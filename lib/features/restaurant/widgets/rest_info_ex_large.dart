import 'package:flutter/material.dart';
import 'package:gazzer_userapp/common/models/restaurant_model.dart';
import 'package:gazzer_userapp/common/widgets/custom_image_widget.dart';
import 'package:gazzer_userapp/features/language/controllers/localization_controller.dart';
import 'package:gazzer_userapp/features/restaurant/controllers/restaurant_controller.dart';
import 'package:gazzer_userapp/features/restaurant/widgets/coupon_view_widget.dart';
import 'package:gazzer_userapp/features/restaurant/widgets/info_view_widget.dart';
import 'package:gazzer_userapp/features/splash/controllers/splash_controller.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:gazzer_userapp/util/images.dart';
import 'package:gazzer_userapp/util/styles.dart';
import 'package:get/get.dart';
import 'package:marquee/marquee.dart';

class RestInfoExLarge extends StatelessWidget {
  const RestInfoExLarge({
    super.key,
    required this.restaurant,
    required this.restController,
    required this.scrollingRate,
  });

  final Restaurant restaurant;
  final RestaurantController restController;
  final double scrollingRate;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        height: restaurant.announcementActive! ? 200 : 160,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 1))
          ],
        ),
        margin: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
        child: Column(
          children: [
            if (restaurant.announcementActive != null &&
                restaurant.announcementActive! &&
                restaurant.announcementMessage != null)
              Container(
                height: 40 - (scrollingRate * 40),
                padding: EdgeInsets.only(
                  left: Get.find<LocalizationController>().isLtr ? 250 : 20,
                  right: Get.find<LocalizationController>().isLtr ? 20 : 250,
                ),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(Dimensions.radiusDefault),
                      topRight: Radius.circular(Dimensions.radiusDefault)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Image.asset(Images.announcement, height: 26, width: 26),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Flexible(
                    child: Marquee(
                      text: restaurant.announcementMessage!,
                      style:
                          robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).cardColor),
                      blankSpace: 20.0,
                      velocity: 100.0,
                      accelerationDuration: const Duration(seconds: 5),
                      decelerationDuration: const Duration(milliseconds: 500),
                      accelerationCurve: Curves.linear,
                      decelerationCurve: Curves.easeOut,
                    ),
                  ),
                ]),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(children: [
                    SizedBox(width: context.width * 0.17 - (scrollingRate * 90)),
                    Expanded(
                        child: InfoViewWidget(
                            restaurant: restaurant, restController: restController, scrollingRate: scrollingRate)),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(child: CouponViewWidget(scrollingRate: scrollingRate)),
                  ]),
                  Positioned(
                    left: Get.find<LocalizationController>().isLtr ? 30 : null,
                    right: Get.find<LocalizationController>().isLtr ? null : 30,
                    top: -80 + (scrollingRate * 77),
                    child: Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).cardColor,
                          border: Border.all(color: Theme.of(context).primaryColor, width: 0.2),
                          boxShadow: [
                            BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 10)
                          ]),
                      padding: const EdgeInsets.all(2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(500),
                        child: Stack(children: [
                          CustomImageWidget(
                            image:
                                '${Get.find<SplashController>().configModel!.baseUrls!.restaurantImageUrl}/${restaurant.logo}',
                            height: 200 - (scrollingRate * 90),
                            width: 200 - (scrollingRate * 90),
                            fit: BoxFit.cover,
                            isRestaurant: true,
                          ),
                          if (!restController.isRestaurantOpenNow(restaurant.active!, restaurant.schedules))
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      const BorderRadius.vertical(bottom: Radius.circular(Dimensions.radiusSmall)),
                                  color: Colors.black.withOpacity(0.6),
                                ),
                                child: Text(
                                  'closed_now'.tr,
                                  textAlign: TextAlign.center,
                                  style:
                                      robotoRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
                                ),
                              ),
                            ),
                        ]),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
