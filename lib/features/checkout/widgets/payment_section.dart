import 'package:flutter/material.dart';
import 'package:gazzer_userapp/features/cart/domain/models/cart_model.dart';
import 'package:gazzer_userapp/features/checkout/controllers/checkout_controller.dart';
import 'package:gazzer_userapp/features/checkout/screens/checkout_screen.dart';
import 'package:gazzer_userapp/features/checkout/widgets/payment_method_bottom_sheet.dart';
import 'package:gazzer_userapp/features/profile/controllers/profile_controller.dart';
import 'package:gazzer_userapp/helper/price_converter.dart';
import 'package:gazzer_userapp/helper/responsive_helper.dart';
import 'package:gazzer_userapp/util/app_constants.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:gazzer_userapp/util/images.dart';
import 'package:gazzer_userapp/util/styles.dart';
import 'package:get/get.dart';
class PaymentSection extends StatelessWidget {
  final bool isCashOnDeliveryActive;
  final bool isDigitalPaymentActive;
  final bool isWalletActive;
  final bool isOfflinePaymentActive;
  final double total;
  final double deliveryCharge;
  final CheckoutController checkoutController;
  final bool fromCart;
  final bool? isGuestLogIn;
  final double? discount;
  final double? tax;
  final double? extraPackagingAmount;
  final int? subscriptionQty;
  final List<CartModel> cartList;
  final Function backBottomSheetCalc;
  const PaymentSection({
    super.key,
    required this.isCashOnDeliveryActive,
    required this.isDigitalPaymentActive,
    required this.isWalletActive,
    required this.total,
    required this.deliveryCharge,
    required this.checkoutController,
    required this.fromCart,
    required this.isOfflinePaymentActive,
    required this.cartList,
    this.tax,
    this.subscriptionQty,
    this.isGuestLogIn,
    this.extraPackagingAmount,
    this.discount,
    required this.backBottomSheetCalc
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          horizontal: ResponsiveHelper.isDesktop(context)
              ? 0
              : Dimensions.fontSizeDefault),
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeLarge,
          vertical: Dimensions.paddingSizeDefault),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('payment_method'.tr, style: robotoBold),
          InkWell(
            onTap: () {
              if (ResponsiveHelper.isDesktop(context)) {
                Get.dialog(Dialog(
                    backgroundColor: Colors.transparent,
                    child: PaymentMethodBottomSheet(
                      isCashOnDeliveryActive: isCashOnDeliveryActive,
                      isDigitalPaymentActive: isDigitalPaymentActive,
                      isWalletActive: isWalletActive,
                      totalPrice: total,
                      isOfflinePaymentActive: isOfflinePaymentActive,
                      deliveryCharge: deliveryCharge,
                      fromCart: fromCart,
                      tax: tax!,
                      discount: discount!,
                      cartList: cartList,
                      checkoutController: checkoutController,
                      extraPackagingAmount: extraPackagingAmount!,
                    ))).then((value){
                      if(value=='visa'){
                          if(Get.find<ProfileController>().userInfoModel!.walletBalance! < total){
                            AppConstants.isUseButtonTapped = true;
                          }if(Get.find<ProfileController>().userInfoModel!.walletBalance! >= total){
                            AppConstants.isUseButtonTapped = false;
                          }
                      }
                });
              } else {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (con) => PaymentMethodBottomSheet(
                    isCashOnDeliveryActive: isCashOnDeliveryActive,
                    isDigitalPaymentActive: isDigitalPaymentActive,
                    isWalletActive: isWalletActive,
                    totalPrice: total,
                    isOfflinePaymentActive: isOfflinePaymentActive,
                    deliveryCharge: deliveryCharge,
                    fromCart: fromCart,
                    tax: tax!,
                    discount: discount!,
                    cartList: cartList,
                    checkoutController: checkoutController,
                    extraPackagingAmount: extraPackagingAmount!,
                  ),
                ).then((value){
                  if(value=='visa'){
                    if(Get.find<ProfileController>().userInfoModel!.walletBalance! < total){
                      AppConstants.isUseButtonTapped = true;
                    }
                  }
                });
              }
            },
            child: Image.asset(Images.paymentSelect, height: 24, width: 24),
          ),
        ]),
        const Divider(),
        Container(
          decoration: ResponsiveHelper.isDesktop(context)
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  color: Theme.of(context).cardColor,
                  border: Border.all(
                      color: Theme.of(context).disabledColor.withOpacity(0.3),
                      width: 1),
                )
              : const BoxDecoration(),
          padding: ResponsiveHelper.isDesktop(context)
              ? const EdgeInsets.symmetric(
                  vertical: Dimensions.paddingSizeSmall,
                  horizontal: Dimensions.radiusDefault)
              : EdgeInsets.zero,
          child: checkoutController.paymentMethodIndex == 0
              ? Row(children: [
                  Image.asset(
                    Images.cash,
                    width: 20,
                    height: 20,
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                      child: Text(
                        'cash_on_delivery'.tr,
                    style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Colors.grey.shade700),
                  )),
                  Text(
                    PriceConverter.convertPrice(total),
                    textDirection: TextDirection.ltr,
                    style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: Theme.of(context).primaryColor),
                  )
                ])
              : Row(children: [
                  checkoutController.paymentMethodIndex != -1
                      ? Image.asset(
                          checkoutController.paymentMethodIndex == 0
                              ? Images.cash
                              : checkoutController.paymentMethodIndex == 1
                                  ? Images.wallet
                                  : Images.digitalPayment,
                          width: 20,
                          height: 20,
                          color: Theme.of(context).textTheme.bodyMedium!.color,
                        )
                      : Icon(Icons.wallet_outlined,
                          size: 18, color: Theme.of(context).disabledColor),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                      child: Row(children: [
                    Text(
                      checkoutController.paymentMethodIndex == 0
                          ? 'cash_on_delivery'.tr
                          : checkoutController.paymentMethodIndex == 1
                              ? 'wallet_payment'.tr
                              : checkoutController.paymentMethodIndex == 2
                                  ? 'pay_visa'.tr
                                  : checkoutController.paymentMethodIndex == 3
                                      ? '${'offline_payment'.tr} (${checkoutController.offlineMethodList![checkoutController.selectedOfflineBankIndex].methodName})'
                                      : 'select_payment_method'.tr,
                      style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).disabledColor),
                    ),
                    checkoutController.paymentMethodIndex == -1
                        ? Padding(
                            padding: const EdgeInsets.only(
                                left: Dimensions.paddingSizeExtraSmall),
                            child: Icon(Icons.error,
                                size: 16,
                                color: Theme.of(context).colorScheme.error),
                          )
                        : const SizedBox(),
                  ])),
                  !ResponsiveHelper.isDesktop(context)
                      ? PriceConverter.convertAnimationPrice(
                          total,
                          textStyle: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              color: Theme.of(context).primaryColor),
                        )
                      : const SizedBox(),
                ]),
        ),
        SizedBox(
            height: ResponsiveHelper.isDesktop(context)
                ? 0
                : Dimensions.paddingSizeSmall),
      ]),
    );
  }
}
