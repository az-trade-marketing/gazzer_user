import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:gazzer_userapp/common/widgets/no_internet_screen_widget.dart';
import 'package:gazzer_userapp/features/auth/controllers/auth_controller.dart';
import 'package:gazzer_userapp/features/cart/controllers/cart_controller.dart';
import 'package:gazzer_userapp/features/favourite/controllers/favourite_controller.dart';
import 'package:gazzer_userapp/features/notification/domain/models/notification_body_model.dart';
import 'package:gazzer_userapp/features/splash/controllers/splash_controller.dart';
import 'package:gazzer_userapp/features/splash/domain/models/deep_link_body.dart';
import 'package:gazzer_userapp/helper/address_helper.dart';
import 'package:gazzer_userapp/helper/route_helper.dart';
import 'package:gazzer_userapp/util/app_constants.dart';
import 'package:gazzer_userapp/util/images.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  final NotificationBodyModel? notificationBody;
  final DeepLinkBody? linkBody;

  const SplashScreen({super.key, required this.notificationBody, required this.linkBody});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  late StreamSubscription<List<ConnectivityResult>> _onConnectivityChanged;

  @override
  void initState() {
    super.initState();

    bool firstTime = true;
    _onConnectivityChanged = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      if (!firstTime) {
        bool isNotConnected = !result.contains(ConnectivityResult.wifi) && !result.contains(ConnectivityResult.mobile);
        if (mounted) {
          isNotConnected ? const SizedBox() : ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: isNotConnected ? Colors.red : Colors.green,
            duration: Duration(seconds: isNotConnected ? 6000 : 3),
            content: Text(
              isNotConnected ? 'no_connection'.tr : 'connected'.tr,
              textAlign: TextAlign.center,
            ),
          ));
        }
        if (!isNotConnected) {
          _route();
        }
      }
      firstTime = false;
    });

    Get.find<SplashController>().initSharedData();
    if (AddressHelper.getAddressFromSharedPref() != null &&
        (AddressHelper.getAddressFromSharedPref()!.zoneIds == null ||
            AddressHelper.getAddressFromSharedPref()!.zoneData == null)) {
      AddressHelper.clearAddressFromSharedPref();
    }
    if (Get.find<AuthController>().isGuestLoggedIn() || Get.find<AuthController>().isLoggedIn()) {
      Get.find<CartController>().getCartDataOnline();
    }
    _route();
  }

  @override
  void dispose() {
    super.dispose();

    _onConnectivityChanged.cancel();
  }

  void _route() {
    Get.find<SplashController>().getConfigData().then((isSuccess) {
      if (isSuccess) {
        Timer(const Duration(seconds: 1), () async {
          double? minimumVersion = 0;
          if (GetPlatform.isAndroid) {
            minimumVersion = Get.find<SplashController>().configModel!.appMinimumVersionAndroid;
          } else if (GetPlatform.isIOS) {
            minimumVersion = Get.find<SplashController>().configModel!.appMinimumVersionIos;
          }
          if (AppConstants.appVersion < minimumVersion! || Get.find<SplashController>().configModel!.maintenanceMode!) {
            Get.offNamed(RouteHelper.getUpdateRoute(AppConstants.appVersion < minimumVersion));
          } else {
            if (widget.notificationBody != null && widget.linkBody == null) {
              _forNotificationRouteProcess();
            } else {
              if (Get.find<AuthController>().isLoggedIn()) {
                _forLoggedInUserRouteProcess();
              } else {
                if (Get.find<SplashController>().showIntro()!) {
                  _newlyRegisteredRouteProcess();
                } else {
                  if (Get.find<AuthController>().isGuestLoggedIn()) {
                    _forGuestUserRouteProcess();
                  } else {
                    await Get.find<AuthController>().guestLogin();
                    _forGuestUserRouteProcess();
                    // Get.offNamed(RouteHelper.getSignInRoute(RouteHelper.splash));
                  }
                }
              }
            }
          }
        });
      }
    });
  }

  void _forNotificationRouteProcess() {
    if (widget.notificationBody!.notificationType == NotificationType.order) {
      Get.offNamed(RouteHelper.getOrderDetailsRoute(widget.notificationBody!.orderId));
    } else if (widget.notificationBody!.notificationType == NotificationType.general) {
      Get.offNamed(RouteHelper.getNotificationRoute(fromNotification: true));
    } else {
      Get.offNamed(RouteHelper.getChatRoute(
          notificationBody: widget.notificationBody, conversationID: widget.notificationBody!.conversationId));
    }
  }

  Future<void> _forLoggedInUserRouteProcess() async {
    Get.find<AuthController>().updateToken();
    await Get.find<FavouriteController>().getFavouriteList();
    if (AddressHelper.getAddressFromSharedPref() != null) {
      Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
    } else {
      Get.offNamed(RouteHelper.getAccessLocationRoute('splash'));
    }
  }

  void _newlyRegisteredRouteProcess() {
    if (AppConstants.languages.length > 1) {
      Get.offNamed(RouteHelper.getLanguageRoute('splash'));
    } else {
      Get.offNamed(RouteHelper.getOnBoardingRoute());
    }
  }

  void _forGuestUserRouteProcess() {
    if (AddressHelper.getAddressFromSharedPref() != null) {
      Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
    } else {
      Get.find<SplashController>().navigateToLocationScreen('splash', offNamed: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _globalKey,
      body: GetBuilder<SplashController>(builder: (splashController) {
        return splashController.hasConnection
            ? SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Image.asset(
                  Images.gazzerSplash,
                  fit: BoxFit.cover,
                ),
              )
            : NoInternetScreen(
                child: SplashScreen(notificationBody: widget.notificationBody, linkBody: widget.linkBody));
      }),
    );
  }
}
