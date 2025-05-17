import 'package:flutter/material.dart';
import 'package:gazzer_userapp/common/models/restaurant_model.dart';
import 'package:gazzer_userapp/common/widgets/custom_image_widget.dart';
import 'package:gazzer_userapp/common/widgets/customizable_space_bar_widget.dart';
import 'package:gazzer_userapp/features/coupon/controllers/coupon_controller.dart';
import 'package:gazzer_userapp/features/restaurant/controllers/restaurant_controller.dart';
import 'package:gazzer_userapp/features/restaurant/widgets/rest_info_ex_large.dart';
import 'package:gazzer_userapp/features/restaurant/widgets/rest_info_large.dart';
import 'package:gazzer_userapp/features/splash/controllers/splash_controller.dart';
import 'package:gazzer_userapp/helper/responsive_helper.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:gazzer_userapp/util/images.dart';
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
                    ? RestInfoLarge(
                        restaurant: restaurant,
                        restController: restController,
                        scrollingRate: scrollingRate,
                      )
                    : RestInfoExLarge(
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
