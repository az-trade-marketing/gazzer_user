import '../features/category/domain/models/category_model.dart';
import 'hive_db_helper.dart';

class CategoryListDBHelper {
  static const String boxName = 'categoryBox';
  static const String categoryKey = 'category_list';

  // Save category list to database
  static Future<void> saveCategoryList(List<CategoryModel> categoryList, {String? cacheVersion}) async {
    // Convert list to a format that can be saved
    List<Map<String, dynamic>> categoryMapList = categoryList.map((category) => category.toJson()).toList();
    Map<String, dynamic> dataToSave = {
      'categories': categoryMapList,
    };

    if (cacheVersion != null) {
      dataToSave['cacheVersion'] = cacheVersion;
    }

    await HiveDBHelper.saveData(boxName, categoryKey, dataToSave);
  }

  // Get category list from database
  static Future<List<CategoryModel>?> getCategoryList() async {
    Map<String, dynamic>? data = await HiveDBHelper.getData<Map<String, dynamic>>(
        boxName,
        categoryKey,
            (json) => json
    );

    if (data != null && data.containsKey('categories')) {
      List<dynamic> categoryMapList = data['categories'];
      List<CategoryModel> categoryList = categoryMapList
          .map((categoryMap) => CategoryModel.fromJson(categoryMap))
          .toList();
      return categoryList;
    }

    return null;
  }

  // Check if category list exists in database
  static Future<bool> hasCategoryList() async {
    return await HiveDBHelper.hasData(boxName, categoryKey);
  }

  // Get cached version for category list
  static Future<String?> getCategoryListCacheVersion() async {
    return await HiveDBHelper.getDataCacheVersion(boxName, categoryKey);
  }

  // Clear stored category list
  static Future<void> clearCategoryList() async {
    await HiveDBHelper.clearData(boxName, categoryKey);
  }
}
