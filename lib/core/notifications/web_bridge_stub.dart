import 'package:flutter/services.dart';

void webBridgeSendWire(String message) {
  // Stub for non-web platforms
}

void webBridgeListenWire(void Function(String) callback) {
  // Stub for non-web platforms
}

void webBridgePlaySound(String type) {
  try {
    SystemSound.play(type == 'send' ? SystemSoundType.click : SystemSoundType.alert);
  } catch (_) {}
}

void webBridgeShowNotification(String title, String body) {
  // Native notification stub
}

Future<String> webBridgeRequestNotificationPermission() async {
  return 'granted';
}
