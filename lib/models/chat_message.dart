enum MessageType { text, image, file }

class ChatMessage {
  final String id;
  final String text;
  final bool isMine;
  final DateTime sentAt;
  final Duration burnDuration;
  final MessageType type;
  final String? attachmentPath; // local file path for image/file messages
  final List<int>? attachmentBytes; // raw bytes for cross-device display
  final String? fileName; // original file name

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMine,
    required this.sentAt,
    required this.burnDuration,
    this.type = MessageType.text,
    this.attachmentPath,
    this.attachmentBytes,
    this.fileName,
  });

  bool get isBurned {
    return DateTime.now().isAfter(sentAt.add(burnDuration));
  }

  Duration get remainingTime {
    final expireAt = sentAt.add(burnDuration);
    final diff = expireAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String get remainingFormatted {
    final rem = remainingTime;
    if (rem.inHours > 0) {
      final m = (rem.inMinutes % 60).toString().padLeft(2, '0');
      return '${rem.inHours}h ${m}m';
    }
    final m = rem.inMinutes.toString().padLeft(2, '0');
    final s = (rem.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
