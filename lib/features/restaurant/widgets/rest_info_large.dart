import 'package:flutter/material.dart';
import 'package:gazzer_userapp/common/models/restaurant_model.dart';
import 'package:gazzer_userapp/features/language/controllers/localization_controller.dart';
import 'package:gazzer_userapp/features/restaurant/controllers/restaurant_controller.dart';
import 'package:gazzer_userapp/features/restaurant/widgets/coupon_view_widget.dart';
import 'package:gazzer_userapp/features/restaurant/widgets/info_view_widget.dart';
import 'package:gazzer_userapp/features/restaurant/widgets/rest_opening_hours_widget.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:get/get.dart';

class RestInfoLarge extends StatelessWidget {
  const RestInfoLarge({super.key, required this.restaurant, required this.restController, required this.scrollingRate});

  final Restaurant restaurant;
  final RestaurantController restController;
  final double scrollingRate;

  @override
  Widget build(BuildContext context) {
    final openCloseHours = restController.todaySchedulte(restaurant.schedules);

    return Container(
      color: Theme.of(context).cardColor.withOpacity(scrollingRate),
      padding: EdgeInsets.only(
        bottom: 0,
        left: Get.find<LocalizationController>().isLtr ? 40 * scrollingRate : 0,
        right: Get.find<LocalizationController>().isLtr ? 0 : 40 * scrollingRate,
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          // height: (hasCoupon ? 290 : 190) - (scrollingRate * 25),
          decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1 - (0.1 * scrollingRate)), blurRadius: 10)]),
          margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
          padding: EdgeInsets.only(
              left: Get.find<LocalizationController>().isLtr ? 20 : 0,
              right: Get.find<LocalizationController>().isLtr ? 0 : 20,
              top: scrollingRate * (context.height * 0.035)),
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: Dimensions.paddingSizeSmall - (scrollingRate * Dimensions.paddingSizeSmall)),
            child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              InfoViewWidget(restaurant: restaurant, restController: restController, scrollingRate: scrollingRate),
              SizedBox(height: Dimensions.paddingSizeLarge - (scrollingRate * (Dimensions.paddingSizeLarge))),
              if (scrollingRate < 0.8) CouponViewWidget(scrollingRate: scrollingRate),
              if (openCloseHours?.$1 != null && openCloseHours?.$2 != null)
                RestOpeningHoursWidget(openHour: openCloseHours!.$1!, closeHour: openCloseHours.$2!),
            ]),
          ),
        ),
      ),
    );
  }
}
