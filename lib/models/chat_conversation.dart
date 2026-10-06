import 'chat_message.dart';
import '../core/security/encryption_service.dart';

class ChatConversation {
  final String id;
  final String username;
  final String burnTimer;
  final Duration defaultBurnDuration;
  final bool isOnline;
  int unreadCount;
  final List<ChatMessage> messages;

  // End-to-End Encryption fields
  final String? secretKey;
  final String? sessionId;
  final bool isEncrypted;
  bool isLiveConnected;

  ChatConversation({
    required this.id,
    required this.username,
    required this.burnTimer,
    required this.defaultBurnDuration,
    this.isOnline = false,
    this.unreadCount = 0,
    this.secretKey,
    this.sessionId,
    this.isEncrypted = true,
    this.isLiveConnected = false,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  String get safetyFingerprint {
    if (secretKey != null && secretKey!.isNotEmpty) {
      return EncryptionService.computeSafetyFingerprint(secretKey!);
    }
    return 'AES-256 E2EE';
  }

  String get avatarInitial {
    final clean = username.replaceAll('@', '').trim();
    return clean.isNotEmpty ? clean[0].toUpperCase() : '?';
  }

  String get lastMessageText {
    final validMessages = messages.where((m) => !m.isBurned).toList();
    if (validMessages.isEmpty) {
      return 'No active messages (all burned)';
    }
    return validMessages.last.text;
  }

  String get lastMessageTime {
    final validMessages = messages.where((m) => !m.isBurned).toList();
    if (validMessages.isEmpty) {
      return '';
    }
    final sent = validMessages.last.sentAt;
    final diff = DateTime.now().difference(sent);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}
