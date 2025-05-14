import 'package:flutter/material.dart';
import 'package:gazzer_userapp/common/models/restaurant_model.dart';
import 'package:gazzer_userapp/common/widgets/custom_image_widget.dart';
import 'package:gazzer_userapp/common/widgets/customizable_space_bar_widget.dart';
import 'package:gazzer_userapp/features/coupon/controllers/coupon_controller.dart';
import 'package:gazzer_userapp/features/language/controllers/localization_controller.dart';
import 'package:gazzer_userapp/features/restaurant/controllers/restaurant_controller.dart';
import 'package:gazzer_userapp/features/restaurant/widgets/coupon_view_widget.dart';
import 'package:gazzer_userapp/features/restaurant/widgets/desktop_rest_info_widget.dart';
import 'package:gazzer_userapp/features/restaurant/widgets/info_view_widget.dart';
import 'package:gazzer_userapp/features/splash/controllers/splash_controller.dart';
import 'package:gazzer_userapp/helper/responsive_helper.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:gazzer_userapp/util/images.dart';
import 'package:gazzer_userapp/util/styles.dart';
import 'package:get/get.dart';

class RestaurantInfoSectionWidget extends StatelessWidget {
  final Restaurant restaurant;
  final RestaurantController restController;
  final bool hasCoupon;

  const RestaurantInfoSectionWidget(
      {super.key, required this.restaurant, required this.restController, required this.hasCoupon});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    final double xyz = MediaQuery.of(context).size.width - 1170;
    final double realSpaceNeeded = xyz / 2;

    return SliverAppBar(
      expandedHeight: isDesktop
          ? 350
          : hasCoupon
              ? 400
              : 300,
      toolbarHeight: isDesktop ? 150 : 90,
      pinned: true,
      floating: false,
      elevation: 0.5,
      backgroundColor: Theme.of(context).cardColor,
      leading: !isDesktop
          ? IconButton(
              icon: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).primaryColor),
                alignment: Alignment.center,
                padding: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
                child: Icon(Icons.chevron_left, color: Theme.of(context).cardColor, size: 28),
              ),
              onPressed: () => Get.back(),
            )
          : const SizedBox(),
      flexibleSpace: GetBuilder<CouponController>(builder: (couponController) {
        return Container(
          margin: isDesktop ? EdgeInsets.symmetric(horizontal: realSpaceNeeded) : EdgeInsets.zero,
          child: FlexibleSpaceBar(
            titlePadding: EdgeInsets.zero,
            centerTitle: true,
            expandedTitleScale: isDesktop ? 1 : 1.1,
            title: CustomizableSpaceBarWidget(
              builder: (context, scrollingRate) {
                return !isDesktop
                    ? Container(
                        color: Theme.of(context).cardColor.withOpacity(scrollingRate),
                        padding: EdgeInsets.only(
                          bottom: 0,
                          left: Get.find<LocalizationController>().isLtr ? 40 * scrollingRate : 0,
                          right: Get.find<LocalizationController>().isLtr ? 0 : 40 * scrollingRate,
                        ),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            height: (hasCoupon ? 290 : 190) - (scrollingRate * 25),
                            decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.1 - (0.1 * scrollingRate)), blurRadius: 10)
                                ]),
                            margin: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                            padding: EdgeInsets.only(
                                left: Get.find<LocalizationController>().isLtr ? 20 : 0,
                                right: Get.find<LocalizationController>().isLtr ? 0 : 20,
                                top: scrollingRate * (context.height * 0.035)),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical:
                                      Dimensions.paddingSizeSmall - (scrollingRate * Dimensions.paddingSizeSmall)),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    InfoViewWidget(
                                        restaurant: restaurant,
                                        restController: restController,
                                        scrollingRate: scrollingRate),
                                    SizedBox(
                                        height: Dimensions.paddingSizeLarge -
                                            (scrollingRate * (isDesktop ? 2 : Dimensions.paddingSizeLarge))),
                                    if (scrollingRate < 0.8) CouponViewWidget(scrollingRate: scrollingRate),
                                    () {
                                      final openCloseHours = restController.todaySchedulte(restaurant.schedules);
                                      if (openCloseHours != null) {
                                        final closingAfter = restController.closingAfter(openCloseHours.$2!);
                                        print(closingAfter);
                                        return Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text("${"opens_at".tr}: ",
                                                          style: robotoRegular.copyWith(
                                                            color: Colors.black38,
                                                          )),
                                                      Text(
                                                        ' ${openCloseHours.$1?.format(context)}',
                                                        style: robotoMedium.copyWith(
                                                          color: Colors.black54,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text("${"closes_at".tr}: ",
                                                          style: robotoRegular.copyWith(
                                                            color: Colors.black38,
                                                          )),
                                                      Text(
                                                        ' ${openCloseHours.$2?.format(context)}',
                                                        style: robotoMedium.copyWith(
                                                          color: Colors.black54,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox.shrink(),
                                                ],
                                              ),
                                              if (closingAfter < 30 && closingAfter > 0)
                                                DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.withAlpha(180),
                                                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: Dimensions.paddingSizeDefault,
                                                        vertical: Dimensions.paddingSizeExtraSmall),
                                                    child: Text(
                                                      "this_restaurant_is_closing_in"
                                                          .trParams({"time": closingAfter.toString()}),
                                                      style: robotoBold.copyWith(
                                                        color: Theme.of(context).cardColor,
                                                        fontSize: Dimensions.fontSizeDefault,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                            ],
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    }()
                                  ]),
                            ),
                          ),
                        ),
                      )
                    : DeskTopInfoWidget(
                        restaurant: restaurant,
                        restController: restController,
                        scrollingRate: scrollingRate,
                      );
              },
            ),
            background: Container(
              margin: EdgeInsets.only(bottom: isDesktop ? 100 : (hasCoupon ? 200 : 100)),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Dimensions.radiusLarge)),
                child: CustomImageWidget(
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: Images.restaurantCover,
                  image:
                      '${Get.find<SplashController>().configModel!.baseUrls!.restaurantCoverPhotoUrl}/${restaurant.coverPhoto}',
                  isRestaurant: true,
                ),
              ),
            ),
          ),
        );
      }),
      actions: const [SizedBox()],
    );
  }
}
