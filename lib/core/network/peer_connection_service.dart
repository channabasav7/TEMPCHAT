import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../notifications/web_bridge.dart';
import '../security/encryption_service.dart';
import 'firebase_relay_service.dart';
import '../../models/qr_handshake_payload.dart';
import '../../models/chat_message.dart';

enum PeerConnectionState {
  idle,
  hosting,
  connecting,
  connected,
  disconnected,
  error,
}

class PeerConnectionService {
  static final PeerConnectionService _instance =
      PeerConnectionService._internal();
  factory PeerConnectionService() => _instance;
  PeerConnectionService._internal() {
    webBridgeListenWire((raw) {
      _handleRawWireData(raw);
    });
  }

  PeerConnectionState _state = PeerConnectionState.idle;
  bool _allowIncomingConnections = true;
  PeerConnectionState get state => _state;

  HttpServer? _localServer;
  WebSocket? _socket;
  final List<WebSocket> _connectedClients = [];
  final FirebaseRelayService _firebaseRelay = FirebaseRelayService();

  QrHandshakePayload? _activePayload;
  QrHandshakePayload? get activePayload => _activePayload;

  String? _peerAlias;
  String? get peerAlias => _peerAlias;

  String? _myAlias;
  void setMyAlias(String alias) {
    _myAlias = alias;
  }

  void setAllowIncomingConnections(bool allowed) {
    _allowIncomingConnections = allowed;
  }

  String? Function(String sender, String? relayRoom)? _keyResolver;
  void setKeyResolver(
    String? Function(String sender, String? relayRoom) resolver,
  ) {
    _keyResolver = resolver;
  }

  void Function(String text, String sender)? _onMessageReceived;
  void Function({
    required String sender,
    required String text,
    required MessageType type,
    required List<int> bytes,
    required String fileName,
  })?
  _onAttachmentReceived;
  void Function(PeerConnectionState state)? _onStateChanged;

  String? _localIpCache;

  void setCallbacks({
    required void Function(String text, String sender) onMessageReceived,
    required void Function(PeerConnectionState state) onStateChanged,
    void Function({
      required String sender,
      required String text,
      required MessageType type,
      required List<int> bytes,
      required String fileName,
    })?
    onAttachmentReceived,
  }) {
    _onMessageReceived = onMessageReceived;
    _onStateChanged = onStateChanged;
    _onAttachmentReceived = onAttachmentReceived;
  }

  void _setState(PeerConnectionState newState) {
    _state = newState;
    _onStateChanged?.call(newState);
  }

  /// Discovers local IPv4 address for direct LAN P2P
  Future<String> getLocalIp() async {
    if (_localIpCache != null) return _localIpCache!;
    if (kIsWeb) {
      _localIpCache = '127.0.0.1';
      return _localIpCache!;
    }
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && addr.address.isNotEmpty) {
            _localIpCache = addr.address;
            return addr.address;
          }
        }
      }
    } catch (_) {}
    _localIpCache = '127.0.0.1';
    return _localIpCache!;
  }

  /// Starts hosting an encrypted session on a local port
  Future<QrHandshakePayload> startHostingSession({
    required String hostAlias,
    required int burnSeconds,
    bool allowIncomingConnections = true,
  }) async {
    await disconnect();
    _allowIncomingConnections = allowIncomingConnections;

    String? ip;
    int? port;

    if (!kIsWeb) {
      try {
        ip = await getLocalIp();
        // Bind to available port
        _localServer = await HttpServer.bind(InternetAddress.anyIPv4, 0);
        port = _localServer!.port;

        // Listen for incoming WebSocket connections
        _localServer!.listen((HttpRequest request) async {
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            final socket = await WebSocketTransformer.upgrade(request);
            _handleIncomingClientSocket(socket);
          } else {
            request.response
              ..statusCode = HttpStatus.notFound
              ..close();
          }
        });
      } catch (e) {
        debugPrint(
          'Direct socket server not available on this platform/network: $e',
        );
      }
    }

    final payload = QrHandshakePayload.createFresh(
      hostAlias: hostAlias,
      burnSeconds: burnSeconds,
      localIp: ip,
      localPort: port,
    );

    _activePayload = payload;
    _peerAlias = null;
    _setState(PeerConnectionState.hosting);

    return payload;
  }

  void _handleIncomingClientSocket(WebSocket socket) {
    if (!_allowIncomingConnections) {
      socket.close(WebSocketStatus.policyViolation, 'New chats are disabled');
      return;
    }
    _connectedClients.add(socket);
    _setState(PeerConnectionState.connected);

    socket.listen(
      (data) {
        _handleRawWireData(data.toString());
      },
      onDone: () {
        _connectedClients.remove(socket);
        if (_connectedClients.isEmpty) {
          _setState(PeerConnectionState.hosting);
        }
      },
      onError: (err) {
        _connectedClients.remove(socket);
      },
    );
  }

  /// Connects to a peer by scanning their QrHandshakePayload
  Future<bool> connectViaPayload({
    required QrHandshakePayload payload,
    required String myAlias,
  }) async {
    await disconnect();
    _activePayload = payload;
    _peerAlias = payload.hostAlias;
    _setState(PeerConnectionState.connecting);

    // Try direct LAN P2P connection first if on non-web platform
    if (!kIsWeb && payload.localIp != null && payload.localPort != null) {
      try {
        final uri = Uri.parse('ws://${payload.localIp}:${payload.localPort}');
        final socket = await WebSocket.connect(
          uri.toString(),
        ).timeout(const Duration(seconds: 4));

        _socket = socket;
        _setState(PeerConnectionState.connected);

        _socket!.listen(
          (data) => _handleRawWireData(data.toString()),
          onDone: () => _setState(PeerConnectionState.disconnected),
          onError: (_) => _setState(PeerConnectionState.error),
        );

        // Send encrypted join announcement
        await sendEncryptedMessage(
          plainText: '👋 Optical handshake established. Connected securely.',
          sender: myAlias,
        );

        return true;
      } catch (e) {
        debugPrint(
          'Direct LAN connection failed, falling back to session link: $e',
        );
      }
    }

    // A QR handshake alone is not an Internet transport. Do not report a
    // connection until a relay has actually been established.
    try {
      await _firebaseRelay.connect(
        roomId: payload.relayRoom,
        onWire: _handleRawWireData,
      );
      _setState(PeerConnectionState.connected);
      await sendEncryptedMessage(
        plainText: 'Optical handshake established. Connected securely.',
        sender: myAlias,
      );
      return true;
    } catch (e) {
      debugPrint('Firebase relay connection failed: $e');
      _setState(PeerConnectionState.error);
      return false;
    }
  }

  /// Sends plaintext by encrypting with AES-256 before transmitting over the wire
  Future<bool> sendEncryptedMessage({
    required String plainText,
    required String sender,
    String? secretKey,
    String? relayRoom,
  }) async {
    final keyToUse = secretKey ?? _activePayload?.secretKey;
    if (keyToUse == null) return false;

    final encryptedPayload = EncryptionService.encryptText(plainText, keyToUse);

    final wireMap = {
      'protocol': QrHandshakePayload.currentProtocol,
      'sender': sender,
      'type': 'text',
      'payload': encryptedPayload.toJson(),
      'relayRoom': relayRoom ?? _activePayload?.relayRoom,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final wireString = jsonEncode(wireMap);

    // 1. Broadcast to other browser tabs/windows via WebBridge
    webBridgeSendWire(wireString);
    var transmitted = _firebaseRelay.isConnected;
    try {
      await _sendToRelay(wireString);
    } catch (e) {
      debugPrint('Firebase relay send failed: $e');
      transmitted = false;
    }

    // 2. Send to connected client sockets if hosting (LAN / Native)
    for (final client in _connectedClients) {
      try {
        client.add(wireString);
        transmitted = true;
      } catch (_) {}
    }

    // 3. Send to host if we are client (LAN / Native)
    try {
      if (_socket != null) {
        _socket!.add(wireString);
        transmitted = true;
      }
    } catch (_) {}
    return transmitted;
  }

  /// Sends file or image attachment encrypted with AES-256 over the wire
  Future<bool> sendEncryptedAttachment({
    required String text,
    required String sender,
    required MessageType type,
    required List<int> bytes,
    required String fileName,
    String? secretKey,
    String? relayRoom,
  }) async {
    final keyToUse = secretKey ?? _activePayload?.secretKey;
    if (keyToUse == null) return false;

    final attachmentJson = jsonEncode({
      'text': text,
      'type': type == MessageType.image ? 'image' : 'file',
      'fileName': fileName,
      'bytes': base64Encode(bytes),
    });

    final encryptedPayload = EncryptionService.encryptText(
      attachmentJson,
      keyToUse,
    );

    final wireMap = {
      'protocol': QrHandshakePayload.currentProtocol,
      'sender': sender,
      'type': 'attachment',
      'payload': encryptedPayload.toJson(),
      'relayRoom': relayRoom ?? _activePayload?.relayRoom,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final wireString = jsonEncode(wireMap);

    // 1. Broadcast to other browser tabs/windows via WebBridge
    webBridgeSendWire(wireString);
    var transmitted = _firebaseRelay.isConnected;
    try {
      await _sendToRelay(wireString);
    } catch (e) {
      debugPrint('Firebase relay attachment send failed: $e');
      transmitted = false;
    }

    // 2. Send to sockets
    for (final client in _connectedClients) {
      try {
        client.add(wireString);
        transmitted = true;
      } catch (_) {}
    }

    try {
      if (_socket != null) {
        _socket!.add(wireString);
        transmitted = true;
      }
    } catch (_) {}
    return transmitted;
  }

  Future<void> _sendToRelay(String wireString) async {
    if (_firebaseRelay.isConnected) {
      await _firebaseRelay.send(wireString);
    }
  }

  /// Decrypts raw wire data using the negotiated AES-256 key
  void _handleRawWireData(String rawString) {
    try {
      final map = jsonDecode(rawString) as Map<String, dynamic>;
      final sender = map['sender'] as String? ?? 'Peer';
      final relayRoom = map['relayRoom'] as String?;

      // Ignore echoes broadcast from ourselves!
      if (_myAlias != null &&
          sender.trim().toLowerCase() == _myAlias!.trim().toLowerCase()) {
        return;
      }

      final keyToUse =
          _keyResolver?.call(sender, relayRoom) ?? _activePayload?.secretKey;
      if (keyToUse == null) return;

      final msgType = map['type'] as String? ?? 'text';
      final payloadMap = map['payload'] as Map<String, dynamic>;
      final encryptedPayload = EncryptedPayload.fromJson(payloadMap);

      final decrypted = EncryptionService.decryptText(
        encryptedPayload,
        keyToUse,
      );

      // Verify that decryption was successful and not an error string
      if (decrypted.startsWith('[Decryption Error')) {
        return;
      }

      _peerAlias = sender;
      _setState(PeerConnectionState.connected);

      if (msgType == 'attachment') {
        try {
          final attachData = jsonDecode(decrypted) as Map<String, dynamic>;
          final text = attachData['text'] as String? ?? 'Attachment';
          final typeStr = attachData['type'] as String? ?? 'file';
          final fileName = attachData['fileName'] as String? ?? 'file';
          final base64Bytes = attachData['bytes'] as String? ?? '';
          final bytes = base64Decode(base64Bytes);
          final type = typeStr == 'image'
              ? MessageType.image
              : MessageType.file;

          _onAttachmentReceived?.call(
            sender: sender,
            text: text,
            type: type,
            bytes: bytes,
            fileName: fileName,
          );
          return;
        } catch (e) {
          debugPrint('Error parsing attachment payload: $e');
        }
      }

      _onMessageReceived?.call(decrypted, sender);
    } catch (e) {
      debugPrint('Error decrypting wire data: $e');
    }
  }

  /// Cleans up server, sockets, and zeroizes active key in RAM
  Future<void> disconnect() async {
    for (final client in _connectedClients) {
      try {
        client.close();
      } catch (_) {}
    }
    _connectedClients.clear();

    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;

    try {
      await _localServer?.close(force: true);
    } catch (_) {}
    _localServer = null;
    await _firebaseRelay.disconnect();

    _activePayload = null;
    _peerAlias = null;
    _setState(PeerConnectionState.idle);
  }
}
