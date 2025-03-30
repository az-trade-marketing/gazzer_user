import 'package:flutter/material.dart';
import 'package:gazzer_userapp/features/auth/controllers/auth_controller.dart';
import 'package:gazzer_userapp/features/cart/domain/models/cart_model.dart';
import 'package:gazzer_userapp/features/checkout/controllers/checkout_controller.dart';
import 'package:gazzer_userapp/features/checkout/widgets/partial_pay_view.dart';
import 'package:gazzer_userapp/features/checkout/widgets/payment_section.dart';
import 'package:gazzer_userapp/features/coupon/controllers/coupon_controller.dart';
import 'package:gazzer_userapp/features/location/controllers/location_controller.dart';
import 'package:gazzer_userapp/features/profile/controllers/profile_controller.dart';
import 'package:gazzer_userapp/features/splash/controllers/splash_controller.dart';
import 'package:gazzer_userapp/helper/price_converter.dart';
import 'package:gazzer_userapp/helper/responsive_helper.dart';
import 'package:gazzer_userapp/util/app_constants.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:gazzer_userapp/util/styles.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

class BottomSectionWidget extends StatelessWidget {
  final CartModel? cart;
  final bool isCashOnDeliveryActive;
  final bool isDigitalPaymentActive;
  final bool isOfflinePaymentActive;
  final bool isWalletActive;
  final double total;
  final double subTotal;
  final double discount;
  final CouponController couponController;
  final bool taxIncluded;
  final double tax;
  double deliveryCharge;
  final double charge;
  final CheckoutController checkoutController;
  final LocationController locationController;
  final bool todayClosed;
  final bool tomorrowClosed;
  final double orderAmount;
  final double? maxCodOrderAmount;
  final int subscriptionQty;
  final double taxPercent;
  final bool fromCart;
  final List<CartModel> cartList;
  final double price;
  final double addOns;
  final TextEditingController guestNameTextEditingController;
  final TextEditingController guestNumberTextEditingController;
  final TextEditingController guestEmailController;
  final FocusNode guestNumberNode;
  final FocusNode guestEmailNode;
  final ExpansionTileController expansionTileController;
  final JustTheController serviceFeeTooltipController;
  final double referralDiscount;
  final double extraPackagingAmount;
  final bool isTapped;

  BottomSectionWidget({
    super.key,
    this.cart,
    required this.isCashOnDeliveryActive,
    required this.isDigitalPaymentActive,
    required this.isWalletActive,
    required this.total,
    required this.subTotal,
    required this.discount,
    required this.couponController,
    required this.taxIncluded,
    required this.tax,
    required this.deliveryCharge,
    required this.checkoutController,
    required this.locationController,
    required this.todayClosed,
    required this.tomorrowClosed,
    required this.orderAmount,
    this.maxCodOrderAmount,
    required this.subscriptionQty,
    required this.taxPercent,
    required this.fromCart,
    required this.cartList,
    required this.price,
    required this.addOns,
    required this.charge,
    required this.guestNameTextEditingController,
    required this.guestNumberTextEditingController,
    required this.guestNumberNode,
    required this.isOfflinePaymentActive,
    required this.guestEmailController,
    required this.guestEmailNode,
    required this.expansionTileController,
    required this.serviceFeeTooltipController,
    required this.referralDiscount,
    required this.extraPackagingAmount,
    required this.isTapped,
  });

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    bool isGuestLoggedIn = Get.find<AuthController>().isGuestLoggedIn();

    // Group the cartList by restaurant
    Map<String, List<CartModel>> restaurantGroupedCartList = {};
    for (var cartItem in cartList) {
      String restaurantName = cartItem.product!.restaurantName!;
      if (!restaurantGroupedCartList.containsKey(restaurantName)) {
        restaurantGroupedCartList[restaurantName] = [];
      }
      restaurantGroupedCartList[restaurantName]!.add(cartItem);
    }

    // Calculate delivery charge for grouped orders
    double groupedDeliveryCharge = restaurantGroupedCartList.length > 1
        ? deliveryCharge +
            (restaurantGroupedCartList.length - 1) *
                Get.find<SplashController>()
                    .configModel!
                    .deliveryFeeMultiVendor!
        : deliveryCharge;
    calcTotal() {
      debugPrint("delivery charge button section:: $deliveryCharge");
      if (couponController.coupon?.couponType == "free_delivery") {
        deliveryCharge = 0;
        return orderAmount + deliveryCharge;
      } else if (AppConstants.isUseButtonTapped == true) {
        return Get.find<ProfileController>().userInfoModel!.walletBalance! >= (orderAmount + deliveryCharge)
            ? 0.0
            : (orderAmount + deliveryCharge) - Get.find<ProfileController>().userInfoModel!.walletBalance!;
      } else {
        return orderAmount + deliveryCharge;
      }
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        isDesktop && !isGuestLoggedIn
            ? PartialPayView(
                totalPrice: total,
                isButtonTapped: isTapped,
              )
            : const SizedBox(),
        !isDesktop
            ? Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingSizeDefault,
                    horizontal: Dimensions.paddingSizeDefault),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      orderDetailsView(
                          context, isDesktop, restaurantGroupedCartList),
                    ]),
              )
            : const SizedBox(),
        !isDesktop
            ? Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingSizeDefault,
                    horizontal: Dimensions.paddingSizeDefault),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      pricingView(context, isDesktop, groupedDeliveryCharge),
                    ]),
              )
            : const SizedBox(),
        Padding(
          padding: const EdgeInsetsDirectional.only(
              start: 20.0, end: 20.0, bottom: 20.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(.3)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'payment_amount'.tr,
                  textDirection: TextDirection.ltr,
                  style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeExtraLarge,
                      color: Theme.of(context).primaryColor),
                ),
                Text(
                  PriceConverter.convertPrice(calcTotal()),
                  textDirection: TextDirection.ltr,
                  style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeExtraLarge,
                      color: Theme.of(context).primaryColor),
                ),
              ],
            ),
          ),
        ),
        !isDesktop
            ? PaymentSection(
                isCashOnDeliveryActive: isCashOnDeliveryActive,
                isDigitalPaymentActive: isDigitalPaymentActive,
                isWalletActive: isWalletActive,
                total: calcTotal(),
                checkoutController: checkoutController,
                isOfflinePaymentActive: isOfflinePaymentActive,
                deliveryCharge: deliveryCharge,
                fromCart: fromCart,
                discount: discount,
                extraPackagingAmount: extraPackagingAmount,
                isGuestLogIn: isGuestLoggedIn,
                subscriptionQty: subscriptionQty,
                tax: tax,
                cartList: cartList,
          backBottomSheetCalc: (){

          }
              )
            : const SizedBox(),
      ]),
    );
  }

  Widget pricingView(
      BuildContext context, bool isDesktop, double groupedDeliveryCharge) {
    return Container(
      decoration: !isDesktop
          ? BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 1))
              ],
            )
          : null,
      padding: !isDesktop
          ? const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall)
          : EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          controller: expansionTileController,
          title: Text('pay'.tr, style: !isDesktop ? robotoBold : robotoBold),
          trailing: Icon(Icons.arrow_forward_ios_outlined,
              size: 20, color: Theme.of(context).textTheme.bodyLarge!.color),
          tilePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          onExpansionChanged: (value) =>
              checkoutController.expandedUpdate(value),
          initiallyExpanded: !isDesktop ? false : true,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Divider(
                  thickness: 0.5,
                  color: Theme.of(context).hintColor.withOpacity(0.5)),
              SizedBox(height: !isDesktop ? Dimensions.paddingSizeSmall : 0),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                    !checkoutController.subscriptionOrder
                        ? 'subtotal'.tr
                        : 'item_price'.tr,
                    style: robotoRegular),
                Text(
                    PriceConverter.convertPrice(cartList.fold(
                        0,
                        (total, item) =>
                            total! + (item.price! * item.quantity!))),
                    style: robotoRegular,
                    textDirection: TextDirection.ltr),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('variations'.tr, style: robotoRegular),
                Text(
                    '(+) ${PriceConverter.convertPrice(orderAmount - (cartList.fold(0, (total, item) => total + (item.price! * item.quantity!))))}',
                    style: robotoRegular,
                    textDirection: TextDirection.ltr),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('discount'.tr, style: robotoRegular),
                Row(children: [
                  Text('(-) ', style: robotoRegular),
                  PriceConverter.convertAnimationPrice(discount,
                      textStyle: robotoRegular)
                ]),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              (couponController.discount! > 0 || couponController.freeDelivery)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('coupon_discount'.tr,
                                    style: robotoRegular),
                                Row(children: [
                                  Text('(-) ', style: robotoRegular),
                                  PriceConverter.convertAnimationPrice(
                                      couponController.discount,
                                      textStyle: robotoRegular)
                                ]),
                              ]),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                        ])
                  : const SizedBox(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('vat_tax'.tr, style: robotoRegular),
                Text(PriceConverter.convertPrice(tax),
                    style: robotoRegular, textDirection: TextDirection.ltr),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('delivery_charge'.tr, style: robotoRegular),
                Text(
                    PriceConverter.convertPrice(
                        couponController.coupon?.couponType == "free_delivery"
                            ? 0
                            : deliveryCharge),
                    style: robotoRegular,
                    textDirection: TextDirection.ltr),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),
            ]),
          ],
        ),
      ),
    );
  }

  Widget orderDetailsView(BuildContext context, bool isDesktop,
      Map<String, List<CartModel>> restaurantGroupedCartList) {
    return Container(
      decoration: !isDesktop
          ? BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 1))
              ],
            )
          : null,
      padding: !isDesktop
          ? const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall)
          : EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text('order_details'.tr,
              style: !isDesktop ? robotoBold : robotoBold),
          trailing: Icon(Icons.arrow_forward_ios_outlined,
              size: 20, color: Theme.of(context).textTheme.bodyLarge!.color),
          tilePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          onExpansionChanged: (value) {
            // Handle expansion change if needed
          },
          initiallyExpanded: !isDesktop ? false : true,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Divider(
                  thickness: 0.5,
                  color: Theme.of(context).hintColor.withOpacity(0.5)),
              SizedBox(height: !isDesktop ? Dimensions.paddingSizeSmall : 0),
              ...restaurantGroupedCartList.entries.map((entry) {
                String restaurantName = entry.key;
                List<CartModel> groupedItems = entry.value;
                double restaurantTotal = groupedItems.fold(
                  0.0,
                  (total, item) =>
                      total + (item.price! * item.quantity!.toDouble()),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName,
                      style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    ...groupedItems.map((cartItem) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${cartItem.quantity} x ${cartItem.product!.name}',
                            style: robotoRegular,
                          ),
                          Text(
                            PriceConverter.convertPrice(cartItem.price! *
                                cartItem.quantity!.toDouble()),
                            style: robotoRegular,
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                  ],
                );
              }),
            ]),
          ],
        ),
      ),
    );
  }
}
