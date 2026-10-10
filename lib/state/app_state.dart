import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/network/peer_connection_service.dart';
import '../core/security/encryption_service.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/connection.dart';
import '../models/qr_handshake_payload.dart';

class AppState extends ChangeNotifier {
  static const List<String> _defaultAliases = [
    'ghost_runner',
    'neon_drifter',
    'cipher_echo',
    'shadow_pulse',
    'silent_hawk',
    'zero_trace',
    'matrix_nomad',
    'cryptic_owl',
    'amber_spark',
    'quiet_fox',
    'solar_lynx',
    'hyper_wolf',
  ];

  late String _username;
  String _selectedTheme = 'Light';
  String _selectedTimer = '15 minutes';

  bool _allowNewChats = true;
  bool _qrVisible = true;
  bool _messageAlerts = true;
  bool _sound = true;
  bool _browserNotifications = false;

  late final List<ChatConversation> _conversations;
  late final List<ConnectionItem> _connections;

  QrHandshakePayload? _hostingPayload;
  final PeerConnectionService _peerService = PeerConnectionService();

  AppState() {
    final randName = _defaultAliases[Random().nextInt(_defaultAliases.length)];
    final randNum = Random().nextInt(90) + 10;
    _username = '@$randName$randNum';

    // Synchronously generate a unique cryptographic handshake payload for this unique user
    final burnSecs = getDurationFromTimer(_selectedTimer).inSeconds;
    _hostingPayload = QrHandshakePayload.createFresh(
      hostAlias: _username,
      burnSeconds: burnSecs,
    );

    _initSeedData();
    _initPeerService();
    refreshHostingPayload();
  }

  // Getters
  String get username => _username;
  String get selectedTheme => _selectedTheme;
  String get selectedTimer => _selectedTimer;
  bool get allowNewChats => _allowNewChats;
  bool get qrVisible => _qrVisible;
  bool get messageAlerts => _messageAlerts;
  bool get sound => _sound;
  bool get browserNotifications => _browserNotifications;
  List<ChatConversation> get conversations => List.unmodifiable(_conversations);
  List<ConnectionItem> get connections => List.unmodifiable(_connections);
  QrHandshakePayload? get hostingPayload => _hostingPayload;
  PeerConnectionState get peerConnectionState => _peerService.state;

  ThemeMode get themeMode {
    switch (_selectedTheme) {
      case 'Light':
        return ThemeMode.light;
      case 'Dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void _initPeerService() {
    _peerService.setCallbacks(
      onMessageReceived: (decryptedText, sender) {
        _handleIncomingNetworkMessage(decryptedText, sender);
      },
      onAttachmentReceived: ({
        required String sender,
        required String text,
        required MessageType type,
        required List<int> bytes,
        required String fileName,
      }) {
        _handleIncomingNetworkAttachment(
          sender: sender,
          text: text,
          type: type,
          bytes: bytes,
          fileName: fileName,
        );
      },
      onStateChanged: (state) {
        notifyListeners();
      },
    );
  }

  Future<QrHandshakePayload> refreshHostingPayload() async {
    final burnSecs = getDurationFromTimer(_selectedTimer).inSeconds;
    try {
      _hostingPayload = await _peerService.startHostingSession(
        hostAlias: _username,
        burnSeconds: burnSecs,
      );
    } catch (e) {
      debugPrint('Error starting hosting session, generating unique offline payload: $e');
      _hostingPayload = QrHandshakePayload.createFresh(
        hostAlias: _username,
        burnSeconds: burnSecs,
      );
    }
    notifyListeners();
    return _hostingPayload!;
  }

  void _handleIncomingNetworkMessage(String text, String sender) {
    // Locate existing conversation for this peer or create one
    ChatConversation? target;
    for (final c in _conversations) {
      if (c.username.toLowerCase() == sender.toLowerCase()) {
        target = c;
        break;
      }
    }

    target ??= addOrGetConversation(
      sender,
      secretKey: _hostingPayload?.secretKey,
      sessionId: _hostingPayload?.sessionId,
    );

    final msg = ChatMessage(
      id: 'net-${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isMine: false,
      sentAt: DateTime.now(),
      burnDuration: target.defaultBurnDuration,
    );

    target.messages.add(msg);
    target.unreadCount += 1;
    target.isLiveConnected = true;
    notifyListeners();
  }

  void _handleIncomingNetworkAttachment({
    required String sender,
    required String text,
    required MessageType type,
    required List<int> bytes,
    required String fileName,
  }) {
    ChatConversation? target;
    for (final c in _conversations) {
      if (c.username.toLowerCase() == sender.toLowerCase()) {
        target = c;
        break;
      }
    }

    target ??= addOrGetConversation(
      sender,
      secretKey: _hostingPayload?.secretKey,
      sessionId: _hostingPayload?.sessionId,
    );

    final msg = ChatMessage(
      id: 'net-${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isMine: false,
      sentAt: DateTime.now(),
      burnDuration: target.defaultBurnDuration,
      type: type,
      attachmentBytes: bytes,
      fileName: fileName,
    );

    target.messages.add(msg);
    target.unreadCount += 1;
    target.isLiveConnected = true;
    notifyListeners();
  }

  void _initSeedData() {
    _conversations = [];
    _connections = [];
  }


  void setUsername(String newName) {
    if (newName.trim().isNotEmpty) {
      _username = newName.trim().startsWith('@')
          ? newName.trim()
          : '@${newName.trim()}';
      refreshHostingPayload();
      notifyListeners();
    }
  }

  void setTheme(String theme) {
    _selectedTheme = theme;
    notifyListeners();
  }

  void setDefaultTimer(String timer) {
    _selectedTimer = timer;
    refreshHostingPayload();
    notifyListeners();
  }

  void setAllowNewChats(bool val) {
    _allowNewChats = val;
    notifyListeners();
  }

  void setQrVisible(bool val) {
    _qrVisible = val;
    notifyListeners();
  }

  void setMessageAlerts(bool val) {
    _messageAlerts = val;
    notifyListeners();
  }

  void setSound(bool val) {
    _sound = val;
    notifyListeners();
  }

  void setBrowserNotifications(bool val) {
    _browserNotifications = val;
    notifyListeners();
  }

  Duration getDurationFromTimer(String timer) {
    switch (timer) {
      case '1 minute':
        return const Duration(minutes: 1);
      case '5 minutes':
        return const Duration(minutes: 5);
      case '15 minutes':
        return const Duration(minutes: 15);
      case '1 hour':
        return const Duration(hours: 1);
      case '6 hours':
        return const Duration(hours: 6);
      case '24 hours':
        return const Duration(hours: 24);
      default:
        return const Duration(minutes: 15);
    }
  }

  ChatConversation? getConversationById(String id) {
    try {
      return _conversations.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void sendMessage(String conversationId, String text) {
    if (text.trim().isEmpty) return;
    final conv = getConversationById(conversationId);
    if (conv != null) {
      final msg = ChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        text: text.trim(),
        isMine: true,
        sentAt: DateTime.now(),
        burnDuration: conv.defaultBurnDuration,
      );
      conv.messages.add(msg);
      notifyListeners();

      // Transmit encrypted over the real P2P wire
      if (conv.secretKey != null &&
          _peerService.activePayload?.secretKey == conv.secretKey) {
        _peerService.sendEncryptedMessage(
          plainText: text.trim(),
          sender: _username,
        );
      }
    }
  }

  Future<void> sendAttachment(String conversationId, String filePath, MessageType type) async {
    final conv = getConversationById(conversationId);
    if (conv != null) {
      final fileName = filePath.split(RegExp(r'[\\/]')).last;
      List<int>? fileBytes;
      if (!kIsWeb) {
        try {
          final f = File(filePath);
          if (await f.exists()) {
            fileBytes = await f.readAsBytes();
          }
        } catch (e) {
          debugPrint('Could not read attachment bytes: $e');
        }
      }

      final msg = ChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        text: type == MessageType.image ? '📷 Image' : '📎 $fileName',
        isMine: true,
        sentAt: DateTime.now(),
        burnDuration: conv.defaultBurnDuration,
        type: type,
        attachmentPath: filePath,
        attachmentBytes: fileBytes,
        fileName: fileName,
      );
      conv.messages.add(msg);
      notifyListeners();

      if (conv.secretKey != null &&
          _peerService.activePayload?.secretKey == conv.secretKey) {
        if (fileBytes != null && fileBytes.isNotEmpty) {
          await _peerService.sendEncryptedAttachment(
            text: msg.text,
            sender: _username,
            type: type,
            bytes: fileBytes,
            fileName: fileName,
          );
        } else {
          await _peerService.sendEncryptedMessage(
            plainText: msg.text,
            sender: _username,
          );
        }
      }
    }
  }


  void burnAllMessages(String conversationId) {
    final conv = getConversationById(conversationId);
    if (conv != null) {
      conv.messages.clear();
      notifyListeners();
    }
  }

  /// Establishes an E2EE session from an optically scanned QR handshake payload
  Future<ChatConversation> connectToScannedPayload(
    QrHandshakePayload payload,
  ) async {
    // 1. Check if conversation already exists for this host alias
    ChatConversation? existing;
    for (final c in _conversations) {
      if (c.username.toLowerCase() == payload.hostAlias.toLowerCase()) {
        existing = c;
        break;
      }
    }

    final duration = Duration(seconds: payload.burnSeconds);
    final burnLabel = '${payload.burnSeconds ~/ 60} minutes';

    final conv = existing ??
        ChatConversation(
          id: 'conv-${DateTime.now().millisecondsSinceEpoch}',
          username: payload.hostAlias,
          burnTimer: burnLabel,
          defaultBurnDuration: duration,
          secretKey: payload.secretKey,
          sessionId: payload.sessionId,
          isOnline: true,
          isLiveConnected: true,
        );

    if (existing == null) {
      _conversations.insert(0, conv);
    }

    // 2. Add to connections mesh
    addConnection(payload.hostAlias);

    // 3. Initiate real-time socket connection via peer service
    await _peerService.connectViaPayload(
      payload: payload,
      myAlias: _username,
    );

    notifyListeners();
    return conv;
  }

  ChatConversation addOrGetConversation(
    String username, {
    String? secretKey,
    String? sessionId,
  }) {
    final cleanUsername = username.trim().startsWith('@')
        ? username.trim()
        : '@${username.trim()}';

    for (final c in _conversations) {
      if (c.username.toLowerCase() == cleanUsername.toLowerCase()) {
        return c;
      }
    }

    final newConv = ChatConversation(
      id: 'conv-${DateTime.now().millisecondsSinceEpoch}',
      username: cleanUsername,
      burnTimer: _selectedTimer,
      defaultBurnDuration: getDurationFromTimer(_selectedTimer),
      secretKey: secretKey ?? EncryptionService.generateSessionKey(),
      sessionId: sessionId ?? EncryptionService.generateSessionId(),
      isOnline: true,
      isLiveConnected: true,
    );
    _conversations.insert(0, newConv);

    addConnection(cleanUsername);

    notifyListeners();
    return newConv;
  }

  void addConnection(String username) {
    final clean =
        username.trim().startsWith('@') ? username.trim() : '@${username.trim()}';
    final exists =
        _connections.any((c) => c.username.toLowerCase() == clean.toLowerCase());
    if (!exists) {
      _connections.insert(
        0,
        ConnectionItem(
          id: 'conn-${DateTime.now().millisecondsSinceEpoch}',
          username: clean,
          connectedAt: DateTime.now(),
          lifetime: const Duration(hours: 24),
          isOnline: true,
        ),
      );
      notifyListeners();
    }
  }

  void removeConnection(String id) {
    _connections.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    _peerService.disconnect();
    super.dispose();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState appState,
    required super.child,
  }) : super(notifier: appState);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in context');
    return scope!.notifier!;
  }
}
