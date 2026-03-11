import 'dart:convert';

/// A very basic XOR + Base64 'encryption' for obfuscating IDs in URLs.
/// Not suitable for sensitive data, but sufficient for hiding raw Firestore IDs.
class EncryptionUtils {
  static const String _key = "fixit-pro-secret-key";

  static String encrypt(String plainText) {
    List<int> bytes = utf8.encode(plainText);
    List<int> keyBytes = utf8.encode(_key);
    List<int> result = [];

    for (int i = 0; i < bytes.length; i++) {
      result.add(bytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64Url.encode(result);
  }

  static String decrypt(String encryptedText) {
    try {
      List<int> bytes = base64Url.decode(encryptedText);
      List<int> keyBytes = utf8.encode(_key);
      List<int> result = [];

      for (int i = 0; i < bytes.length; i++) {
        result.add(bytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(result);
    } catch (e) {
      return "";
    }
  }
}
