import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'web_bridge.dart';

enum AlertType { sent, received, info, error }

class NotificationAlert {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final AlertType type;
  final DateTime timestamp;

  NotificationAlert({
    String? id,
    required this.title,
    required this.message,
    this.icon = Icons.lock_outline,
    this.color = AppColors.primaryOrange,
    this.type = AlertType.sent,
    DateTime? timestamp,
  })  : id = id ?? 'alert-${DateTime.now().millisecondsSinceEpoch}',
        timestamp = timestamp ?? DateTime.now();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final StreamController<NotificationAlert> _alertController =
      StreamController<NotificationAlert>.broadcast();

  Stream<NotificationAlert> get alertStream => _alertController.stream;

  /// Triggered whenever an outgoing message is transmitted to another peer
  void notifyMessageSent({
    required String recipient,
    required String text,
    bool sound = true,
    bool browserNotifications = false,
    bool messageAlerts = true,
  }) {
    if (sound) {
      webBridgePlaySound('send');
    }

    if (browserNotifications) {
      final preview = text.length > 50 ? '${text.substring(0, 50)}...' : text;
      webBridgeShowNotification(
        'TempChat • Sent to $recipient',
        '🔒 Encrypted with AES-256: "$preview"',
      );
    }

    if (messageAlerts) {
      final alert = NotificationAlert(
        title: 'Sent to $recipient',
        message: 'Encrypted client-side with AES-256 & random IV.',
        icon: Icons.lock_rounded,
        color: AppColors.primaryOrange,
        type: AlertType.sent,
      );
      _alertController.add(alert);
    }
  }

  /// Triggered whenever an incoming message is received and decrypted
  void notifyMessageReceived({
    required String sender,
    required String text,
    bool sound = true,
    bool browserNotifications = false,
    bool messageAlerts = true,
  }) {
    if (sound) {
      webBridgePlaySound('receive');
    }

    if (browserNotifications) {
      final preview = text.length > 50 ? '${text.substring(0, 50)}...' : text;
      webBridgeShowNotification(
        'TempChat • Message from $sender',
        preview,
      );
    }

    if (messageAlerts) {
      final preview = text.length > 45 ? '${text.substring(0, 45)}...' : text;
      final alert = NotificationAlert(
        title: 'Message from $sender',
        message: preview,
        icon: Icons.chat_bubble_outline_rounded,
        color: AppColors.accentGreen,
        type: AlertType.received,
      );
      _alertController.add(alert);
    }
  }

  /// Requests browser-level notification permissions on web
  Future<bool> requestBrowserPermission() async {
    final status = await webBridgeRequestNotificationPermission();
    return status == 'granted';
  }

  void dispose() {
    _alertController.close();
  }
}
