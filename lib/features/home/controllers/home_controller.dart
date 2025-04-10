import 'package:gazzer_userapp/features/home/domain/models/banner_model.dart';
import 'package:gazzer_userapp/features/home/domain/models/cashback_model.dart';
import 'package:gazzer_userapp/features/home/domain/services/home_service_interface.dart';
import 'package:gazzer_userapp/helper/responsive_helper.dart';
import 'package:get/get.dart';

import '../../../helper/banner_model_db_helper.dart';
import '../../../helper/cache_version_helper.dart';

class HomeController extends GetxController implements GetxService {
  final HomeServiceInterface homeServiceInterface;

  HomeController({required this.homeServiceInterface});

  List<String?>? _bannerImageList;
  List<dynamic>? _bannerDataList;

  List<String?>? get bannerImageList => _bannerImageList;

  List<dynamic>? get bannerDataList => _bannerDataList;

  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  List<CashBackModel>? _cashBackOfferList;

  List<CashBackModel>? get cashBackOfferList => _cashBackOfferList;

  CashBackModel? _cashBackData;

  CashBackModel? get cashBackData => _cashBackData;

  bool _showFavButton = true;

  bool get showFavButton => _showFavButton;

  Future getBannerList(bool reload) async {
    String? bannerUuid;

    // Check if we need to reload or if the banner list is null
    if (_bannerImageList == null || reload) {
      // Extract the UUID for 'banner' API if available from CacheVersionHelper
      if (CacheVersionHelper.versionModel != null &&
          CacheVersionHelper.versionModel?.data != null) {
        for (var item in CacheVersionHelper.versionModel!.data!) {
          if (item.api == 'banner' && item.uuid != null) {
            bannerUuid = item.uuid;
            break;
          }
        }
      }

      // Check if banner exists in database and has the latest version
      bool hasLocalBanner = await BannerModelDBHelper.hasBanner();

      if (hasLocalBanner) {
        // Get the cached version
        final localCacheVersion = await BannerModelDBHelper.getBannerCacheVersion();

        // Check if the local banner is the latest version by comparing UUIDs
        if (localCacheVersion == bannerUuid) {
          final localBanner = await BannerModelDBHelper.getBanner();
          if (localBanner != null) {
            // Use the cached banner data
            _processBannerData(localBanner);
            update();
            return;
          }
        }
      }

      // Fetch from network
      print('Fetching banner from network');
      BannerModel? responseBanner = await homeServiceInterface.getBannerList();

      if (responseBanner != null) {
        // Process banner data
        _processBannerData(responseBanner);

        // Save to local database with cache version
        print('Saving network banner to database');
        await BannerModelDBHelper.saveBanner(responseBanner, cacheVersion: bannerUuid);
      } else {
        // This condition now always evaluates to false since hasConnection is removed
        if (false) {
          // This code will never execute
          final localBanner = await BannerModelDBHelper.getBanner();
          if (localBanner != null) {
            _processBannerData(localBanner);
          }
        }
      }

      update();
    }
  }
  void _processBannerData(BannerModel responseBanner) {
    _bannerImageList = [];
    _bannerDataList = [];

    if (responseBanner.campaigns != null) {
      for (var campaign in responseBanner.campaigns!) {
        _bannerImageList!.add(campaign.image);
        _bannerDataList!.add(campaign);
      }
    }

    if (responseBanner.banners != null) {
      for (var banner in responseBanner.banners!) {
        _bannerImageList!.add(banner.image);
        if (banner.food != null) {
          _bannerDataList!.add(banner.food);
        } else {
          _bannerDataList!.add(banner.restaurant);
        }
      }
    }

    // Add extra item for desktop if needed
    if (ResponsiveHelper.isDesktop(Get.context) &&
        _bannerImageList!.length % 3 != 0) {
      _bannerImageList!.add(_bannerImageList![0]);
      _bannerDataList!.add(_bannerDataList![0]);
    }
  }
  void setCurrentIndex(int index, bool notify) {
    _currentIndex = index;
    if (notify) {
      update();
    }
  }

  Future<void> getCashBackOfferList() async {
    _cashBackOfferList = null;
    _cashBackOfferList = await homeServiceInterface.getCashBackOfferList();
    update();
  }

  void forcefullyNullCashBackOffers() {
    _cashBackOfferList = null;
    update();
  }

  Future<void> getCashBackData(double amount) async {
    CashBackModel? cashBackModel =
        await homeServiceInterface.getCashBackData(amount);
    if (cashBackModel != null) {
      _cashBackData = cashBackModel;
    }
    update();
  }

  void changeFavVisibility() {
    _showFavButton = !_showFavButton;
    update();
  }
}
