import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptedPayload {
  final String ciphertext;
  final String iv;

  EncryptedPayload({required this.ciphertext, required this.iv});

  Map<String, dynamic> toJson() => {
        'ciphertext': ciphertext,
        'iv': iv,
      };

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) =>
      EncryptedPayload(
        ciphertext: json['ciphertext'] as String,
        iv: json['iv'] as String,
      );
}

class EncryptionService {
  /// Generates a cryptographically strong 256-bit (32 bytes) AES key as base64
  static String generateSessionKey() {
    final key = enc.Key.fromSecureRandom(32);
    return key.base64;
  }

  /// Generates a random session ID
  static String generateSessionId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return sha256.convert(bytes).toString().substring(0, 16);
  }

  /// Derives an anonymous, un-linkable relay room identifier from the key & session
  static String deriveRelayRoomId(String sessionId, String keyBase64) {
    final combined = '$sessionId:$keyBase64';
    final hash = sha256.convert(utf8.encode(combined)).toString();
    return 'tc_${hash.substring(0, 16)}';
  }

  /// Encrypts plaintext using AES-256-CBC with a fresh 16-byte random IV
  static EncryptedPayload encryptText(String plainText, String keyBase64) {
    try {
      final key = enc.Key.fromBase64(keyBase64);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return EncryptedPayload(
        ciphertext: encrypted.base64,
        iv: iv.base64,
      );
    } catch (e) {
      throw Exception('Encryption failure: $e');
    }
  }

  /// Decrypts ciphertext using AES-256-CBC with the provided IV and key
  static String decryptText(EncryptedPayload payload, String keyBase64) {
    try {
      final key = enc.Key.fromBase64(keyBase64);
      final iv = enc.IV.fromBase64(payload.iv);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(payload.ciphertext, iv: iv);
    } catch (e) {
      return '[Decryption Error: Invalid Key or Corrupted Message]';
    }
  }

  /// Computes a SHA-256 security fingerprint for peer verification
  static String computeSafetyFingerprint(String keyBase64) {
    final digest = sha256.convert(base64.decode(keyBase64)).toString();
    // Return formatted in 4-character chunks: XXXX-XXXX-XXXX-XXXX
    return digest.substring(0, 16).toUpperCase().replaceAllMapped(
          RegExp(r'.{4}'),
          (match) => '${match.group(0)} ',
        ).trim();
  }
}
