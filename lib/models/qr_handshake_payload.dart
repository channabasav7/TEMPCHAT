import 'dart:convert';
import '../core/security/encryption_service.dart';

class QrHandshakePayload {
  static const String currentProtocol = 'tempchat-v1';

  final String protocol;
  final String sessionId;
  final String hostAlias;
  final String secretKey;
  final String relayRoom;
  final int burnSeconds;
  final int createdAt;
  final String? localIp;
  final int? localPort;

  QrHandshakePayload({
    this.protocol = currentProtocol,
    required this.sessionId,
    required this.hostAlias,
    required this.secretKey,
    required this.relayRoom,
    required this.burnSeconds,
    required this.createdAt,
    this.localIp,
    this.localPort,
  });

  /// Factory to generate a fresh ephemeral handshake for a host alias
  factory QrHandshakePayload.createFresh({
    required String hostAlias,
    required int burnSeconds,
    String? localIp,
    int? localPort,
  }) {
    final sessionId = EncryptionService.generateSessionId();
    final secretKey = EncryptionService.generateSessionKey();
    final relayRoom = EncryptionService.deriveRelayRoomId(sessionId, secretKey);

    return QrHandshakePayload(
      protocol: currentProtocol,
      sessionId: sessionId,
      hostAlias: hostAlias.trim().startsWith('@') ? hostAlias.trim() : '@${hostAlias.trim()}',
      secretKey: secretKey,
      relayRoom: relayRoom,
      burnSeconds: burnSeconds,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      localIp: localIp,
      localPort: localPort,
    );
  }

  Map<String, dynamic> toMap() => {
        'p': protocol,
        's': sessionId,
        'a': hostAlias,
        'k': secretKey,
        'r': relayRoom,
        'b': burnSeconds,
        't': createdAt,
        if (localIp != null) 'ip': localIp,
        if (localPort != null) 'pt': localPort,
      };

  /// Encodes into a compact URI string suitable for QR codes and deep links
  String toEncodedString() {
    final jsonStr = jsonEncode(toMap());
    final base64Payload = base64Url.encode(utf8.encode(jsonStr));
    return 'tempchat://$base64Payload';
  }

  /// Parses a scanned QR string, deep link, or pasted payload with fallback support
  static QrHandshakePayload? tryParse(String raw) {
    try {
      String clean = raw.trim();
      if (clean.isEmpty) return null;

      if (clean.startsWith('tempchat://')) {
        clean = clean.substring('tempchat://'.length);
      }

      // 1. Try base64Url decode first
      String jsonStr;
      try {
        jsonStr = utf8.decode(base64Url.decode(base64Url.normalize(clean)));
      } catch (_) {
        jsonStr = clean;
      }

      // 2. Try JSON decode
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        if (map['k'] != null && map['s'] != null) {
          return QrHandshakePayload(
            protocol: map['p'] as String? ?? currentProtocol,
            sessionId: map['s'] as String,
            hostAlias: map['a'] as String? ?? '@anonymous',
            secretKey: map['k'] as String,
            relayRoom: map['r'] as String? ??
                EncryptionService.deriveRelayRoomId(
                  map['s'] as String,
                  map['k'] as String,
                ),
            burnSeconds: (map['b'] as num?)?.toInt() ?? 900,
            createdAt: (map['t'] as num?)?.toInt() ?? 0,
            localIp: map['ip'] as String?,
            localPort: (map['pt'] as num?)?.toInt(),
          );
        }
      } catch (_) {}

      // 3. Fallback: If it looks like a username alias (e.g. "@alice" or "alice"),
      // auto-generate a fresh ephemeral AES-256 session for this peer!
      final aliasCandidate = clean.replaceAll(RegExp(r'[^\w@]'), '');
      if (aliasCandidate.isNotEmpty && aliasCandidate.length <= 32) {
        return QrHandshakePayload.createFresh(
          hostAlias: aliasCandidate,
          burnSeconds: 900,
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  String get safetyFingerprint =>
      EncryptionService.computeSafetyFingerprint(secretKey);
}
