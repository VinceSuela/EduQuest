import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_pomodoro/constant.dart';

class ApiKeyService {
  static const String _apiKeyName = 'gemini_api_key';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static Future<void> saveApiKeyLocally(String apiKey) async {
    await _storage.write(
      key: _apiKeyName,
      value: apiKey.trim(),
    );
  }

  static Future<String?> getApiKey() async {
    return await _storage.read(key: _apiKeyName);
  }

  static Future<void> deleteApiKey() async {
    await _storage.delete(key: _apiKeyName);
  }

  static Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  static enc.Key _deriveKey(String uid) {
    final bytes = utf8.encode('$uid$appSecret');
    final hash = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(hash.bytes));
  }

  static String encryptForFirestore({
    required String apiKey,
    required String uid,
  }) {
    final key = _deriveKey(uid);

    final iv = enc.IV.fromSecureRandom(16);

    final encrypter = enc.Encrypter(
      enc.AES(
        key,
        mode: enc.AESMode.cbc,
      ),
    );

    final encrypted = encrypter.encrypt(
      apiKey,
      iv: iv,
    );

    return jsonEncode({
      'iv': iv.base64,
      'data': encrypted.base64,
    });
  }

  static String? decryptFromFirestore({
    required String payload,
    required String uid,
  }) {
    try {
      final parsed = jsonDecode(payload);

      final iv = enc.IV.fromBase64(parsed['iv']);
      final encryptedData = parsed['data'];

      final key = _deriveKey(uid);

      final encrypter = enc.Encrypter(
        enc.AES(
          key,
          mode: enc.AESMode.cbc,
        ),
      );

      return encrypter.decrypt64(
        encryptedData,
        iv: iv,
      );
    } catch (_) {
      return null;
    }
  }
}