import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptedPayload {
  final String ciphertext;
  final String iv;
  final String algorithm;

  EncryptedPayload({
    required this.ciphertext,
    required this.iv,
    this.algorithm = 'aes-256-gcm',
  });

  Map<String, dynamic> toJson() => {
    'ciphertext': ciphertext,
    'iv': iv,
    'algorithm': algorithm,
  };

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) =>
      EncryptedPayload(
        ciphertext: json['ciphertext'] as String,
        iv: json['iv'] as String,
        algorithm: json['algorithm'] as String? ?? 'aes-256-cbc',
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

  /// Encrypts plaintext using authenticated AES-256-GCM.
  static EncryptedPayload encryptText(String plainText, String keyBase64) {
    try {
      final key = enc.Key.fromBase64(keyBase64);
      final iv = enc.IV.fromSecureRandom(12);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return EncryptedPayload(ciphertext: encrypted.base64, iv: iv.base64);
    } catch (e) {
      throw Exception('Encryption failure: $e');
    }
  }

  /// Decrypts authenticated AES-256-GCM ciphertext.
  static String decryptText(EncryptedPayload payload, String keyBase64) {
    try {
      if (payload.algorithm != 'aes-256-gcm') {
        return '[Decryption Error: Unsupported Cipher]';
      }
      final key = enc.Key.fromBase64(keyBase64);
      final iv = enc.IV.fromBase64(payload.iv);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      return encrypter.decrypt64(payload.ciphertext, iv: iv);
    } catch (e) {
      return '[Decryption Error: Invalid Key or Corrupted Message]';
    }
  }

  /// Computes a SHA-256 security fingerprint for peer verification
  static String computeSafetyFingerprint(String keyBase64) {
    final digest = sha256.convert(base64.decode(keyBase64)).toString();
    // Return formatted in 4-character chunks: XXXX-XXXX-XXXX-XXXX
    return digest
        .substring(0, 16)
        .toUpperCase()
        .replaceAllMapped(RegExp(r'.{4}'), (match) => '${match.group(0)} ')
        .trim();
  }
}
