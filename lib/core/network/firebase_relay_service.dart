import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseRelayService {
  static const _databaseUrl =
      'https://tempchat-1cd4f-default-rtdb.asia-southeast1.firebasedatabase.app';
  static const _maxWireBytes = 256 * 1024;

  StreamSubscription<DatabaseEvent>? _subscription;
  DatabaseReference? _messages;
  String? _ownUserId;
  bool get isConnected => _messages != null;

  Future<void> connect({
    required String roomId,
    required void Function(String wire) onWire,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final user =
        currentUser ?? (await FirebaseAuth.instance.signInAnonymously()).user;
    final uid = user?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Anonymous Firebase authentication returned no user.');
    }

    await disconnect();
    _ownUserId = uid;
    _messages = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _databaseUrl,
    ).ref('rooms/$roomId/messages');
    _subscription = _messages!.onChildAdded.listen((event) {
      final value = event.snapshot.value;
      if (value is String && value.isNotEmpty) {
        onWire(value);
      }
    });
  }

  Future<void> send(String wire) async {
    final messages = _messages;
    if (messages == null) {
      throw StateError('Firebase relay is not connected.');
    }
    if (utf8.encode(wire).length > _maxWireBytes) {
      throw StateError('Message is too large for the encrypted relay.');
    }

    final child = messages.push();
    await child.set({
      'senderUid': _ownUserId,
      'wire': wire,
      'createdAt': ServerValue.timestamp,
      'expiresAt': DateTime.now()
          .add(const Duration(minutes: 30))
          .millisecondsSinceEpoch,
    });
    await child.onDisconnect().remove();
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    _messages = null;
    _ownUserId = null;
  }
}
