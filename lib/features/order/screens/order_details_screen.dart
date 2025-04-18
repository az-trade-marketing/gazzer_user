import 'package:flutter/material.dart';
import 'package:gazzer_userapp/common/widgets/custom_app_bar_widget.dart';
import 'package:gazzer_userapp/common/widgets/custom_dialog_widget.dart';
import 'package:gazzer_userapp/common/widgets/footer_view_widget.dart';
import 'package:gazzer_userapp/common/widgets/menu_drawer_widget.dart';
import 'package:gazzer_userapp/common/widgets/web_page_title_widget.dart';
import 'package:gazzer_userapp/features/checkout/widgets/offline_success_dialog.dart';
import 'package:gazzer_userapp/features/order/controllers/order_controller.dart';
import 'package:gazzer_userapp/features/order/domain/models/order_details_model.dart';
import 'package:gazzer_userapp/features/order/domain/models/order_model.dart';
import 'package:gazzer_userapp/features/order/domain/models/subscription_schedule_model.dart';
import 'package:gazzer_userapp/features/order/widgets/bottom_view_widget.dart';
import 'package:gazzer_userapp/features/order/widgets/order_info_section.dart';
import 'package:gazzer_userapp/features/order/widgets/order_pricing_section.dart';
import 'package:gazzer_userapp/features/splash/controllers/splash_controller.dart';
import 'package:gazzer_userapp/helper/date_converter.dart';
import 'package:gazzer_userapp/helper/responsive_helper.dart';
import 'package:gazzer_userapp/helper/route_helper.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:gazzer_userapp/util/styles.dart';
import 'package:get/get.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel? orderModel;
  final int? orderId;
  final bool fromOfflinePayment;
  final String? contactNumber;
  final bool fromGuestTrack;

  const OrderDetailsScreen({
    super.key,
    required this.orderModel,
    required this.orderId,
    this.contactNumber,
    this.fromOfflinePayment = false,
    this.fromGuestTrack = false,
  });

  @override
  OrderDetailsScreenState createState() => OrderDetailsScreenState();
}

class OrderDetailsScreenState extends State<OrderDetailsScreen>
    with WidgetsBindingObserver {
  final ScrollController scrollController = ScrollController();

  void _loadData(BuildContext context) async {
    await Get.find<OrderController>()
        .trackOrder(widget.orderId.toString(), widget.orderModel, false,
        contactNumber: widget.contactNumber)
        .then((value) {
      if (widget.fromOfflinePayment) {
        Future.delayed(
            const Duration(seconds: 2),
                () => showAnimatedDialog(
                context, OfflineSuccessDialog(orderId: widget.orderId)));
      }
    });
    if (widget.orderModel == null) {
      await Get.find<SplashController>().getConfigData();
    }
    Get.find<OrderController>().getOrderCancelReasons();
    Get.find<OrderController>().getOrderDetails(widget.orderId.toString());
    if (Get.find<OrderController>().trackModel != null) {
      Get.find<OrderController>().callTrackOrderApi(
          orderModel: Get.find<OrderController>().trackModel!,
          orderId: widget.orderId.toString(),
          contactNumber: widget.contactNumber);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData(context);
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Get.find<OrderController>().callTrackOrderApi(
          orderModel: Get.find<OrderController>().trackModel!,
          orderId: widget.orderId.toString(),
          contactNumber: widget.contactNumber);
    } else if (state == AppLifecycleState.paused) {
      Get.find<OrderController>().cancelTimer();
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    Get.find<OrderController>().cancelTimer();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvoked: (val) async {
        if ((widget.orderModel == null || widget.fromOfflinePayment) &&
            !widget.fromGuestTrack) {
          Get.offAllNamed(RouteHelper.getInitialRoute());
        } else if (widget.fromGuestTrack) {
          return;
        } else {
          return;
        }
      },
      child: GetBuilder<OrderController>(builder: (orderController) {
        double itemsPrice = 0;
        double? discount = 0;
        double? couponDiscount = 0;
        double? tax = 0;
        double addOns = 0;
        double? dmTips = 0;
        double additionalCharge = 0;
        double extraPackagingCharge = 0;
        double referrerBonusAmount = 0;
        bool showChatPermission = true;
        bool? taxIncluded = false;
        OrderModel? order = orderController.trackModel;
        bool subscription = false;
        List<String> schedules = [];

        // Define maps for delivery charges and total orders per restaurant
        Map<String, double> restaurantDeliveryCharges = {};
        Map<String, double> restaurantTotalOrders = {};

        if (orderController.orderDetails != null && order != null) {
          subscription = order.subscription != null;

          if (subscription) {
            if (order.subscription!.type == 'weekly') {
              List<String> weekDays = [
                'sunday',
                'monday',
                'tuesday',
                'wednesday',
                'thursday',
                'friday',
                'saturday'
              ];
              for (SubscriptionScheduleModel schedule
              in orderController.schedules!) {
                schedules.add(
                    '${weekDays[schedule.day!].tr} (${DateConverter.convertTimeToTime(schedule.time!)})');
              }
            } else if (order.subscription!.type == 'monthly') {
              for (SubscriptionScheduleModel schedule
              in orderController.schedules!) {
                schedules.add(
                    '${'day_capital'.tr} ${schedule.day} (${DateConverter.convertTimeToTime(schedule.time!)})');
              }
            } else {
              schedules.add(DateConverter.convertTimeToTime(
                  orderController.schedules![0].time!));
            }
          }

          couponDiscount = order.couponDiscountAmount;
          discount = order.restaurantDiscountAmount;
          tax = order.totalTaxAmount;
          taxIncluded = order.taxStatus;
          additionalCharge = order.additionalCharge!;
          extraPackagingCharge = order.extraPackagingAmount!;
          referrerBonusAmount = order.referrerBonusAmount!;

          for (OrderDetailsModel orderDetails
          in orderController.orderDetails!) {
            for (AddOn addOn in orderDetails.addOns!) {
              addOns = addOns + (addOn.price! * addOn.quantity!);
            }
            itemsPrice =
                itemsPrice + (orderDetails.price! * orderDetails.quantity!);

            // Accumulate delivery charges for each restaurant
            String restaurantName =
                orderDetails.foodDetails!.restaurantName ?? '';
            if (!restaurantDeliveryCharges.containsKey(restaurantName)) {
              restaurantDeliveryCharges[restaurantName] = 0;
              restaurantTotalOrders[restaurantName] = 0;
            }
            restaurantTotalOrders[restaurantName] =
                (restaurantTotalOrders[restaurantName] ?? 0) + 1;
          }

          if (order.restaurant != null) {
            if (order.restaurant!.restaurantModel == 'commission') {
              showChatPermission = true;
            } else if (order.restaurant!.restaurantSubscription != null &&
                order.restaurant!.restaurantSubscription!.chat == 1) {
              showChatPermission = true;
            } else {
              showChatPermission = false;
            }
          }
        }
        // Calculate delivery charges based on grouped restaurant orders
        double totalDeliveryCharge = order?.deliveryCharge??0;
      //  bool isFirstRestaurant = true; // To track the first restaurant
      //  restaurantDeliveryCharges.forEach((name, charge) {
      //    double deliveryCharge;
      //    if (isFirstRestaurant) {
      //      deliveryCharge = order?.deliveryCharge??15; // Charge for the first restaurant
      //      isFirstRestaurant = false; // Set to false after the first order
      //    } else {
      //      deliveryCharge = Get.find<SplashController>()
      //          .configModel!
      //          .deliveryFeeMultiVendor!
      //          .toDouble(); // Charge for subsequent restaurants
      //    }
      //    totalDeliveryCharge += deliveryCharge;
      //  });
        double subTotal = itemsPrice + addOns;
        // double total = itemsPrice +
        //     addOns -
        //     discount! +
        //     (taxIncluded! ? 0 : tax!) +
        //     totalDeliveryCharge - // Use the aggregated delivery charge here
        //     couponDiscount! +
        //     dmTips +
        //     additionalCharge +
        //     extraPackagingCharge -
        //     referrerBonusAmount;

        double total = itemsPrice +
            addOns -
            discount! +
            (taxIncluded! ? 0 : tax!) +
            totalDeliveryCharge -
            couponDiscount! +
            dmTips +
            extraPackagingCharge -
            referrerBonusAmount;

        return Scaffold(
          appBar: subscription && !ResponsiveHelper.isDesktop(context)
              ? AppBar(
            surfaceTintColor: Theme.of(context).cardColor,
            title: Column(children: [
              Text('${'subscription'.tr} # ${order?.id.toString()}',
                  style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge)),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text('${'your_order_is'.tr} ${order?.orderStatus}',
                  style: robotoRegular.copyWith(
                      color: Theme.of(context).primaryColor)),
            ]),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () {
                if ((widget.orderModel == null ||
                    widget.fromOfflinePayment) &&
                    !widget.fromGuestTrack) {
                  Get.offAllNamed(RouteHelper.getInitialRoute());
                } else if (widget.fromGuestTrack) {
                  Get.back();
                } else {
                  Get.back();
                }
              },
            ),
            actions: const [SizedBox()],
            backgroundColor: Theme.of(context).cardColor,
            elevation: 0,
          )
              : CustomAppBarWidget(
              title: subscription
                  ? 'subscription_details'.tr
                  : 'order_details'.tr,
              onBackPressed: () {
                if ((widget.orderModel == null ||
                    widget.fromOfflinePayment) &&
                    !widget.fromGuestTrack) {
                  Get.offAllNamed(RouteHelper.getInitialRoute());
                } else if (widget.fromGuestTrack) {
                  Get.back();
                } else {
                  Get.back();
                }
              }),
          endDrawer: const MenuDrawerWidget(),
          endDrawerEnableOpenDragGesture: false,
          body: SafeArea(
            child: (order != null && orderController.orderDetails != null)
                ? Column(children: [
              WebScreenTitleWidget(
                  title: subscription
                      ? 'subscription_details'.tr
                      : 'order_details'.tr),
              Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: FooterViewWidget(
                        child: SizedBox(
                          width: Dimensions.webMaxWidth,
                          child: ResponsiveHelper.isDesktop(context)
                              ? Padding(
                            padding: const EdgeInsets.only(
                                top: Dimensions.paddingSizeLarge),
                            child: Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      flex: 6,
                                      child: Column(
                                        children: [
                                          subscription
                                              ? Text(
                                              '${'subscription'.tr} # ${order.id.toString()}',
                                              style: robotoBold.copyWith(
                                                  fontSize: Dimensions
                                                      .fontSizeLarge))
                                              : const SizedBox(),
                                          SizedBox(
                                              height: subscription
                                                  ? Dimensions
                                                  .paddingSizeExtraSmall
                                                  : 0),
                                          subscription
                                              ? Text(
                                              '${'your_order_is'.tr} ${order.orderStatus}',
                                              style: robotoRegular
                                                  .copyWith(
                                                  color: Theme.of(
                                                      context)
                                                      .primaryColor))
                                              : const SizedBox(),
                                          SizedBox(
                                              height: subscription
                                                  ? Dimensions
                                                  .paddingSizeLarge
                                                  : 0),
                                          OrderInfoSection(
                                              order: order,
                                              orderController:
                                              orderController,
                                              schedules: schedules,
                                              showChatPermission:
                                              showChatPermission,
                                              contactNumber:
                                              widget.contactNumber,
                                              totalAmount: total),
                                        ],
                                      )),
                                  const SizedBox(
                                      width: Dimensions.paddingSizeLarge),
                                  Expanded(
                                      flex: 4,
                                      child: OrderPricingSection(
                                        itemsPrice: itemsPrice,
                                        addOns: addOns,
                                        order: order,
                                        subTotal: subTotal,
                                        discount: discount,
                                        couponDiscount: couponDiscount,
                                        tax: tax!,
                                        dmTips: dmTips,
                                        deliveryCharge:
                                        order.couponDiscountAmount ==
                                            0 &&
                                            order.couponCode != null
                                            ? 0
                                            : totalDeliveryCharge,
                                        total: total,
                                        orderController: orderController,
                                        orderId: widget.orderId,
                                        contactNumber: widget.contactNumber,
                                        extraPackagingAmount:
                                        extraPackagingCharge,
                                        referrerBonusAmount:
                                        referrerBonusAmount,
                                      ))
                                ]),
                          )
                              : Column(children: [
                            OrderInfoSection(
                                order: order,
                                orderController: orderController,
                                schedules: schedules,
                                showChatPermission: showChatPermission,
                                contactNumber: widget.contactNumber,
                                totalAmount: total),
                            OrderPricingSection(
                              itemsPrice: itemsPrice,
                              addOns: addOns,
                              order: order,
                              subTotal: subTotal,
                              discount: discount,
                              couponDiscount: couponDiscount,
                              tax: tax!,
                              dmTips: dmTips,
                              deliveryCharge:
                              order.couponDiscountAmount == 0 &&
                                  order.couponCode != null
                                  ? 0
                                  : totalDeliveryCharge,
                              total: order.orderAmount!,
                              orderController: orderController,
                              orderId: widget.orderId,
                              contactNumber: widget.contactNumber,
                              extraPackagingAmount: extraPackagingCharge,
                              referrerBonusAmount: referrerBonusAmount,
                            ),
                          ]),
                        )),
                  )),
              !ResponsiveHelper.isDesktop(context)
                  ? BottomViewWidget(
                  orderController: orderController,
                  order: order,
                  orderId: widget.orderId,
                  total: total,
                  contactNumber: widget.contactNumber)
                  : const SizedBox(),
            ])
                : const Center(child: CircularProgressIndicator()),
          ),
        );
      }),
    );
  }
}