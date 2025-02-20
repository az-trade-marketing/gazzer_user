import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefHelper {
  static SharedPreferences? sharedPreferences;

  static Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  static Future<bool> saveData({
    required String key,
    required dynamic value,
  }) async {
    if (sharedPreferences == null) {
      throw Exception('SharedPref not initialized');
    }

    if (value is bool) {
      return await sharedPreferences!.setBool(key, value);
    } else if (value is int) {
      return await sharedPreferences!.setInt(key, value);
    } else if (value is double) {
      return await sharedPreferences!.setDouble(key, value);
    } else if (value is String) {
      return await sharedPreferences!.setString(key, value);
    } else {
      throw Exception('Unsupported value type');
    }
  }

  static dynamic getData({required String key}) {
    if (sharedPreferences == null) {
      throw Exception('SharedPref not initialized');
    }
    return sharedPreferences!.get(key);
  }

  static bool containsKey({required String key}) {
    if (sharedPreferences == null) {
      throw Exception('SharedPref not initialized');
    }
    return sharedPreferences!.containsKey(key);
  }

  static Future<bool> removeData({required String key}) async {
    if (sharedPreferences == null) {
      throw Exception('SharedPref not initialized');
    }
    return await sharedPreferences!.remove(key);
  }

  static Future<bool> clearData() async {
    if (sharedPreferences == null) {
      throw Exception('SharedPref not initialized');
    }
    return await sharedPreferences!.clear();
  }
}
