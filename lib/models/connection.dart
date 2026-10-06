class ConnectionItem {
  final String id;
  final String username;
  final DateTime connectedAt;
  final Duration lifetime;
  final bool isOnline;

  ConnectionItem({
    required this.id,
    required this.username,
    required this.connectedAt,
    required this.lifetime,
    this.isOnline = true,
  });

  String get avatarInitial {
    final clean = username.replaceAll('@', '').trim();
    return clean.isNotEmpty ? clean[0].toUpperCase() : '?';
  }

  bool get isExpired {
    return DateTime.now().isAfter(connectedAt.add(lifetime));
  }

  Duration get remainingTime {
    final expireAt = connectedAt.add(lifetime);
    final diff = expireAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String get formattedRemaining {
    final rem = remainingTime;
    if (rem.inHours > 0) {
      return '${rem.inHours}h ${(rem.inMinutes % 60)}m left';
    }
    return '${rem.inMinutes}m left';
  }
}
