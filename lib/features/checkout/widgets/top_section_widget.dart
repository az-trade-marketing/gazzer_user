import 'package:flutter/material.dart';
import 'package:gazzer_userapp/common/widgets/custom_text_field_widget.dart';
import 'package:gazzer_userapp/features/auth/controllers/auth_controller.dart';
import 'package:gazzer_userapp/features/auth/widgets/auth_dialog_widget.dart';
import 'package:gazzer_userapp/features/cart/domain/models/cart_model.dart';
import 'package:gazzer_userapp/features/checkout/controllers/checkout_controller.dart';
import 'package:gazzer_userapp/features/checkout/widgets/coupon_section.dart';
import 'package:gazzer_userapp/features/checkout/widgets/guest_login_widget.dart';
import 'package:gazzer_userapp/features/checkout/widgets/order_type_widget.dart';
import 'package:gazzer_userapp/features/checkout/widgets/partial_pay_view.dart';
import 'package:gazzer_userapp/features/checkout/widgets/payment_section.dart';
import 'package:gazzer_userapp/features/checkout/widgets/subscription_view.dart';
import 'package:gazzer_userapp/features/checkout/widgets/time_slot_section.dart';
import 'package:gazzer_userapp/features/location/controllers/location_controller.dart';
import 'package:gazzer_userapp/helper/auth_helper.dart';
import 'package:gazzer_userapp/helper/responsive_helper.dart';
import 'package:gazzer_userapp/helper/route_helper.dart';
import 'package:gazzer_userapp/util/app_constants.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:gazzer_userapp/util/images.dart';
import 'package:gazzer_userapp/util/styles.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

class TopSectionWidget extends StatelessWidget {
  final double charge;
  final double deliveryCharge;
  final LocationController locationController;
  final bool tomorrowClosed;
  final bool todayClosed;
  final double price;
  final double discount;
  final double addOns;
  final bool restaurantSubscriptionActive;
  final bool showTips;
  final bool isCashOnDeliveryActive;
  final bool isDigitalPaymentActive;
  final bool isOfflinePaymentActive;
  final bool isWalletActive;
  final bool fromCart;
  final double total;
  final JustTheController tooltipController3;
  final JustTheController tooltipController2;
  final TextEditingController guestNameTextEditingController;
  final TextEditingController guestNumberTextEditingController;
  final TextEditingController guestEmailController;
  final FocusNode guestNumberNode;
  final FocusNode guestEmailNode;
  final JustTheController loginTooltipController;
  final Function() callBack;
  final List<CartModel> cartList;

  const TopSectionWidget(
      {super.key,
      required this.charge,
      required this.deliveryCharge,
      required this.locationController,
      required this.tomorrowClosed,
      required this.todayClosed,
      required this.price,
      required this.discount,
      required this.addOns,
      required this.restaurantSubscriptionActive,
      required this.showTips,
      required this.isCashOnDeliveryActive,
      required this.isDigitalPaymentActive,
      required this.isWalletActive,
      required this.fromCart,
      required this.total,
      required this.tooltipController3,
      required this.tooltipController2,
      required this.guestNameTextEditingController,
      required this.guestNumberTextEditingController,
      required this.guestNumberNode,
      required this.isOfflinePaymentActive,
      required this.guestEmailController,
      required this.guestEmailNode,
      required this.loginTooltipController,
    required this.callBack,
    required this.cartList,
  });

  @override
  Widget build(BuildContext context) {
    bool takeAway = false;
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    bool isGuestLoggedIn = Get.find<AuthController>().isGuestLoggedIn();
    bool isLoggedIn = Get.find<AuthController>().isLoggedIn();

    return GetBuilder<CheckoutController>(builder: (checkoutController) {
      takeAway = (checkoutController.orderType == 'take_away');
      return Column(children: [
        SizedBox(
            height: isGuestLoggedIn && !isDesktop
                ? Dimensions.paddingSizeSmall
                : 0),

        isGuestLoggedIn
            ? GuestLoginWidget(
                loginTooltipController: loginTooltipController,
                onTap: () async {
                  if (!isDesktop) {
                    await Get.toNamed(
                            RouteHelper.getSignInRoute(Get.currentRoute))!
                        .then((value) {
                      if (AuthHelper.isLoggedIn()) {
                        callBack();
                      }
                    });
                  } else {
                    Get.dialog(const Center(
                            child: AuthDialogWidget(
                                exitFromApp: false, backFromThis: true)))
                        .then((value) {
                      if (AuthHelper.isLoggedIn()) {
                        callBack();
                      }
                    });
                  }
                },
              )
            : const SizedBox(),
        SizedBox(height: isGuestLoggedIn ? Dimensions.paddingSizeSmall : 0),

        SizedBox(
            height: !isDesktop &&
                    isCashOnDeliveryActive &&
                    restaurantSubscriptionActive
                ? Dimensions.paddingSizeSmall
                : 0),

        isCashOnDeliveryActive && restaurantSubscriptionActive && isLoggedIn
            ? Container(
                width: context.width,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 1))
                  ],
                ),
                margin: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 0 : Dimensions.fontSizeDefault),
                padding: EdgeInsets.symmetric(
                    vertical: Dimensions.paddingSizeSmall,
                    horizontal: isDesktop
                        ? Dimensions.paddingSizeLarge
                        : Dimensions.paddingSizeLarge),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('order_type'.tr, style: robotoMedium),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Row(children: [
                        Expanded(
                            child: OrderTypeWidget(
                          title: 'regular_order'.tr,
                          icon: Images.regularOrder,
                          isSelected: !checkoutController.subscriptionOrder,
                          onTap: () {
                            checkoutController.setSubscription(false);
                            if (checkoutController.isPartialPay) {
                              checkoutController.changePartialPayment();
                            } else {
                              checkoutController.setPaymentMethod(-1);
                            }
                            checkoutController.updateTips(
                              Get.find<AuthController>()
                                      .getDmTipIndex()
                                      .isNotEmpty
                                  ? int.parse(Get.find<AuthController>()
                                      .getDmTipIndex())
                                  : 1,
                              notify: false,
                            );
                          },
                        )),
                        SizedBox(
                            width: isCashOnDeliveryActive
                                ? Dimensions.paddingSizeSmall
                                : 0),
                        Expanded(
                            child: OrderTypeWidget(
                          title: 'subscription_order'.tr,
                          icon: Images.subscriptionOrder,
                          isSelected: checkoutController.subscriptionOrder,
                          onTap: () {
                            checkoutController.setSubscription(true);
                            checkoutController.addTips(0);
                            if (checkoutController.isPartialPay) {
                              checkoutController.changePartialPayment();
                            } else {
                              checkoutController.setPaymentMethod(-1);
                            }
                          },
                        )),
                      ]),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      checkoutController.subscriptionOrder
                          ? SubscriptionView(
                              checkoutController: checkoutController,
                            )
                          : const SizedBox(),
                      SizedBox(
                          height: checkoutController.subscriptionOrder
                              ? Dimensions.paddingSizeLarge
                              : 0),
                    ]),
              )
            : const SizedBox(),
        SizedBox(
            height: ResponsiveHelper.isMobile(context)
                ? Dimensions.paddingSizeSmall
                : isCashOnDeliveryActive &&
                        restaurantSubscriptionActive &&
                        isLoggedIn
                    ? Dimensions.paddingSizeSmall
                    : 0),

        /// Time Slot
        TimeSlotSection(
            fromCart: fromCart,
            checkoutController: checkoutController,
            tomorrowClosed: tomorrowClosed,
            todayClosed: todayClosed,
            tooltipController2: tooltipController2),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('additional_note'.tr, style: robotoMedium),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              CustomTextFieldWidget(
                controller: checkoutController.noteController,
                hintText: 'share_any_specific_delivery_details_here'.tr,
                showLabelText: false,
                maxLines: 1,
                inputType: TextInputType.multiline,
                inputAction: TextInputAction.done,
                capitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),

        const SizedBox(
          height: Dimensions.paddingSizeExtraLarge,
        ),

        /// Coupon
        !ResponsiveHelper.isDesktop(context) && !isGuestLoggedIn
            ? CouponSection(
                charge: charge,
                checkoutController: checkoutController,
                price: price,
                discount: discount,
                addOns: addOns,
                deliveryCharge: deliveryCharge,
                total: total,
              )
            : const SizedBox(),
        SizedBox(
            height: !ResponsiveHelper.isDesktop(context)
                ? Dimensions.paddingSizeSmall
                : 0),

        ///Delivery Address
        // DeliverySection(
        //   checkoutController: checkoutController,
        //   locationController: locationController,
        //   guestNameTextEditingController: guestNameTextEditingController,
        //   guestNumberTextEditingController: guestNumberTextEditingController,
        //   guestNumberNode: guestNumberNode,
        //   guestEmailController: guestEmailController,
        //   guestEmailNode: guestEmailNode,
        // ),
        // const SizedBox(height: Dimensions.paddingSizeSmall),

        ///DmTips
        // DeliveryManTipsSection(
        //   takeAway: takeAway,
        //   tooltipController3: tooltipController3,
        //   checkoutController: checkoutController,
        //   totalPrice: total,
        //   onTotalChange: (double price) => total + price,
        // ),

        // SizedBox(height: (checkoutController.orderType != 'take_away' && Get.find<SplashController>().configModel!.dmTipsStatus == 1) ? Dimensions.paddingSizeExtraSmall : 0),

        ///payment..
        Column(children: [
          isDesktop
              ? PaymentSection(
                  isCashOnDeliveryActive: isCashOnDeliveryActive,
                  isDigitalPaymentActive: isDigitalPaymentActive,
                  isWalletActive: isWalletActive,
                  total: total,
                  checkoutController: checkoutController,
                  isOfflinePaymentActive: isOfflinePaymentActive,
                  deliveryCharge: deliveryCharge,
                  fromCart: fromCart,
                  cartList: cartList,
            backBottomSheetCalc: (){

              }

                )
              : const SizedBox(),
          // SizedBox(height: isGuestLoggedIn && !isDesktop ? 0 : Dimensions.paddingSizeDefault),

          !isDesktop && !isGuestLoggedIn
              ? PartialPayView(
                  totalPrice: total,
                  isButtonTapped: false,
                )
              : const SizedBox(),
        ]),
      ]);
    });
  }
}
