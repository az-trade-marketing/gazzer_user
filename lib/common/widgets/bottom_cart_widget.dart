import 'package:flutter/material.dart';
import 'package:gazzer_userapp/common/models/restaurant_model.dart';
import 'package:gazzer_userapp/common/widgets/custom_button_widget.dart';
import 'package:gazzer_userapp/features/cart/controllers/cart_controller.dart';
import 'package:gazzer_userapp/features/cart/controllers/cart_controller_extension.dart';
import 'package:gazzer_userapp/features/restaurant/controllers/restaurant_controller.dart';
import 'package:gazzer_userapp/helper/price_converter.dart';
import 'package:gazzer_userapp/helper/route_helper.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:gazzer_userapp/util/styles.dart';
import 'package:get/get.dart';

class BottomCartWidget extends StatelessWidget {
  final int? restaurantId;

  const BottomCartWidget({super.key, this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      return Container(
        height: GetPlatform.isIOS ? 100 : 70,
        width: Get.width,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(color: const Color(0xFF2A2A2A).withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${'items'.tr}: ${cartController.cartList.length}',
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(
                    '${'total'.tr}: ${PriceConverter.convertPrice(cartController.calculateTotalPrice())}',
                    style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
                  ),
                ]),
            CustomButtonWidget(
                buttonText: 'view_cart'.tr,
                width: 130,
                height: 45,
                onPressed: () async {
                  await Get.toNamed(RouteHelper.getCartRoute());
                  Get.find<RestaurantController>().makeEmptyRestaurant();
                  if (restaurantId != null) {
                    Get.find<RestaurantController>().getRestaurantDetails(Restaurant(id: restaurantId));
                  }
                })
          ]),
        ),
      );
    });
  }
}
