import 'dart:js_interop';

@JS('tempChatBridge')
external TempChatBridgeJs? get tempChatBridge;

extension type TempChatBridgeJs(JSObject _) implements JSObject {
  external void sendWire(JSString msg);
  external void listenWire(JSFunction callback);
  external void playSound(JSString type);
  external void showNotification(JSString title, JSString body);
  external JSPromise<JSString> requestNotificationPermission();
}

void webBridgeSendWire(String message) {
  try {
    tempChatBridge?.sendWire(message.toJS);
  } catch (_) {}
}

void webBridgeListenWire(void Function(String) callback) {
  try {
    tempChatBridge?.listenWire(((JSString msg) {
      callback(msg.toDart);
    }).toJS);
  } catch (_) {}
}

void webBridgePlaySound(String type) {
  try {
    tempChatBridge?.playSound(type.toJS);
  } catch (_) {}
}

void webBridgeShowNotification(String title, String body) {
  try {
    tempChatBridge?.showNotification(title.toJS, body.toJS);
  } catch (_) {}
}

Future<String> webBridgeRequestNotificationPermission() async {
  try {
    final promise = tempChatBridge?.requestNotificationPermission();
    if (promise != null) {
      final res = await promise.toDart;
      return res.toDart;
    }
  } catch (_) {}
  return 'denied';
}
