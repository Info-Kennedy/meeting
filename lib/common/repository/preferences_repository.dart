import "package:flutter_secure_storage/flutter_secure_storage.dart";

class PreferencesRepository {
  final FlutterSecureStorage secureStorage;

  PreferencesRepository(this.secureStorage);

  Future<void> savePreference(String key, String value) async {
    await secureStorage.write(key: key, value: value);
  }

  Future<String?> getPreference(String key) async {
    return await secureStorage.read(key: key);
  }

  Future<void> removePreference(String key) async {
    await secureStorage.delete(key: key);
  }

  Future<void> removeAllPreference() async {
    await secureStorage.deleteAll();
  }

  /// FlutterSecureStorage doesn't support getting all keys directly.
  /// This method returns an empty map. If you need to track all preferences,
  /// consider maintaining a separate list of keys.
  Future<Map<String, String>> getAllPreferences() async {
    // FlutterSecureStorage doesn't provide a way to get all keys
    // Return empty map as this method is not used in the codebase
    return <String, String>{};
  }
}
