import 'package:gazzer_userapp/common/models/product_model.dart';
import 'package:gazzer_userapp/common/models/restaurant_model.dart';
import 'package:gazzer_userapp/features/category/domain/models/category_model.dart';
import 'package:gazzer_userapp/features/category/domain/services/category_service_interface.dart';
import 'package:get/get.dart';

import '../../../helper/cache_version_helper.dart';
import '../../../helper/category_model_db_helper.dart';

class CategoryController extends GetxController implements GetxService {
  final CategoryServiceInterface categoryServiceInterface;

  CategoryController({required this.categoryServiceInterface});

  List<CategoryModel>? _categoryList;

  List<CategoryModel>? get categoryList => _categoryList;

  List<CategoryModel>? _subCategoryList;

  List<CategoryModel>? get subCategoryList => _subCategoryList;

  List<Product>? _categoryProductList;

  List<Product>? get categoryProductList => _categoryProductList;

  List<Restaurant>? _categoryRestaurantList;

  List<Restaurant>? get categoryRestaurantList => _categoryRestaurantList;

  List<Product>? _searchProductList = [];

  List<Product>? get searchProductList => _searchProductList;

  List<Restaurant>? _searchRestaurantList = [];

  List<Restaurant>? get searchRestaurantList => _searchRestaurantList;

  // List<bool>? _interestCategorySelectedList;
  // List<bool>? get interestCategorySelectedList => _interestCategorySelectedList;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  int? _pageSize;

  int? get pageSize => _pageSize;

  int? _restaurantPageSize;

  int? get restaurantPageSize => _restaurantPageSize;

  bool _isSearching = false;

  bool get isSearching => _isSearching;

  int _subCategoryIndex = 0;

  int get subCategoryIndex => _subCategoryIndex;

  String _type = 'all';

  String get type => _type;

  bool _isRestaurant = false;

  bool get isRestaurant => _isRestaurant;

  String? _searchText = '';

  String? get searchText => _searchText;

  int _offset = 1;

  int get offset => _offset;

  // String? _restResultText = '';
  // String? _foodResultText = '';

  Future<void> getCategoryList(bool reload) async {
    String? categoryUuid;

    // Check if we need to reload or if the category list is null
    if (_categoryList == null || reload) {

      // Extract the UUID for 'category' API if available from CacheVersionHelper
      if (CacheVersionHelper.versionModel != null &&
          CacheVersionHelper.versionModel?.data != null) {
        for (var item in CacheVersionHelper.versionModel!.data!) {
          if (item.api == 'category' && item.uuid != null) {
            categoryUuid = item.uuid;
            break;
          }
        }
      }

      // Check if category list exists in database and has the latest version
      bool hasLocalCategoryList = await CategoryListDBHelper.hasCategoryList();

      if (hasLocalCategoryList) {
        // Get the cached version
        final localCacheVersion = await CategoryListDBHelper.getCategoryListCacheVersion();

        // Check if the local category list is the latest version by comparing UUIDs
        if (localCacheVersion == categoryUuid) {
          final localCategoryList = await CategoryListDBHelper.getCategoryList();
          if (localCategoryList != null) {
            // Use the cached category list data
            _categoryList = localCategoryList;
            update();
            return;
          }
        }
      }

      // Fetch from network
      print('Fetching category list from network');
      _categoryList = await categoryServiceInterface.getCategoryList(true, null);

      if (_categoryList != null) {
        // Save to local database with cache version
        print('Saving network category list to database');
        await CategoryListDBHelper.saveCategoryList(_categoryList!, cacheVersion: categoryUuid);
      } else {
        // Attempt to load cached data if network fetch failed
        final localCategoryList = await CategoryListDBHelper.getCategoryList();
        if (localCategoryList != null) {
          _categoryList = localCategoryList;
        }
      }

      update();
    }
  }
  void getSubCategoryList(String? categoryID) async {
    _subCategoryIndex = 0;
    _subCategoryList = null;
    _categoryProductList = null;
    _isRestaurant = false;
    _subCategoryList =
        await categoryServiceInterface.getSubCategoryList(categoryID);
    if (_subCategoryList != null) {
      getCategoryProductList(categoryID, 1, 'all', false);
    }
  }

  void setSubCategoryIndex(int index, String? categoryID) {
    _subCategoryIndex = index;
    if (_isRestaurant) {
      getCategoryRestaurantList(
          _subCategoryIndex == 0
              ? categoryID
              : _subCategoryList![index].id.toString(),
          1,
          _type,
          true);
    } else {
      getCategoryProductList(
          _subCategoryIndex == 0
              ? categoryID
              : _subCategoryList![index].id.toString(),
          1,
          _type,
          true);
    }
  }

  void getCategoryProductList(
      String? categoryID, int offset, String type, bool notify) async {
    _offset = offset;
    if (offset == 1) {
      if (_type == type) {
        _isSearching = false;
      }
      _type = type;
      if (notify) {
        update();
      }
      _categoryProductList = null;
    }
    ProductModel? productModel = await categoryServiceInterface
        .getCategoryProductList(categoryID, offset, type);
    if (productModel != null) {
      if (offset == 1) {
        _categoryProductList = [];
      }
      _categoryProductList!.addAll(productModel.products!);
      _pageSize = productModel.totalSize;
      _isLoading = false;
    }
    update();
  }

  void getCategoryRestaurantList(
      String? categoryID, int offset, String type, bool notify) async {
    _offset = offset;
    if (offset == 1) {
      if (_type == type) {
        _isSearching = false;
      }
      _type = type;
      if (notify) {
        update();
      }
      _categoryRestaurantList = null;
    }
    RestaurantModel? restaurantModel = await categoryServiceInterface
        .getCategoryRestaurantList(categoryID, offset, type);
    if (restaurantModel != null) {
      if (offset == 1) {
        _categoryRestaurantList = [];
      }
      _categoryRestaurantList!.addAll(restaurantModel.restaurants!);
      _restaurantPageSize = restaurantModel.totalSize;
      _isLoading = false;
    }
    update();
  }

  void searchData(String? query, String? categoryID, String type) async {
    if ((_isRestaurant && query!.isNotEmpty /*&& query != _restResultText*/) ||
        (!_isRestaurant &&
            query!.isNotEmpty /* && query != _foodResultText*/)) {
      _searchText = query;
      _type = type;
      if (_isRestaurant) {
        _searchRestaurantList = null;
      } else {
        _searchProductList = null;
      }
      _isSearching = true;
      update();

      Response response = await categoryServiceInterface.getSearchData(
          query, categoryID, _isRestaurant, type);
      if (response.statusCode == 200) {
        if (query.isEmpty) {
          if (_isRestaurant) {
            _searchRestaurantList = [];
          } else {
            _searchProductList = [];
          }
        } else {
          if (_isRestaurant) {
            // _restResultText = query;
            _searchRestaurantList = [];
            _searchRestaurantList!
                .addAll(RestaurantModel.fromJson(response.body).restaurants!);
          } else {
            // _foodResultText = query;
            _searchProductList = [];
            _searchProductList!
                .addAll(ProductModel.fromJson(response.body).products!);
          }
        }
      }
      update();
    }
  }

  void toggleSearch() {
    _isSearching = !_isSearching;
    _searchProductList = [];
    if (_categoryProductList != null) {
      _searchProductList!.addAll(_categoryProductList!);
    }
    update();
  }

  void showBottomLoader() {
    _isLoading = true;
    update();
  }

  // Future<bool> saveInterest(List<int?> interests) async {
  //   _isLoading = true;
  //   update();
  //   bool isSuccess = await categoryServiceInterface.saveUserInterests(interests);
  //   _isLoading = false;
  //   update();
  //   return isSuccess;
  // }

  // void addInterestSelection(int index) {
  //   _interestCategorySelectedList![index] = !_interestCategorySelectedList![index];
  //   update();
  // }

  void setRestaurant(bool isRestaurant) {
    _isRestaurant = isRestaurant;
    update();
  }
}
