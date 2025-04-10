import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:math' as Math;
class HiveDBHelper {

  // Save any model to database
  static Future<void> saveData<T>(String boxName, String key, T data,
      {String? cacheVersion}) async {
    try {
      final box = await Hive.openBox(boxName);

      // Convert to JSON then store
      final Map<String, dynamic> dataMap;
      if (data is Map<String, dynamic>) {
        dataMap = data;
      } else {
        // Assuming the model has a toJson method
        dataMap = (data as dynamic).toJson();
      }

      // Add cache version if provided
      if (cacheVersion != null) {
        dataMap['cacheVersion'] = cacheVersion;
      }

      final String dataJson = jsonEncode(dataMap);
      await box.put(key, dataJson);
      print('Data saved successfully to $boxName:$key');
    } catch (e) {
      print('Error saving data to database: $e');
    }
  }

  // Get data from database
  static Future<T?> getData<T>(String boxName, String key,
      T Function(Map<String, dynamic>) fromJson) async {
    try {
      final box = await Hive.openBox(boxName);
      final String? dataJson = box.get(key);

      if (dataJson != null && dataJson.isNotEmpty) {
        try {
          final Map<String, dynamic> dataMap = jsonDecode(dataJson);
          return fromJson(dataMap);
        } catch (e) {
          print('Error parsing JSON data: $e');
          return null;
        }
      }
    } catch (e) {
      print('Error retrieving data from database: $e');
    }
    return null;
  }

  // Check if data exists in database
  static Future<bool> hasData(String boxName, String key) async {
    try {
      final box = await Hive.openBox(boxName);
      return box.containsKey(key);
    } catch (e) {
      print('Error checking data existence: $e');
      return false;
    }
  }

  // Clear stored data
  static Future<void> clearData(String boxName, String key) async {
    try {
      final box = await Hive.openBox(boxName);
      await box.delete(key);
    } catch (e) {
      print('Error clearing data: $e');
    }
  }

  // Get cache version of stored data
  static Future<String?> getDataCacheVersion(String boxName, String key) async {
    try {
      final box = await Hive.openBox(boxName);
      final String? dataJson = box.get(key);

      if (dataJson != null && dataJson.isNotEmpty) {
        try {
          final Map<String, dynamic> dataMap = jsonDecode(dataJson);
          return dataMap['cache_version'] as String?;
        } catch (e) {
          print('Error parsing JSON for cache version: $e');
        }
      }
    } catch (e) {
      print('Error retrieving cache version: $e');
    }
    return null;
  }
}