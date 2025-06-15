import 'package:gazzer_userapp/features/cart/controllers/cart_controller.dart';

extension CartControllerExtension on CartController {
  double calculateTotalPrice() {
    final subTotal =
        cartList.fold(0.0, (sum, item) => (sum) + (((itemPrice + variationPrice + addOns) / cartList.length)));
    return subTotal;
  }
}
