import 'package:flutter/material.dart';
import 'package:gazzer_userapp/common/widgets/custom_snackbar_widget.dart';
import 'package:gazzer_userapp/features/auth/controllers/auth_controller.dart';
import 'package:gazzer_userapp/features/business/controllers/business_controller.dart';
import 'package:gazzer_userapp/features/cart/domain/models/cart_model.dart';
import 'package:gazzer_userapp/features/checkout/controllers/checkout_controller.dart';
import 'package:gazzer_userapp/features/checkout/domain/models/place_order_body_model.dart';
import 'package:gazzer_userapp/features/checkout/widgets/payment_button_new.dart';
import 'package:gazzer_userapp/features/profile/controllers/profile_controller.dart';
import 'package:gazzer_userapp/features/splash/controllers/splash_controller.dart';
import 'package:gazzer_userapp/helper/date_converter.dart';
import 'package:gazzer_userapp/helper/responsive_helper.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:gazzer_userapp/util/images.dart';
import 'package:gazzer_userapp/util/styles.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

class PaymentMethodBottomSheet extends StatefulWidget {
  final bool isCashOnDeliveryActive;
  final bool isDigitalPaymentActive;
  final bool isOfflinePaymentActive;
  final bool isWalletActive;
  final double totalPrice;
  final double deliveryCharge;
  final bool isSubscriptionPackage;
  final bool fromCart;
  final bool? isGuestLogIn;
  final double discount;
  final double tax;
  final double extraPackagingAmount;
  final int? subscriptionQty;
  final List<CartModel> cartList;
  final CheckoutController checkoutController;

  const PaymentMethodBottomSheet(
      {super.key,
      required this.isCashOnDeliveryActive,
      required this.isDigitalPaymentActive,
      required this.isWalletActive,
      required this.totalPrice,
      required this.deliveryCharge,
      required this.fromCart,
      required this.discount,
      required this.checkoutController,
      required this.extraPackagingAmount,
      this.isGuestLogIn,
      this.subscriptionQty,
      required this.tax,
      required this.cartList,
      this.isSubscriptionPackage = false,
      required this.isOfflinePaymentActive});

  @override
  State<PaymentMethodBottomSheet> createState() =>
      _PaymentMethodBottomSheetState();
}

class _PaymentMethodBottomSheetState extends State<PaymentMethodBottomSheet> {
  bool canSelectWallet = true;
  bool notHideCod = true;
  bool notHideWallet = true;
  bool notHideDigital = true;
  final JustTheController tooltipController = JustTheController();
  bool isLoading = false;
  late List<OnlineCart> carts;
  late DateTime scheduleStartDate;
  late List<SubscriptionDays> days;

  @override
  void initState() {
    super.initState();
    carts = generateOnlineCartList();
    days = generateSubscriptionDays();
    scheduleStartDate = processScheduleStartDate();
    if (!widget.isSubscriptionPackage &&
        !Get.find<AuthController>().isGuestLoggedIn()) {
      double walletBalance =
          Get.find<ProfileController>().userInfoModel!.walletBalance!;
      if (walletBalance < widget.totalPrice) {
        canSelectWallet = false;
      }
      if (Get.find<CheckoutController>().isPartialPay) {
        notHideWallet = false;
        if (Get.find<SplashController>().configModel!.partialPaymentMethod! ==
            'cod') {
          notHideCod = true;
          notHideDigital = false;
        } else if (Get.find<SplashController>()
                .configModel!
                .partialPaymentMethod! ==
            'digital_payment') {
          notHideCod = false;
          notHideDigital = true;
        } else if (Get.find<SplashController>()
                .configModel!
                .partialPaymentMethod! ==
            'both') {
          notHideCod = true;
          notHideDigital = true;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = Get.find<AuthController>().isLoggedIn();

    return SizedBox(
      width: 550,
      child: GetBuilder<CheckoutController>(builder: (checkoutController) {
        return GetBuilder<BusinessController>(builder: (businessController) {
          return Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(Dimensions.radiusLarge),
                  bottom: Radius.circular(ResponsiveHelper.isDesktop(context)
                      ? Dimensions.radiusLarge
                      : 0)),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeLarge,
                vertical: Dimensions.paddingSizeLarge),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ResponsiveHelper.isDesktop(context)
                  ? Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: () => Get.back(),
                        child: Container(
                          height: 30,
                          width: 30,
                          margin: const EdgeInsets.symmetric(
                              vertical: Dimensions.paddingSizeExtraSmall),
                          decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(50)),
                          child: const Icon(Icons.clear),
                        ),
                      ),
                    )
                  : Align(
                      alignment: Alignment.center,
                      child: Container(
                        height: 4,
                        width: 35,
                        margin: const EdgeInsets.symmetric(
                            vertical: Dimensions.paddingSizeExtraSmall),
                        decoration: BoxDecoration(
                            color: Theme.of(context).disabledColor,
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'payment_method'.tr,
                          style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge),
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      !widget.isSubscriptionPackage && notHideCod
                          ? Text(
                              'choose_payment_method'.tr,
                              style: robotoBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault),
                            )
                          : const SizedBox(),
                      SizedBox(
                        height: !widget.isSubscriptionPackage && notHideCod
                            ? Dimensions.paddingSizeExtraSmall
                            : 0,
                      ),
                      !widget.isSubscriptionPackage && notHideCod
                          ? Text(
                              'click_one_of_the_option_below'.tr,
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor,
                              ),
                            )
                          : const SizedBox(),
                      SizedBox(
                        height: !widget.isSubscriptionPackage
                            ? Dimensions.paddingSizeLarge
                            : 0,
                      ),
                      !widget.isSubscriptionPackage &&
                              Get.find<SplashController>()
                                      .configModel!
                                      .partialPaymentMethod! ==
                                  'both'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    widget.isCashOnDeliveryActive && notHideCod
                                        ? Expanded(
                                            child: PaymentButtonNew(
                                              icon: Images.codIcon,
                                              title: 'cash_on_delivery'.tr,
                                              isSelected: checkoutController
                                                      .paymentMethodIndex ==
                                                  0,
                                              onTap: () {
                                                checkoutController
                                                    .setPaymentMethod(0);
                                                Get.back();
                                              },
                                            ),
                                          )
                                        : const SizedBox(),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    widget.isDigitalPaymentActive &&
                                            notHideDigital
                                        ? Expanded(
                                            child: PaymentButtonNew(
                                              icon: Images.digitalPayment,
                                              title: 'pay_visa'.tr,
                                              isSelected: checkoutController
                                                      .paymentMethodIndex ==
                                                  2,
                                              onTap: () {
                                                checkoutController
                                                    .setPaymentMethod(2);
                                                Get.back();
                                              },
                                            ),
                                          )
                                        : const SizedBox(),
                                  ],
                                ),
                                const SizedBox(
                                    height: Dimensions.paddingSizeSmall),
                                widget.isWalletActive &&
                                        notHideWallet &&
                                        !checkoutController.subscriptionOrder &&
                                        isLoggedIn
                                    ? PaymentButtonNew(
                                        icon: Images.partialWallet,
                                        title: 'pay_via_wallet'.tr,
                                        isSelected: checkoutController
                                                .paymentMethodIndex ==
                                            1,
                                        onTap: () {
                                          if (canSelectWallet) {
                                            checkoutController
                                                .setPaymentMethod(1);
                                            Get.back();
                                          } else if (checkoutController
                                              .isPartialPay) {
                                            showCustomSnackBar(
                                              'you_can_not_user_wallet_in_partial_payment'
                                                  .tr,
                                            );
                                            Get.back();
                                          } else {
                                            showCustomSnackBar(
                                              'your_wallet_have_not_sufficient_balance'
                                                  .tr,
                                            );
                                            Get.back();
                                          }
                                        },
                                      )
                                    : const SizedBox(),
                              ],
                            )
                          : const SizedBox(),
                      !widget.isSubscriptionPackage &&
                              Get.find<SplashController>()
                                      .configModel!
                                      .partialPaymentMethod! ==
                                  'cod'
                          ? widget.isCashOnDeliveryActive && notHideCod
                              ? PaymentButtonNew(
                                  icon: Images.codIcon,
                                  title: 'cash_on_delivery'.tr,
                                  isSelected:
                                      checkoutController.paymentMethodIndex ==
                                          0,
                                  onTap: () {
                                    checkoutController.setPaymentMethod(0);
                                    Get.back();
                                  },
                                )
                              : const SizedBox()
                          : const SizedBox(),
                      !widget.isSubscriptionPackage &&
                              Get.find<SplashController>()
                                      .configModel!
                                      .partialPaymentMethod! ==
                                  'digital_payment'
                          ? widget.isDigitalPaymentActive && notHideDigital
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        widget.isDigitalPaymentActive &&
                                                notHideDigital
                                            ? Expanded(
                                                child: PaymentButtonNew(
                                                  icon: Images.digitalPayment,
                                                  title: 'pay_visa'.tr,
                                                  isSelected: checkoutController
                                                          .paymentMethodIndex ==
                                                      2,
                                                  onTap: () {
                                                    checkoutController
                                                        .setPaymentMethod(2);
                                                    Get.back();
                                                  },
                                                ),
                                              )
                                            : const SizedBox(),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        widget.isWalletActive && notHideWallet
                                            ? Expanded(
                                                child: PaymentButtonNew(
                                                  icon: Images.partialWallet,
                                                  title: 'pay_via_wallet'.tr,
                                                  isSelected: checkoutController
                                                          .paymentMethodIndex ==
                                                      1,
                                                  onTap: () {
                                                    if (canSelectWallet) {
                                                      checkoutController
                                                          .setPaymentMethod(1);
                                                      Get.back();
                                                    } else if (checkoutController
                                                        .isPartialPay) {
                                                      showCustomSnackBar(
                                                        'you_can_not_user_wallet_in_partial_payment'
                                                            .tr,
                                                      );
                                                      Get.back();
                                                    } else {
                                                      showCustomSnackBar(
                                                        'your_wallet_have_not_sufficient_balance'
                                                            .tr,
                                                      );
                                                      Get.back();
                                                    }
                                                  },
                                                ),
                                              )
                                            : const SizedBox(),
                                      ],
                                    ),
                                  ],
                                )
                              : const SizedBox()
                          : const SizedBox(),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                    ],
                  ),
                ),
              ),
            ]),
          );
        });
      }),
    );
  }

  List<SubscriptionDays> generateSubscriptionDays() {
    List<SubscriptionDays> days = [];
    for (int index = 0;
        index < widget.checkoutController.selectedDays.length;
        index++) {
      if (widget.checkoutController.selectedDays[index] != null) {
        days.add(SubscriptionDays(
          day: widget.checkoutController.subscriptionType == 'weekly'
              ? (index == 6 ? 0 : (index + 1)).toString()
              : widget.checkoutController.subscriptionType == 'monthly'
                  ? (index + 1).toString()
                  : index.toString(),
          time: DateConverter.dateToTime(
              widget.checkoutController.selectedDays[index]!),
        ));
      }
    }
    return days;
  }

  List<OnlineCart> generateOnlineCartList() {
    List<OnlineCart> carts = [];
    for (int index = 0; index < widget.cartList.length; index++) {
      CartModel cart = widget.cartList[index];
      List<int?> addOnIdList = [];
      List<int?> addOnQtyList = [];
      List<OrderVariation> variations = [];
      List<int?> optionIds = [];
      for (var addOn in cart.addOnIds!) {
        addOnIdList.add(addOn.id);
        addOnQtyList.add(addOn.quantity);
      }
      if (cart.product!.variations != null) {
        for (int i = 0; i < cart.product!.variations!.length; i++) {
          if (cart.variations![i].contains(true)) {
            variations.add(OrderVariation(
                name: cart.product!.variations![i].name,
                values: OrderVariationValue(label: [])));
            // ,qty: 0
            for (int j = 0;
                j < cart.product!.variations![i].variationValues!.length;
                j++) {
              if (cart.variations![i][j]!) {
                variations[variations.length - 1].values!.label!.add(
                    cart.product!.variations![i].variationValues![j].level);
                if (cart.product!.variations![i].variationValues![j].optionId !=
                    null) {
                  optionIds.add(cart
                      .product!.variations![i].variationValues![j].optionId);
                }
              }
            }
          }
        }
      }
      carts.add(OnlineCart(
        cart.id,
        cart.product!.id,
        cart.isCampaign! ? cart.product!.id : null,
        cart.discountedPrice.toString(),
        variations,
        cart.quantity,
        addOnIdList,
        cart.addOns,
        addOnQtyList,
        'Food',
        variationOptionIds: optionIds,
        itemType: !widget.fromCart ? "AppModelsItemCampaign" : null,
      ));
    }
    return carts;
  }

  DateTime processScheduleStartDate() {
    DateTime scheduleStartDate = DateTime.now();
    if (widget.checkoutController.timeSlots != null ||
        widget.checkoutController.timeSlots!.isNotEmpty) {
      DateTime date = widget.checkoutController.selectedDateSlot == 0
          ? DateTime.now()
          : widget.checkoutController.selectedDateSlot == 1
              ? DateTime.now().add(const Duration(days: 1))
              : widget.checkoutController.selectedCustomDate ?? DateTime.now();
      DateTime startTime = widget.checkoutController
          .timeSlots![widget.checkoutController.selectedTimeSlot!].startTime!;
      scheduleStartDate = DateTime(date.year, date.month, date.day,
          startTime.hour, startTime.minute + 1);
    }
    return scheduleStartDate;
  }
}
