import 'package:gazzer_userapp/api/api_client.dart';
import 'package:gazzer_userapp/common/widgets/custom_loader_widget.dart';
import 'package:gazzer_userapp/features/address/controllers/address_controller.dart';
import 'package:gazzer_userapp/features/auth/controllers/auth_controller.dart';
import 'package:gazzer_userapp/features/location/controllers/location_controller.dart';
import 'package:gazzer_userapp/features/location/widgets/pick_map_dialog.dart';
import 'package:gazzer_userapp/features/splash/domain/models/config_model.dart';
import 'package:gazzer_userapp/features/splash/domain/services/splash_service_interface.dart';
import 'package:gazzer_userapp/helper/address_helper.dart';
import 'package:gazzer_userapp/helper/responsive_helper.dart';
import 'package:gazzer_userapp/helper/route_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../helper/config_model_db_helper.dart';

class SplashController extends GetxController implements GetxService {
  final SplashServiceInterface splashServiceInterface;

  SplashController({required this.splashServiceInterface});

  ConfigModel? _configModel;

  ConfigModel? get configModel => _configModel;

  bool _firstTimeConnectionCheck = true;

  bool get firstTimeConnectionCheck => _firstTimeConnectionCheck;

  bool _hasConnection = true;

  bool get hasConnection => _hasConnection;

  bool _savedCookiesData = false;

  bool get savedCookiesData => _savedCookiesData;

  String? _htmlText;

  String? get htmlText => _htmlText;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  bool _showReferBottomSheet = false;

  bool get showReferBottomSheet => _showReferBottomSheet;

  DateTime get currentTime => DateTime.now();

  Future<bool> getConfigData() async {
    _hasConnection = true;
    _savedCookiesData = getCookiesData();

    // Check if config exists in database
    bool hasLocalConfig = await ConfigModelDBHelper.hasConfig();
    print('Has local config: $hasLocalConfig');

    if (hasLocalConfig) {
      final localConfig = await ConfigModelDBHelper.getConfig();
      if (localConfig != null) {
        print('Successfully loaded local config');
        _configModel = localConfig;
        update();
        return true;
      } else {
        print('Local config found but failed to load');
      }
    }

    // Fetch from network
    print('Fetching config from network');
    Response response = await splashServiceInterface.getConfigData();
    bool isSuccess = false;

    if (response.statusCode == 200) {
      _configModel = splashServiceInterface.prepareConfigData(response);
      if (_configModel != null) {
        // Save to local database
        print('Saving network config to database');
        await ConfigModelDBHelper.saveConfig(_configModel!);
        isSuccess = true;
      }
    } else {
      if (response.statusText == ApiClient.noInternetMessage) {
        _hasConnection = false;

        // Try to load any stored config if no connection
        final localConfig = await ConfigModelDBHelper.getConfig();
        if (localConfig != null) {
          _configModel = localConfig;
          isSuccess = true;
        }
      } else {
        isSuccess = false;
      }
    }

    update();
    return isSuccess;
  }
  Future<bool> initSharedData() {
    return splashServiceInterface.initSharedData();
  }

  bool? showIntro() {
    return splashServiceInterface.showIntro();
  }

  void disableIntro() {
    splashServiceInterface.disableIntro();
  }

  void setFirstTimeConnectionCheck(bool isChecked) {
    _firstTimeConnectionCheck = isChecked;
  }

  void saveCookiesData(bool data) {
    splashServiceInterface.saveCookiesData(data);
    _savedCookiesData = true;
    update();
  }

  bool getCookiesData() {
    return splashServiceInterface.getCookiesData();
  }

  void cookiesStatusChange(String? data) {
    splashServiceInterface.cookiesStatusChange(data);
  }

  bool getAcceptCookiesStatus(String data) {
    return splashServiceInterface.getAcceptCookiesStatus(data);
  }

  Future<bool> subscribeMail(String email) async {
    _isLoading = true;
    bool isSuccess = false;
    update();
    isSuccess = await splashServiceInterface.subscribeMail(email);
    _isLoading = false;
    update();
    return isSuccess;
  }

  Future<void> navigateToLocationScreen(String page,
      {bool offNamed = false, bool offAll = false}) async {
    bool fromSignup = page == RouteHelper.signUp;
    bool fromHome = page == 'home';
    if (!fromHome && AddressHelper.getAddressFromSharedPref() != null) {
      Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
      Get.find<LocationController>().autoNavigate(
          AddressHelper.getAddressFromSharedPref(),
          fromSignup,
          null,
          false,
          ResponsiveHelper.isDesktop(Get.context));
    } else if (Get.find<AuthController>().isLoggedIn()) {
      Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
      await Get.find<AddressController>().getAddressList();
      Get.back();
      if (Get.find<AddressController>().addressList != null &&
          Get.find<AddressController>().addressList!.isEmpty) {
        if (ResponsiveHelper.isDesktop(Get.context)) {
          showGeneralDialog(
              context: Get.context!,
              pageBuilder: (_, __, ___) {
                return SizedBox(
                  height: 300,
                  width: 300,
                  child: PickMapDialog(
                    fromSignUp: (page == RouteHelper.signUp),
                    canRoute: false,
                    fromAddAddress: false,
                    route: null,
                  ),
                );
              });
        } else {
          Get.toNamed(RouteHelper.getPickMapRoute(page, false));
        }
      } else {
        if (offNamed) {
          Get.offNamed(RouteHelper.getAccessLocationRoute(page));
        } else if (offAll) {
          Get.offAllNamed(RouteHelper.getAccessLocationRoute(page));
        } else {
          Get.toNamed(RouteHelper.getAccessLocationRoute(page));
        }
      }
    } else {
      if (ResponsiveHelper.isDesktop(Get.context)) {
        showGeneralDialog(
            context: Get.context!,
            pageBuilder: (_, __, ___) {
              return SizedBox(
                height: 300,
                width: 300,
                child: PickMapDialog(
                    fromSignUp: (page == RouteHelper.signUp),
                    canRoute: false,
                    fromAddAddress: false,
                    route: null),
              );
            });
      } else {
        Get.toNamed(RouteHelper.getPickMapRoute(page, false));
      }
    }
  }

  void saveReferBottomSheetStatus(bool data) {
    splashServiceInterface.saveReferBottomSheetStatus(data);
    _showReferBottomSheet = data;
    update();
  }

  void getReferBottomSheetStatus() {
    _showReferBottomSheet = splashServiceInterface.getReferBottomSheetStatus();
  }
}
