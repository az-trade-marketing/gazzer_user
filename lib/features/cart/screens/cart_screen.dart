import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:gazzer_userapp/common/models/restaurant_model.dart';
import 'package:gazzer_userapp/common/widgets/custom_app_bar_widget.dart';
import 'package:gazzer_userapp/common/widgets/custom_snackbar_widget.dart';
import 'package:gazzer_userapp/common/widgets/footer_view_widget.dart';
import 'package:gazzer_userapp/common/widgets/menu_drawer_widget.dart';
import 'package:gazzer_userapp/common/widgets/no_data_screen_widget.dart';
import 'package:gazzer_userapp/common/widgets/web_constrained_box.dart';
import 'package:gazzer_userapp/common/widgets/web_page_title_widget.dart';
import 'package:gazzer_userapp/features/cart/controllers/cart_controller.dart';
import 'package:gazzer_userapp/features/cart/widgets/cart_product_widget.dart';
import 'package:gazzer_userapp/features/cart/widgets/checkout_button_widget.dart';
import 'package:gazzer_userapp/features/cart/widgets/pricing_view_widget.dart';
import 'package:gazzer_userapp/features/profile/controllers/profile_controller.dart';
import 'package:gazzer_userapp/features/restaurant/controllers/restaurant_controller.dart';
import 'package:gazzer_userapp/helper/price_converter.dart';
import 'package:gazzer_userapp/helper/responsive_helper.dart';
import 'package:gazzer_userapp/util/dimensions.dart';
import 'package:gazzer_userapp/util/styles.dart';
import 'package:get/get.dart';

// فئة مساعدة لتجميع معلومات المطعم والطلبات
class RestaurantCartGroup {
  final int id;
  final String name;
  bool isOpen;
  List<int> cartIndices;

  RestaurantCartGroup({
    required this.id,
    required this.name,
    required this.isOpen,
    required this.cartIndices,
  });
}

class CartScreen extends StatefulWidget {
  final bool fromNav;
  final bool fromReorder;

  const CartScreen({
    super.key, 
    required this.fromNav, 
    this.fromReorder = false
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ScrollController scrollController = ScrollController();
  
  // خريطة لتخزين معلومات المطاعم وطلباتها
  Map<int, RestaurantCartGroup> _restaurantCartGroups = {};

  // حالة التحميل لحالة المطاعم
  bool _isLoadingRestaurantStatus = true;

  @override
  void initState() {
    super.initState();
    initCall();
  }

  // دالة التهيئة الأولية
  Future<void> initCall() async {
    Get.find<RestaurantController>().makeEmptyRestaurant(willUpdate: false);
    await Get.find<CartController>().getCartDataOnline();
    
    if (Get.find<CartController>().cartList.isNotEmpty) {
      setState(() {
        _isLoadingRestaurantStatus = true;
      });
      
      await _updateRestaurantMaps();
      
      // معالجة عناصر السلة
      Get.find<CartController>().calculationCart();
      if (Get.find<CartController>().addCutlery) {
        Get.find<CartController>().updateCutlery(isUpdate: false);
      }
      if (Get.find<CartController>().needExtraPackage) {
        Get.find<CartController>().toggleExtraPackage(willUpdate: false);
      }
      Get.find<CartController>().setAvailableIndex(-1, isUpdate: false);
      
      setState(() {
        _isLoadingRestaurantStatus = false;
      });
      
      showReferAndEarnSnackBar();
    }
  }

  // تحديث خريطة المطاعم والطلبات
  Future<void> _updateRestaurantMaps() async {
    // مسح الخريطة السابقة
    _restaurantCartGroups.clear();
    
    CartController cartController = Get.find<CartController>();
    
    // تجميع عناصر السلة حسب المطعم
    for (int i = 0; i < cartController.cartList.length; i++) {
      // التأكد من صحة بيانات المنتج والمطعم
      if (cartController.cartList[i].product == null ||
          cartController.cartList[i].product?.restaurantId == null) {
        continue; // تخطي العناصر غير الصالحة
      }

      int restaurantId = cartController.cartList[i].product!.restaurantId!;

      // جلب تفاصيل المطعم إذا لم تكن موجودة
      if (!_restaurantCartGroups.containsKey(restaurantId)) {
        await Get.find<RestaurantController>().getRestaurantDetails(
          Restaurant(id: restaurantId, name: null),
          fromCart: true
        );
        
        Restaurant? restaurant = Get.find<RestaurantController>().restaurant;
        if (restaurant != null) {
          bool isOpen = Get.find<RestaurantController>().isRestaurantOpenNow(
            restaurant.active == true,
            restaurant.schedules
          );
          
          _restaurantCartGroups[restaurantId] = RestaurantCartGroup(
            id: restaurantId,
            name: restaurant.name ?? '',
            isOpen: isOpen,
            cartIndices: [i]
          );
        }
      } else {
        // إضافة فهرس العنصر للمطعم الموجود
        _restaurantCartGroups[restaurantId]!.cartIndices.add(i);
      }
      
      // جلب العناصر المقترحة للمطعم
      Get.find<RestaurantController>().getCartRestaurantSuggestedItemList(restaurantId);
    }
  }

  // التحقق مما إذا كانت جميع المطاعم مفتوحة
  bool areAllRestaurantsOpen() {
    return _restaurantCartGroups.values.every((group) => group.isOpen);
  }
  
  // إزالة عناصر مطعم بالكامل
  void removeRestaurantItems(int restaurantId, CartController cartController) async {
    setState(() {
      _isLoadingRestaurantStatus = true;
    });
    
    try {
      // استدعاء دالة المتحكم لإزالة جميع العناصر من هذا المطعم
      bool success = await cartController.removeRestaurantItemsOnline(restaurantId);
      
      if (success) {
        // تحديث خريطة المطاعم بعد الإزالة الناجحة
        await _updateRestaurantMaps();
        
        showCustomSnackBar('removed_restaurant_from_cart'.tr, isError: false);
      } else {
        showCustomSnackBar('failed_to_remove_restaurant_items'.tr, isError: true);
      }
    } catch (e) {
      print('Error removing restaurant items: $e');
      showCustomSnackBar('failed_to_remove_restaurant_items'.tr, isError: true);
    } finally {
      setState(() {
        _isLoadingRestaurantStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      appBar: CustomAppBarWidget(
          title: 'my_cart'.tr,
          isBackButtonExist: (isDesktop || !widget.fromNav)),
      endDrawer: const MenuDrawerWidget(),
      endDrawerEnableOpenDragGesture: false,
      body: GetBuilder<RestaurantController>(builder: (restaurantController) {
        return GetBuilder<CartController>(
          builder: (cartController) {
            bool allRestaurantsOpen = areAllRestaurantsOpen();
            
            bool suggestionEmpty =
                (restaurantController.suggestedItems != null &&
                    restaurantController.suggestedItems!.isEmpty);
                    
            return (cartController.isLoading && widget.fromReorder)
                ? const Center(
                    child: SizedBox(
                        height: 30,
                        width: 30,
                        child: CircularProgressIndicator()),
                  )
                : cartController.cartList.isNotEmpty
                    ? Column(
                        children: [
                          Expanded(
                            child: ExpandableBottomSheet(
                              background: Column(
                                children: [
                                  WebScreenTitleWidget(title: 'my_cart'.tr),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      controller: scrollController,
                                      padding: isDesktop
                                          ? const EdgeInsets.only(
                                              top: Dimensions.paddingSizeSmall)
                                          : EdgeInsets.zero,
                                      child: FooterViewWidget(
                                        child: Center(
                                          child: SizedBox(
                                            width: Dimensions.webMaxWidth,
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Expanded(
                                                          flex: 6,
                                                          child: Column(
                                                              children: [
                                                                Container(
                                                                  decoration: isDesktop
                                                                      ? BoxDecoration(
                                                                          borderRadius: const BorderRadius
                                                                              .all(
                                                                              Radius.circular(Dimensions.radiusDefault)),
                                                                          color:
                                                                              Theme.of(context).cardColor,
                                                                          boxShadow: [
                                                                            BoxShadow(
                                                                                color: Colors.grey.withOpacity(0.1),
                                                                                spreadRadius: 1,
                                                                                blurRadius: 10,
                                                                                offset: const Offset(0, 1))
                                                                          ],
                                                                        )
                                                                      : const BoxDecoration(),
                                                                  child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        WebConstrainedBox(
                                                                          dataLength: cartController
                                                                              .cartList
                                                                              .length,
                                                                          minLength:
                                                                              5,
                                                                          minHeight: suggestionEmpty
                                                                              ? 0.6
                                                                              : 0.3,
                                                                          child: _isLoadingRestaurantStatus
                                                                              ? Center(
                                                                                  child: Padding(
                                                                                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                                                                                    child: Column(
                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                      children: [
                                                                                        const CircularProgressIndicator(),
                                                                                        const SizedBox(height: Dimensions.paddingSizeSmall),
                                                                                        Text(
                                                                                          'checking_restaurant_status'.tr,
                                                                                          style: robotoRegular.copyWith(
                                                                                            color: Theme.of(context).disabledColor,
                                                                                            fontSize: Dimensions.fontSizeSmall,
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                )
                                                                              : Column(
                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    // رسالة التحذير إذا كان أي مطعم مغلق
                                                                                    !allRestaurantsOpen && _restaurantCartGroups.isNotEmpty
                                                                                        ? Container(
                                                                                            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                                                                            margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                                                                                            decoration: BoxDecoration(
                                                                                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                                                                                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                                                                            ),
                                                                                            child: Center(
                                                                                              child: Text(
                                                                                                'restaurant_is_closed'.tr,
                                                                                                style: robotoRegular.copyWith(
                                                                                                  color: Theme.of(context).colorScheme.error,
                                                                                                  fontSize: Dimensions.fontSizeSmall,
                                                                                                ),
                                                                                                textAlign: TextAlign.center,
                                                                                              ),
                                                                                            ),
                                                                                          )
                                                                                        : const SizedBox(),
                                                                                    
                                                                                    // تجميع عناصر السلة حسب المطعم
                                                                                    ..._restaurantCartGroups.values.map((restaurantGroup) {
                                                                                      return Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        children: [
                                                                                          // عنوان المطعم مع حالته وزر الإزالة
                                                                                          Container(
                                                                                            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                                                                            margin: const EdgeInsets.only(bottom: 4.0),
                                                                                            decoration: BoxDecoration(
                                                                                              color: Theme.of(context).cardColor,
                                                                                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                                                                              boxShadow: [
                                                                                                BoxShadow(
                                                                                                  color: Colors.grey.withOpacity(0.1),
                                                                                                  spreadRadius: 1,
                                                                                                  blurRadius: 3,
                                                                                                  offset: const Offset(0, 1),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                            child: Row(
                                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                              children: [
                                                                                              
                                                                                                // زر إزالة المطعم
                                                                                                if (!restaurantGroup.isOpen)
                                                                                                  InkWell(
                                                                                                    onTap: !cartController.isCartLoading ? () {
                                                                                                      removeRestaurantItems(restaurantGroup.id, cartController);
                                                                                                    } : null,
                                                                                                    child: Container(
                                                                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                                                                      decoration: BoxDecoration(
                                                                                                      
                                                                                                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                                                                                      ),
                                                                                                      child: !cartController.isCartLoading
                                                                                                          ? Container(
                                                                                                            
                                                                                                            child: Row(
                                                                                                                mainAxisSize: MainAxisSize.min,
                                                                                                                children: [
                                                                                                                  Icon(
                                                                                                                    Icons.delete_outline,
                                                                                                                    color: Theme.of(context).colorScheme.error,
                                                                                                                    size: 18,
                                                                                                                  ),
                                                                                                                  const SizedBox(width: 4),
                                                                                                                  Text(
                                                                                                                    'remove'.tr,
                                                                                                                    style: robotoMedium.copyWith(
                                                                                                                      color: Theme.of(context).colorScheme.error,
                                                                                                                      fontSize: Dimensions.fontSizeSmall,
                                                                                                                    ),
                                                                                                                  ),
                                                                                                                ],
                                                                                                              ),
                                                                                                          )
                                                                                                          : SizedBox(
                                                                                                              height: 18,
                                                                                                              width: 18,
                                                                                                              child: CircularProgressIndicator(
                                                                                                                strokeWidth: 2,
                                                                                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                                                                                  Theme.of(context).colorScheme.error,
                                                                                                                ),
                                                                                                              ),
                                                                                                            ),
                                                                                                    ),
                                                                                                  ),
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                          
                                                                                          // عناصر السلة لهذا المطعم
                                                                                          ...restaurantGroup.cartIndices
                                                                                            .where((index) => 
                                                                                              index >= 0 && index < cartController.cartList.length
                                                                                            )
                                                                                            .map((index) {
                                                                                              return Opacity(
                                                                                                opacity: restaurantGroup.isOpen ? 1.0 : 0.6,
                                                                                                child: CartProductWidget(
                                                                                                  cart: cartController.cartList[index],
                                                                                                  cartIndex: index,
                                                                                                  addOns: index < cartController.addOnsList.length 
                                                                                                    ? cartController.addOnsList[index] 
                                                                                                    : [],
                                                                                                  isAvailable: index < cartController.availableList.length 
                                                                                                    ? cartController.availableList[index] 
                                                                                                    : false,
                                                                                                  isRestaurantOpen: restaurantGroup.isOpen,
                                                                                                ),
                                                                                              );
                                                                                            }).toList(),
                                                                                          
                                                                                         
                                                                                        ],
                                                                                      );
                                                                                    }).toList(),

                                                                                    SizedBox(height: isDesktop ? 40 : 0),
                                                                                  ]),
                                                                        ),
                                                                        // عرض التسعير للعرض المحمول
                                                                        !isDesktop && !_isLoadingRestaurantStatus
                                                                            ? PricingViewWidget(
                                                                                cartController: cartController,
                                                                                isRestaurantOpen: allRestaurantsOpen,
                                                                                restaurantOpenStatusMap: _restaurantCartGroups.map((key, value) => 
                                                                                  MapEntry(key, value.isOpen)
                                                                                ),
                                                                              )
                                                                            : const SizedBox(),
                                                                      ]),
                                                                ),
                                                              ]),
                                                        ),
                                                        SizedBox(
                                                            width: isDesktop
                                                                ? Dimensions
                                                                    .paddingSizeLarge
                                                                : 0),
                                                        // عرض التسعير للعرض المكتبي
                                                        isDesktop && !_isLoadingRestaurantStatus
                                                            ? Expanded(
                                                                flex: 4,
                                                                child: PricingViewWidget(
                                                                  cartController: cartController,
                                                                  isRestaurantOpen: allRestaurantsOpen,
                                                                  restaurantOpenStatusMap: _restaurantCartGroups.map((key, value) => 
                                                                    MapEntry(key, value.isOpen)
                                                                  ),
                                                                ))
                                                            : const SizedBox(),
                                                      ]),
                                                ]),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              persistentContentHeight: isDesktop ? 0 : 25,
                              expandableContent: isDesktop || _isLoadingRestaurantStatus
                                  ? const SizedBox()
                                  : Container(
                                      width: context.width,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(
                                                Dimensions.radiusDefault),
                                            topRight: Radius.circular(
                                                Dimensions.radiusDefault)),
                                      ),
                                      child: Column(children: [
                                        Container(
                                          width: context.width,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .disabledColor
                                                .withOpacity(0.5),
                                            borderRadius: const BorderRadius
                                                .only(
                                                topLeft: Radius.circular(
                                                    Dimensions.radiusDefault),
                                                topRight: Radius.circular(
                                                    Dimensions.radiusDefault)),
                                          ),
                                          child: Icon(Icons.drag_handle,
                                              color: Theme.of(context)
                                                  .disabledColor,
                                              size: 25),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.only(
                                            left: Dimensions.paddingSizeDefault,
                                            right:
                                                Dimensions.paddingSizeDefault,
                                            top: Dimensions.paddingSizeSmall,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                            borderRadius: const BorderRadius
                                                .only(
                                                topLeft: Radius.circular(
                                                    Dimensions.radiusDefault),
                                                topRight: Radius.circular(
                                                    Dimensions.radiusDefault)),
                                          ),
                                          child: Column(children: [
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text('item_price'.tr,
                                                      style: robotoRegular),
                                                  PriceConverter
                                                      .convertAnimationPrice(
                                                          cartController
                                                              .itemPrice,
                                                          textStyle:
                                                              robotoRegular),
                                                ]),
                                            SizedBox(
                                                height: cartController
                                                            .variationPrice >
                                                        0
                                                    ? Dimensions
                                                        .paddingSizeSmall
                                                    : 0),
                                            cartController.variationPrice > 0 ||
                                                    cartController.addOns > 0
                                                ? Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text('variations'.tr,
                                                          style: robotoRegular),
                                                      Text(
                                                          '(+) ${PriceConverter.convertPrice(cartController.variationPrice + cartController.addOns)}',
                                                          style: robotoRegular,
                                                          textDirection:
                                                              TextDirection
                                                                  .ltr),
                                                    ],
                                                  )
                                                : const SizedBox(),
                                            const SizedBox(
                                                height: Dimensions
                                                    .paddingSizeSmall),
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text('discount'.tr,
                                                      style: robotoRegular),
                                                  restaurantController
                                                              .restaurant !=
                                                          null
                                                      ? Row(children: [
                                                          Text('(-)',
                                                              style:
                                                                  robotoRegular),
                                                          PriceConverter
                                                              .convertAnimationPrice(
                                                                  cartController
                                                                      .itemDiscountPrice,
                                                                  textStyle:
                                                                      robotoRegular),
                                                        ])
                                                      : Text('calculating'.tr,
                                                          style: robotoRegular),
                                                ]),
                                          ]),
                                        ),
                                      ]),
                                    ),
                            ),
                          ),
                          isDesktop || _isLoadingRestaurantStatus
                              ? const SizedBox.shrink()
                              : CheckoutButtonWidget(
                                  cartController: cartController,
                                  restaurantOpenStatusMap: _restaurantCartGroups.map((key, value) => 
                                    MapEntry(key, value.isOpen)
                                  ),
                                ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: FooterViewWidget(
                            child: NoDataScreen(
                                isEmptyCart: true,
                                title: 'you_have_not_add_to_cart_yet'.tr)));
          },
        );
      }),
    );
  }

  // عرض رسالة الخصم للإحالة
  Future<void> showReferAndEarnSnackBar() async {
    String text = 'your_referral_discount_added_on_your_first_order'.tr;
    if (Get.find<ProfileController>().userInfoModel != null &&
        Get.find<ProfileController>().userInfoModel!.isValidForDiscount!) {
      showCustomSnackBar(text, isError: false);
    }
  }
}