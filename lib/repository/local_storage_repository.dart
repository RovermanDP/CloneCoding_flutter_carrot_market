import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorageRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> getStoredValue(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> storeValue(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Ignore storage write failures for this sample app.
    }
  }

  Future<void> deleteStoredValue(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // Ignore storage delete failures for this sample app.
    }
  }
}
