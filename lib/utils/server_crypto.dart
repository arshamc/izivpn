import 'dart:convert';
import 'package:encrypt/encrypt.dart';

/// Cryptographic helper for securing remote server configurations on public CDNs.
class ServerCrypto {
  // Exactly 32 bytes (256 bits) for AES-256
  static final Key _key = Key.fromUtf8('IZIVPN_AES_KEY_32BYTES_PROD_2026');
  // Exactly 16 bytes (128 bits) for CBC mode
  static final IV _iv = IV.fromUtf8('IZIVPN_IV_16BYTE');

  /// Decrypts an AES-256-CBC encrypted Base64 string payload into UTF-8 JSON text.
  /// If the payload is already plaintext JSON (starts with '[' or '{'), returns it safely as-is.
  static String decryptPayload(String payload) {
    final trimmed = payload.trim();
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      return trimmed; // Plaintext JSON fallback for local development or unencrypted mirrors
    }

    try {
      final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
      final encrypted = Encrypted.fromBase64(trimmed);
      final decrypted = encrypter.decrypt(encrypted, iv: _iv);
      return decrypted;
    } catch (e) {
      // If decryption fails, safely fallback to the original payload
      return trimmed;
    }
  }

  /// Encrypts raw JSON text into an AES-256-CBC Base64 string payload.
  static String encryptPayload(String rawJson) {
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(rawJson, iv: _iv);
    return encrypted.base64;
  }
}
