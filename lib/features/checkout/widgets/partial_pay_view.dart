import 'package:flutter/material.dart';
import 'package:gazzer_userapp/features/checkout/controllers/checkout_controller.dart';
import 'package:gazzer_userapp/features/profile/controllers/profile_controller.dart';
import 'package:gazzer_userapp/features/splash/controllers/splash_controller.dart';
import 'package:gazzer_userapp/features/splash/controllers/theme_controller.dart';
import 'package:gazzer_userapp/helper/price_converter.dart';
import 'package:gazzer_userapp/helper/responsive_helper.dart';
import 'package:gazzer_userapp/util/app_constants.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:gazzer_userapp/util/images.dart';
import 'package:gazzer_userapp/util/styles.dart';
import 'package:get/get.dart';

class PartialPayView extends StatefulWidget {
  final double totalPrice;
  bool isButtonTapped;

  PartialPayView({super.key, required this.totalPrice, required this.isButtonTapped});

  @override
  State<PartialPayView> createState() => _PartialPayViewState();
}

class _PartialPayViewState extends State<PartialPayView> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(builder: (checkoutController) {
      return Get.find<SplashController>().configModel!.partialPaymentStatus! &&
              !checkoutController.subscriptionOrder &&
              Get.find<SplashController>().configModel!.customerWalletStatus == 1 &&
              Get.find<ProfileController>().userInfoModel != null &&
              (checkoutController.distance != -1) &&
              Get.find<ProfileController>().userInfoModel!.walletBalance! > 0
          ? AnimatedContainer(
              duration: const Duration(seconds: 2),
              decoration: BoxDecoration(
                color: Get.find<ThemeController>().darkTheme
                    ? Theme.of(context).primaryColor.withOpacity(0.2)
                    : Theme.of(context).primaryColor.withOpacity(0.05),
                border: Border.all(color: Theme.of(context).primaryColor, width: 0.5),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                image: const DecorationImage(
                  alignment: Alignment.bottomRight,
                  image: AssetImage(Images.partialWalletTransparent),
                ),
              ),
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              margin: EdgeInsets.symmetric(
                horizontal:
                    ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeSmall,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Image.asset(Images.partialWallet, height: 30, width: 30),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      PriceConverter.convertPrice(Get.find<ProfileController>().userInfoModel!.walletBalance!),
                      style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeOverLarge, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Text(
                      checkoutController.isPartialPay
                          ? 'has_paid_by_your_wallet'.tr
                          : 'your_have_balance_in_your_wallet'.tr,
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                    ),
                  ]),
                ]),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  if (checkoutController.isPartialPay || checkoutController.paymentMethodIndex == 1)
                    Row(children: [
                      Container(
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      Text(
                        'applied'.tr,
                        style: robotoMedium.copyWith(
                            color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge),
                      )
                    ]),
                  if (widget.totalPrice > Get.find<ProfileController>().userInfoModel!.walletBalance!) ...[
                    if (!checkoutController.isPartialPay && checkoutController.paymentMethodIndex != 1)
                      Text(
                        'do_you_want_to_use_now'.tr,
                        style: robotoMedium.copyWith(
                            color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge),
                      ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          AppConstants.isUseButtonTapped = !AppConstants.isUseButtonTapped;
                        });

                        double walletBalance = Get.find<ProfileController>().userInfoModel!.walletBalance!;
                        double totalPrice = widget.totalPrice;
                        if (walletBalance >= totalPrice) return;
                        if (AppConstants.isUseButtonTapped) {
                          if (walletBalance >= totalPrice) {
                            // المحفظة تغطي المبلغ الكامل - يمكن استخدامها مباشرة
                            if (checkoutController.paymentMethodIndex != 1) {
                              checkoutController.setPaymentMethod(1); // حدد طريقة الدفع كمحفظة
                            }
                          } else {
                            // المحفظة لا تغطي المبلغ الكامل - فعّل الدفع الجزئي
                            checkoutController.changePartialPayment();
                            // يمكن الاحتفاظ بطريقة الدفع الحالية أو تغييرها
                          }
                        } else {
                          // تم إلغاء استخدام المحفظة
                          if (checkoutController.isPartialPay) {
                            checkoutController.changePartialPayment();
                          }
                          if (checkoutController.paymentMethodIndex == 1) {
                            checkoutController.setPaymentMethod(-1);
                          }
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: checkoutController.isPartialPay || checkoutController.paymentMethodIndex == 1
                              ? Theme.of(context).cardColor
                              : Theme.of(context).primaryColor,
                          border: Border.all(
                              color: checkoutController.isPartialPay || checkoutController.paymentMethodIndex == 1
                                  ? Colors.red
                                  : Theme.of(context).primaryColor,
                              width: 0.5),
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeLarge),
                        child: Text(
                          checkoutController.isPartialPay || checkoutController.paymentMethodIndex == 1
                              ? 'remove'.tr
                              : 'use'.tr,
                          style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              color: checkoutController.isPartialPay || checkoutController.paymentMethodIndex == 1
                                  ? Colors.red
                                  : Colors.white),
                        ),
                      ),
                    )
                  ]
                ]),
                checkoutController.paymentMethodIndex == 1
                    ? Text(
                        '${'remaining_wallet_balance'.tr}: ${PriceConverter.convertPrice(Get.find<ProfileController>().userInfoModel!.walletBalance! - widget.totalPrice)}',
                        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                      )
                    : const SizedBox(),
              ]),
            )
          : const SizedBox();
    });
  }
}
