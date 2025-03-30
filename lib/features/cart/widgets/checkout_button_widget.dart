import 'package:flutter/material.dart';
import 'package:gazzer_userapp/common/widgets/custom_button_widget.dart';
import 'package:gazzer_userapp/common/widgets/custom_snackbar_widget.dart';
import 'package:gazzer_userapp/features/cart/controllers/cart_controller.dart';
import 'package:gazzer_userapp/features/coupon/controllers/coupon_controller.dart';
import 'package:gazzer_userapp/features/restaurant/controllers/restaurant_controller.dart';
import 'package:gazzer_userapp/features/splash/controllers/splash_controller.dart';
import 'package:gazzer_userapp/helper/price_converter.dart';
import 'package:gazzer_userapp/helper/responsive_helper.dart';
import 'package:gazzer_userapp/helper/route_helper.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:gazzer_userapp/util/images.dart';
import 'package:gazzer_userapp/util/styles.dart';
import 'package:get/get.dart';

class CheckoutButtonWidget extends StatelessWidget {
  final CartController cartController;
  final List<bool> availableList;
  final bool isRestaurantOpen;

  const CheckoutButtonWidget(
      {super.key,
      required this.cartController,
      required this.availableList,
      required this.isRestaurantOpen});

  @override
  Widget build(BuildContext context) {
    double percentage = 0;
    bool isDesktop = ResponsiveHelper.isDesktop(context);

    // Calculate the total subtotal for all items
    double totalSubtotal = cartController.cartList.fold(
      0,
      (sum, item) =>
          sum +
          (((cartController.itemPrice +
                  cartController.variationPrice +
                  cartController.addOns) /
              cartController.cartList.length)),
    );



    //  cartController.cartList.length == 1 ?   : cartController.cartList.fold(
    // 0,
    // (sum, item) => sum + (item.price! * item.quantity!),
    // )
    return Container(
      width: Dimensions.webMaxWidth,
      padding: const EdgeInsets.symmetric(
          vertical: Dimensions.paddingSizeSmall,
          horizontal: Dimensions.paddingSizeDefault),
      decoration: isDesktop
          ? null
          : BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
      child: SafeArea(
        child:
            GetBuilder<RestaurantController>(builder: (restaurantController) {
          if (Get.find<RestaurantController>().restaurant != null &&
              Get.find<RestaurantController>().restaurant!.freeDelivery !=
                  null &&
              !Get.find<RestaurantController>().restaurant!.freeDelivery! &&
              Get.find<SplashController>().configModel!.freeDeliveryOver !=
                  null) {
            percentage = totalSubtotal /
                Get.find<SplashController>().configModel!.freeDeliveryOver!;
          }
          return Column(mainAxisSize: MainAxisSize.min, children: [
            (restaurantController.restaurant != null &&
                    restaurantController.restaurant!.freeDelivery != null &&
                    !restaurantController.restaurant!.freeDelivery! &&
                    Get.find<SplashController>()
                            .configModel!
                            .freeDeliveryOver !=
                        null &&
                    percentage < 1)
                ? Padding(
                    padding: EdgeInsets.only(
                        bottom: isDesktop ? Dimensions.paddingSizeLarge : 0),
                    child: Column(children: [
                      Row(children: [
                        Image.asset(Images.percentTag, height: 20, width: 20),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        PriceConverter.convertAnimationPrice(
                          Get.find<SplashController>()
                                  .configModel!
                                  .freeDeliveryOver! -
                              totalSubtotal,
                          textStyle: robotoMedium.copyWith(
                              color: Theme.of(context).primaryColor),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Text('more_for_free_delivery'.tr,
                            style: robotoMedium.copyWith(
                                color: Theme.of(context).disabledColor)),
                      ]),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      LinearProgressIndicator(
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.2),
                        value: percentage,
                      ),
                    ]),
                  )
                : const SizedBox(),
            !isDesktop
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeSmall),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('subtotal'.tr,
                            style: robotoMedium.copyWith(
                                color: Theme.of(context).primaryColor)),
                        PriceConverter.convertAnimationPrice(
                          totalSubtotal,
                          textStyle: robotoRegular.copyWith(
                              color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
            GetBuilder<CartController>(builder: (cartController) {
              return CustomButtonWidget(
                radius: 10,
                buttonText:/* !(restaurantController.isRestaurantOpenNow(
                    restaurantController.restaurant?.active?? false, restaurantController.restaurant?.schedules??[]))
                    ? 'not_active'.tr
                    :*/ 'proceed_to_checkout'.tr,
                onPressed: cartController.isLoading ||
                         restaurantController.restaurant == null
                    ? null
                    : () {
                        _processToCheckoutButtonPressed(restaurantController);
                      },
              );
            }),
            SizedBox(height: isDesktop ? Dimensions.paddingSizeExtraLarge : 0),
          ]);
        }),
      ),
    );
  }

  void _processToCheckoutButtonPressed(
      RestaurantController restaurantController) {
    if (!cartController.cartList.first.product!.scheduleOrder! &&
        cartController.availableList.contains(false)) {
      showCustomSnackBar('one_or_more_product_unavailable'.tr);
    } else if (restaurantController.restaurant!.freeDelivery == null ||
        restaurantController.restaurant!.cutlery == null) {
      showCustomSnackBar('restaurant_is_unavailable'.tr);
    }
    /* else if(!isRestaurantOpen) {
      showCustomSnackBar('restaurant_is_close_now'.tr);
    } */
    else {
      Get.find<CouponController>().removeCouponData(false);
      Get.toNamed(RouteHelper.getCheckoutRoute('cart'));
    }
  }
}
