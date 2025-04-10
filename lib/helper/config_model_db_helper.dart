import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:math' as Math;

import '../features/splash/domain/models/config_model.dart';
import 'hive_db_helper.dart';

class ConfigModelDBHelper {
  static const String boxName = 'configBox';
  static const String configKey = 'current_config';

  // Save config to database
  static Future<void> saveConfig(ConfigModel config, {String? cacheVersion}) async {
    Map<String, dynamic> configMap = config.toJson();

    // Apply safety measures to prevent null pointer issues
    configMap = _sanitizeConfigMap(configMap);

    await HiveDBHelper.saveData(boxName, configKey, configMap, cacheVersion: cacheVersion);
  }

  // Get config from database with additional safety
  static Future<ConfigModel?> getConfig() async {
    return await HiveDBHelper.getData<ConfigModel>(
        boxName,
        configKey,
            (json) => _createSafeConfigFromJson(json)
    );
  }

  // Create a safe instance of ConfigModel with null checks
  static ConfigModel _createSafeConfigFromJson(Map<String, dynamic> json) {
    // Create a copy to avoid modifying the original
    final Map<String, dynamic> safeJson = _sanitizeConfigMap(json);

    // Now create the ConfigModel
    try {
      return ConfigModel.fromJson(safeJson);
    } catch (e) {
      print('Error creating ConfigModel: $e');
      // Return an empty ConfigModel if something goes wrong
      return ConfigModel();
    }
  }

  // Sanitize config map to handle nulls
  static Map<String, dynamic> _sanitizeConfigMap(Map<String, dynamic> json) {
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

    // 3. Handle loyaltyPointItemPurchasePoint
    if (safeJson['loyalty_point_item_purchase_point'] == null) {
      safeJson['loyalty_point_item_purchase_point'] = 0.0;
    }

    // 4. Handle refEarningExchangeRate
    if (safeJson['ref_earning_exchange_rate'] == null) {
      safeJson['ref_earning_exchange_rate'] = 0.0;
    }

    // 5. Handle adminCommission
    if (safeJson['admin_commission'] == null) {
      safeJson['admin_commission'] = 0.0;
    }

    return safeJson;
  }

  // Check if config exists in database
  static Future<bool> hasConfig() async {
    return await HiveDBHelper.hasData(boxName, configKey);
  }

  // Get cached version for config
  static Future<String?> getConfigCacheVersion() async {
    return await HiveDBHelper.getDataCacheVersion(boxName, configKey);
  }

  // Clear stored config
  static Future<void> clearConfig() async {
    await HiveDBHelper.clearData(boxName, configKey);
  }
}