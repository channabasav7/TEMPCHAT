import 'package:flutter_test/flutter_test.dart';
import 'package:viora/core/security/encryption_service.dart';
import 'package:viora/models/qr_handshake_payload.dart';

void main() {
  group('EncryptionService Tests', () {
    test('Generate 256-bit key and encrypt/decrypt text accurately', () {
      final key = EncryptionService.generateSessionKey();
      expect(key.isNotEmpty, true);

      const secretMessage = r'Secret ephemeral message 12345! @#$%^&*';
      final encrypted = EncryptionService.encryptText(secretMessage, key);

      // Ciphertext should not match original plaintext
      expect(encrypted.ciphertext, isNot(equals(secretMessage)));
      expect(encrypted.iv.isNotEmpty, true);

      // Decrypt with correct key
      final decrypted = EncryptionService.decryptText(encrypted, key);
      expect(decrypted, equals(secretMessage));
    });

    test('Decryption with wrong key fails safely', () {
      final keyA = EncryptionService.generateSessionKey();
      final keyB = EncryptionService.generateSessionKey();

      final encrypted = EncryptionService.encryptText('Classified information', keyA);
      final failedAttempt = EncryptionService.decryptText(encrypted, keyB);

      expect(failedAttempt.contains('Decryption Error'), true);
    });

    test('Compute safety fingerprint', () {
      final key = EncryptionService.generateSessionKey();
      final fingerprint = EncryptionService.computeSafetyFingerprint(key);

      expect(fingerprint.isNotEmpty, true);
      // Format should contain space-separated hex chunks
      expect(fingerprint.length, greaterThanOrEqualTo(16));
    });
  });

  group('QrHandshakePayload Tests', () {
    test('Create fresh payload, encode to QR URI, and parse back', () {
      final payload = QrHandshakePayload.createFresh(
        hostAlias: '@quiet_fox42',
        burnSeconds: 900,
        localIp: '192.168.1.50',
        localPort: 54321,
      );

      final encoded = payload.toEncodedString();
      expect(encoded.startsWith('tempchat://'), true);

      final parsed = QrHandshakePayload.tryParse(encoded);
      expect(parsed, isNotNull);
      expect(parsed!.hostAlias, equals('@quiet_fox42'));
      expect(parsed.burnSeconds, equals(900));
      expect(parsed.secretKey, equals(payload.secretKey));
      expect(parsed.sessionId, equals(payload.sessionId));
      expect(parsed.localIp, equals('192.168.1.50'));
      expect(parsed.localPort, equals(54321));
    });

    test('Reject invalid QR strings gracefully', () {
      expect(QrHandshakePayload.tryParse('invalid_random_string'), isNull);
      expect(QrHandshakePayload.tryParse('tempchat://not_base64!'), isNull);
    });
  });
}
