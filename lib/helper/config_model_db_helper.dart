import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:math' as Math;

import '../features/splash/domain/models/config_model.dart';

class ConfigModelDBHelper {
  static const String boxName = 'configBox';
  static const String configKey = 'current_config';

  // Save config to database
  static Future<void> saveConfig(ConfigModel config) async {
    try {
      final box = await Hive.openBox(boxName);
      // Convert to JSON then sanitize
      final Map<String, dynamic> configMap = config.toJson();
      final String configJson = jsonEncode(configMap);
      await box.put(configKey, configJson);
      print('Config saved successfully');
    } catch (e) {
      print('Error saving config to database: $e');
    }
  }

  // Get config from database with additional safety
  static Future<ConfigModel?> getConfig() async {
    try {
      final box = await Hive.openBox(boxName);
      final String? configJson = box.get(configKey);

      if (configJson != null && configJson.isNotEmpty) {
        print('Retrieved config JSON: ${configJson.substring(0, Math.min(configJson.length, 50))}...');

        try {
          final Map<String, dynamic> configMap = jsonDecode(configJson);
          // First sanitize the map to handle nulls
          return _createSafeConfigFromJson(configMap);
        } catch (e) {
          print('Error parsing config JSON: $e');
          return null;
        }
      }
    } catch (e) {
      print('Error retrieving config from database: $e');
    }
    return null;
  }

  // Create a safe instance of ConfigModel with null checks
  static ConfigModel _createSafeConfigFromJson(Map<String, dynamic> json) {
    // Create a copy to avoid modifying the original
    final Map<String, dynamic> safeJson = Map<String, dynamic>.from(json);

    // Add null checks for fields that use toDouble() in ConfigModel.fromJson

    // 1. Handle appMinimumVersionAndroid - direct null check
    if (safeJson['app_minimum_version_android'] == null) {
      safeJson['app_minimum_version_android'] = 0.0;
    }

    // 2. Handle appMinimumVersionIos
    if (safeJson['app_minimum_version_ios'] == null) {
      safeJson['app_minimum_version_ios'] = 0.0;
    }

    // 3. Handle loyaltyPointItemPurchasePoint - this is calling toDouble() without null check
    if (safeJson['loyalty_point_item_purchase_point'] == null) {
      safeJson['loyalty_point_item_purchase_point'] = 0.0;
    }

    // 4. Handle refEarningExchangeRate - also uses toDouble()
    if (safeJson['ref_earning_exchange_rate'] == null) {
      safeJson['ref_earning_exchange_rate'] = 0.0;
    }

    // 5. Handle adminCommission - uses toDouble() without null check
    if (safeJson['admin_commission'] == null) {
      safeJson['admin_commission'] = 0.0;
    }

    // Now create the ConfigModel
    try {
      return ConfigModel.fromJson(safeJson);
    } catch (e) {
      print('Error creating ConfigModel: $e');
      // Return an empty ConfigModel if something goes wrong
      return ConfigModel();
    }
  }

  // Check if config exists in database
  static Future<bool> hasConfig() async {
    try {
      final box = await Hive.openBox(boxName);
      return box.containsKey(configKey);
    } catch (e) {
      print('Error checking config existence: $e');
      return false;
    }
  }

  // Clear stored config
  static Future<void> clearConfig() async {
    try {
      final box = await Hive.openBox(boxName);
      await box.delete(configKey);
    } catch (e) {
      print('Error clearing config: $e');
    }
  }
}