import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:gazzer_userapp/api/api_checker.dart';
import 'package:gazzer_userapp/common/models/online_cart_model.dart';
import 'package:gazzer_userapp/common/models/product_model.dart';
import 'package:gazzer_userapp/common/widgets/cart_snackbar_widget.dart';
import 'package:gazzer_userapp/common/widgets/custom_snackbar_widget.dart';
import 'package:gazzer_userapp/features/cart/domain/models/cart_model.dart';
import 'package:gazzer_userapp/features/cart/domain/services/cart_service_interface.dart';
import 'package:gazzer_userapp/features/checkout/domain/models/place_order_body_model.dart';
import 'package:gazzer_userapp/features/product/controllers/product_controller.dart';
import 'package:gazzer_userapp/features/restaurant/controllers/restaurant_controller.dart';
import 'package:gazzer_userapp/helper/auth_helper.dart';
import 'package:gazzer_userapp/helper/date_converter.dart';
import 'package:gazzer_userapp/helper/price_converter.dart';

class CartController extends GetxController implements GetxService {
  final CartServiceInterface cartServiceInterface;

  CartController({required this.cartServiceInterface});

  List<CartModel> _cartList = [];

  List<CartModel> get cartList => _cartList;

  double _subTotal = 0;

  double get subTotal => _subTotal;

  double _itemPrice = 0;

  double get itemPrice => _itemPrice;

  double _itemDiscountPrice = 0;

  double get itemDiscountPrice => _itemDiscountPrice;

  double _addOnsPrice = 0;

  double get addOns => _addOnsPrice;

  List<List<AddOns>> _addOnsList = [];

  List<List<AddOns>> get addOnsList => _addOnsList;

  List<bool> _availableList = [];

  List<bool> get availableList => _availableList;

  bool _addCutlery = false;

  bool get addCutlery => _addCutlery;

  int _notAvailableIndex = -1;

  int get notAvailableIndex => _notAvailableIndex;

  List<String> notAvailableList = [
    'Remove it from my cart',
    'I will wait until its restocked',
    'Please cancel the order',
    'Call me ASAP',
    'Notify me when its back'
  ];

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  bool _isClearCartLoading = false;

  bool get isClearCartLoading => _isClearCartLoading;
  
  bool _isCartLoading = false;

  bool get isCartLoading => _isCartLoading;

  double _variationPrice = 0;

  double get variationPrice => _variationPrice;

  bool _needExtraPackage = true;

  bool get needExtraPackage => _needExtraPackage;

  void toggleExtraPackage({bool willUpdate = true}) {
    _needExtraPackage = !_needExtraPackage;
    if (willUpdate) {
      update();
    }
  }

  double calculationCart() {
    _itemPrice = 0;
    _itemDiscountPrice = 0;
    _subTotal = 0;
    _addOnsPrice = 0;
    _availableList = [];
    _addOnsList = [];
    _variationPrice = 0;
    double variationWithoutDiscountPrice = 0;
    double variationPrice = 0;
    for (var cartModel in _cartList) {
      variationWithoutDiscountPrice = 0;
      variationPrice = 0;

      double? discount = cartModel.product!.restaurantDiscount == 0
          ? cartModel.product!.discount
          : cartModel.product!.restaurantDiscount;
      String? discountType = cartModel.product!.restaurantDiscount == 0
          ? cartModel.product!.discountType
          : 'percent';

      List<AddOns> addOnList = cartServiceInterface.prepareAddonList(cartModel);

      _addOnsList.add(addOnList);
      _availableList.add(DateConverter.isAvailable(
          cartModel.product!.availableTimeStarts,
          cartModel.product!.availableTimeEnds));

      _addOnsPrice = cartServiceInterface.calculateAddonsPrice(
          addOnList, _addOnsPrice, cartModel);

      variationWithoutDiscountPrice =
          cartServiceInterface.calculateVariationWithoutDiscountPrice(
              cartModel, variationWithoutDiscountPrice, discount, discountType);
      variationPrice = cartServiceInterface.calculateVariationPrice(
          cartModel, variationPrice);

      double price = (cartModel.price! * cartModel.quantity!);
      double discountPrice = (price -
          (PriceConverter.convertWithDiscount(
                  cartModel.price!, discount, discountType)! *
              cartModel.quantity!));

      _variationPrice += variationPrice;
      _itemPrice = _itemPrice + price;
      _itemDiscountPrice = _itemDiscountPrice +
          discountPrice +
          (variationPrice - variationWithoutDiscountPrice);

      debugPrint(
          '==check : ${_cartList.indexOf(cartModel)} ====> $_itemDiscountPrice = $_itemDiscountPrice + $discountPrice + ($variationPrice - $variationWithoutDiscountPrice)');
    }
    _subTotal =
        (_itemPrice - _itemDiscountPrice) + _addOnsPrice + _variationPrice;

    if (Get.find<RestaurantController>().restaurant != null &&
        Get.find<RestaurantController>().restaurant!.discount != null) {
      if (Get.find<RestaurantController>().restaurant!.discount!.maxDiscount !=
              0 &&
          Get.find<RestaurantController>().restaurant!.discount!.maxDiscount! <
              _itemDiscountPrice) {
        _itemDiscountPrice =
            Get.find<RestaurantController>().restaurant!.discount!.maxDiscount!;
      }
      if (Get.find<RestaurantController>().restaurant!.discount!.minPurchase !=
              0 &&
          Get.find<RestaurantController>().restaurant!.discount!.minPurchase! >
              _subTotal) {
        _itemDiscountPrice = 0;
      }
    }
    return _subTotal;
  }

  Future<int?> reorderAddToCart(List<OnlineCart> cartList) async {
    await clearCartList();
    return _addMultipleCartItemOnline(cartList);
  }

  void setQuantity(bool isIncrement, CartModel cart, {int? cartIndex}) {
    int index = cartIndex ?? _cartList.indexOf(cart);
    _cartList[index].quantity = cartServiceInterface.decideProductQuantity(
        _cartList, isIncrement, index);
    cartServiceInterface.addToSharedPrefCartList(_cartList);

    calculationCart();
    updateCartQuantityOnline(_cartList[index].id!, _cartList[index].price!,
        _cartList[index].quantity!);
    update();
  }

  void removeFromCart(int index) {
    // تأكد من وجود عناصر في القائمة
    if (_cartList.isEmpty) {
      print('Cannot remove from an empty cart');
      return;
    }

    // تأكد من صحة الإندكس
    if (index < 0 || index >= _cartList.length) {
      print('Invalid cart index: $index. Cart list length: ${_cartList.length}');
      return;
    }

    try {
      // احصل على معرف العنصر قبل الإزالة
      int cartId = _cartList[index].id!;
      
      // إزالة العنصر من القائمة المحلية
      _cartList.removeAt(index);
      
      // تحديث واجهة المستخدم
      update();
      
      // إزالة العنصر من الخادم
      removeCartItemOnline(cartId);
    } catch (e) {
      print('Unexpected error in removeFromCart: $e');
    }
  }

  Future<bool> removeFromCartOnline(int index) async {
    int cartId = _cartList[index].id!;
    return await removeCartItemOnline(cartId);
  }

Future<bool> removeRestaurantItemsOnline(int restaurantId) async {
  _isCartLoading = true;
  update();
  
  bool success = true;
  
  try {
    // Find cart items ONLY from this specific restaurant
    List<int> cartIds = _cartList
        .where((cart) => cart.product!.restaurantId == restaurantId)
        .map((cart) => cart.id!)
        .toList();
    
    // إزالة العناصر من هذا المطعم فقط
    for (int cartId in cartIds) {
      bool result = await removeCartItemOnline(cartId);
      if (!result) {
        success = false;
      }
    }
    
    // إعادة تحميل بيانات السلة للتأكد
    await getCartDataOnline();
  } catch (e) {
    print('Error removing restaurant items: $e');
    success = false;
  } finally {
    _isCartLoading = false;
    update();
  }
  
  return success;
}
  void removeAddOn(int index, int addOnIndex) {
    _cartList[index].addOnIds!.removeAt(addOnIndex);
    cartServiceInterface.addToSharedPrefCartList(_cartList);
    calculationCart();
    update();
  }

  Future<void> clearCartList() async {
    _cartList = [];
    if (AuthHelper.isLoggedIn() || AuthHelper.isGuestLoggedIn()) {
      await clearCartOnline();
    }
  }

  int isExistInCart(int? productID, int? cartIndex) {
    return cartServiceInterface.isExistInCart(productID, cartIndex, _cartList);
  }

  bool existAnotherRestaurantProduct(int? restaurantID) {
    return cartServiceInterface.existAnotherRestaurantProduct(
        restaurantID, _cartList);
  }

  void updateCutlery({bool isUpdate = true}) {
    _addCutlery = !_addCutlery;
    if (isUpdate) {
      update();
    }
  }

  void setAvailableIndex(int index, {bool isUpdate = true}) {
    _notAvailableIndex =
        cartServiceInterface.setAvailableIndex(index, _notAvailableIndex);
    if (isUpdate) {
      update();
    }
  }

  int cartQuantity(int productID) {
    return cartServiceInterface.cartQuantity(productID, _cartList);
  }

  Future<void> addToCartOnline(OnlineCart onlineCart,
      {CartModel? existCartData, bool fromDirectlyAdd = false}) async {
    _isLoading = true;
    update();
    Response response = await cartServiceInterface.addToCartOnline(
        onlineCart, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId());

    if (response.statusCode == 200) {
      List<OnlineCartModel> onlineCartList = [];
      response.body.forEach(
          (cart) => onlineCartList.add(OnlineCartModel.fromJson(cart)));
      _cartList = [];
      _cartList.addAll(cartServiceInterface.formatOnlineCartToLocalCart(
          onlineCartModel: onlineCartList));
      calculationCart();
      if (!fromDirectlyAdd) {
        Get.back();
      }
      showCartSnackBarWidget();
    } else if (response.statusCode == 403) {
      showCustomSnackBar(response.body['errors'][0]['message'],
          showToaster: true);
      Get.find<ProductController>()
          .getProductDetails(onlineCart.itemId!, existCartData);
    } else {
      ApiChecker.checkApi(response);
    }

    _isLoading = false;
    update();
  }

  Future<int?> _addMultipleCartItemOnline(List<OnlineCart> cartList) async {
    _isLoading = true;
    update();
    Response response =
        await cartServiceInterface.addMultipleCartItemOnline(cartList);
    if (response.statusCode == 200) {
      List<OnlineCartModel> onlineCartList = [];
      response.body.forEach(
          (cart) => onlineCartList.add(OnlineCartModel.fromJson(cart)));
      _cartList = [];
      _cartList.addAll(cartServiceInterface.formatOnlineCartToLocalCart(
          onlineCartModel: onlineCartList));
      calculationCart();
    }
    _isLoading = false;
    update();
    return response.statusCode;
  }

  Future<void> updateCartOnline(OnlineCart onlineCart,
      {CartModel? existCartData}) async {
    _isLoading = true;
    update();
    Response response = await cartServiceInterface.updateCartOnline(onlineCart,
        AuthHelper.isLoggedIn() ? null : int.parse(AuthHelper.getGuestId()));
    if (response.statusCode == 200) {
      List<OnlineCartModel> onlineCartList = [];
      response.body.forEach(
          (cart) => onlineCartList.add(OnlineCartModel.fromJson(cart)));
      _cartList = [];
      _cartList.addAll(cartServiceInterface.formatOnlineCartToLocalCart(
          onlineCartModel: onlineCartList));
      calculationCart();
      Get.back();
      showCartSnackBarWidget();
    } else if (response.statusCode == 403 &&
        response.body['errors'][0]['code'] == 'stock_out') {
      showCustomSnackBar(response.body['errors'][0]['message'],
          showToaster: true);
      Get.find<ProductController>()
          .getProductDetails(onlineCart.itemId!, existCartData);
    } else {
      ApiChecker.checkApi(response);
    }
    _isLoading = false;
    update();
  }

  Future<void> updateCartQuantityOnline(
      int cartId, double price, int quantity) async {
    _isLoading = true;
    update();
    bool success = await cartServiceInterface.updateCartQuantityOnline(
        cartId,
        price,
        quantity,
        AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId());
    if (success) {
      getCartDataOnline();
      calculationCart();
    }
    _isLoading = false;
    update();
  }

  Future<void> getCartDataOnline() async {
    _isLoading = true;
    List<OnlineCartModel> onlineCartList =
        await cartServiceInterface.getCartDataOnline(
            AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId());
    _cartList = [];
    _cartList.addAll(cartServiceInterface.formatOnlineCartToLocalCart(
        onlineCartModel: onlineCartList));
    calculationCart();
    _isLoading = false;
    update();
  }

  Future<bool> removeCartItemOnline(int cartId) async {
    _isLoading = true;
    update();
    
    try {
      bool isSuccess = await cartServiceInterface.removeCartItemOnline(
          cartId, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId());
      
      // إعادة تحميل بيانات السلة بالكامل
      await getCartDataOnline();
      
      return isSuccess;
    } catch (e) {
      print('Error removing cart item online: $e');
      
      // محاولة إعادة تحميل بيانات السلة حتى في حالة الفشل
      await getCartDataOnline();
      
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<bool> clearCartOnline() async {
    _isLoading = true;
    _isClearCartLoading = true;
    update();
    bool success = await cartServiceInterface.clearCartOnline(
        AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId());
    if (success) {
      getCartDataOnline();
    }
    _isLoading = false;
    _isClearCartLoading = false;
    update();
    return success;
  }
}