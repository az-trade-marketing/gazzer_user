import '../features/home/domain/models/banner_model.dart';
import 'hive_db_helper.dart';

class BannerModelDBHelper {
  static const String boxName = 'bannerBox';
  static const String bannerKey = 'current_banner';

  // Save banner to database
  static Future<void> saveBanner(BannerModel banner, {String? cacheVersion}) async {
    await HiveDBHelper.saveData(boxName, bannerKey, banner, cacheVersion: cacheVersion);
  }

  // Get banner from database
  static Future<BannerModel?> getBanner() async {
    return await HiveDBHelper.getData<BannerModel>(
        boxName,
        bannerKey,
            (json) => BannerModel.fromJson(json)
    );
  }

  // Check if banner exists in database
  static Future<bool> hasBanner() async {
    return await HiveDBHelper.hasData(boxName, bannerKey);
  }

  // Get cached version for banner
  static Future<String?> getBannerCacheVersion() async {
    return await HiveDBHelper.getDataCacheVersion(boxName, bannerKey);
  }

  // Clear stored banner
  static Future<void> clearBanner() async {
    await HiveDBHelper.clearData(boxName, bannerKey);
  }
}