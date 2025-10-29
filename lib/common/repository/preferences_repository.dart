import "package:shared_preferences/shared_preferences.dart";

class PreferencesRepository {
  final SharedPreferences sharedPreferences;

  PreferencesRepository(this.sharedPreferences);

  Future<void> savePreference(String key, String value) async {
    await sharedPreferences.setString(key, value);
  }

  String? getPreference(String key) {
    return sharedPreferences.getString(key);
  }

  Future<void> removePreference(String key) async {
    await sharedPreferences.remove(key);
  }

  Future<void> removeAllPreference() async {
    await sharedPreferences.clear();
  }

  Map<String, String> getAllPreferences() {
    return sharedPreferences.getKeys().map((key) => MapEntry(key, sharedPreferences.getString(key) ?? '')).toMap();
  }
}

extension on Iterable<MapEntry<String, String>> {
  Map<String, String> toMap() {
    return Map.fromEntries(this);
  }
}
