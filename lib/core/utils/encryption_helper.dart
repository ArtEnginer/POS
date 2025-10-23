import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Simple encryption helper for storing sensitive data
/// Uses AES-like encoding with base64 for password storage
class EncryptionHelper {
  // Simple key for demonstration - in production, use a secure key management system
  static const String _key = 'POS_ENCRYPTION_KEY_2024';

  /// Encrypt string
  static String encrypt(String plainText) {
    if (plainText.isEmpty) return '';

    try {
      // Simple XOR encryption with base64 encoding
      final bytes = utf8.encode(plainText);
      final keyBytes = utf8.encode(_key);
      final encrypted = List<int>.generate(
        bytes.length,
        (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
      );

      return base64Encode(encrypted);
    } catch (e) {
      return plainText;
    }
  }

  /// Decrypt string
  static String decrypt(String encryptedText) {
    if (encryptedText.isEmpty) return '';

    try {
      final encrypted = base64Decode(encryptedText);
      final keyBytes = utf8.encode(_key);
      final decrypted = List<int>.generate(
        encrypted.length,
        (i) => encrypted[i] ^ keyBytes[i % keyBytes.length],
      );

      return utf8.decode(decrypted);
    } catch (e) {
      return encryptedText;
    }
  }

  /// Hash password using SHA256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify password against hash
  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }
}
