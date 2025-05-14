part of 'checkout_controller.dart';

extension CheckoutControllerExtra on CheckoutController {
  double calculateTotalAmount(List<CartModel>? cartList) {
    // Group cart items by restaurant
    Map<String, List<CartModel>> restaurantGroupedCartList = {};

    for (var cartItem in cartList!) {
      String restaurantName = cartItem.product!.restaurantName!;
      if (!restaurantGroupedCartList.containsKey(restaurantName)) {
        restaurantGroupedCartList[restaurantName] = [];
      }
      restaurantGroupedCartList[restaurantName]!.add(cartItem);
    }

    // Calculate total without extra fees for same restaurant
    double totalAmount = 0.0;

    for (var entries in restaurantGroupedCartList.entries) {
      List<CartModel> items = entries.value;
      double restaurantTotalPrice = calculatePrice(items);
      double restaurantTotalAddOns = calculateAddonsPrice(items);

      double restaurantTotal = calculateSubTotal(restaurantTotalPrice, restaurantTotalAddOns);
      totalAmount += restaurantTotal;
    }

    // Add base delivery charge and any additional charges
    double additionalDeliveryFee = (restaurantGroupedCartList.length - 1) *
        Get.find<SplashController>().configModel!.deliveryFeeMultiVendor!.toDouble(); // Convert to double

    totalAmount += 15 + additionalDeliveryFee;

    return totalAmount;
  }

  double? getDeliveryCharge(
      {required Restaurant? restaurant,
      required CheckoutController checkoutController,
      bool returnDeliveryCharge = true,
      bool returnMaxCodOrderAmount = false}) {
    ZoneData zoneData =
        AddressHelper.getAddressFromSharedPref()!.zoneData!.firstWhere((data) => data.id == restaurant!.zoneId);
    double perKmCharge =
        restaurant!.selfDeliverySystem == 1 ? restaurant.perKmShippingCharge! : zoneData.perKmShippingCharge ?? 0;

    double minimumCharge =
        restaurant.selfDeliverySystem == 1 ? restaurant.minimumShippingCharge! : zoneData.minimumShippingCharge ?? 0;

    double? maximumCharge =
        restaurant.selfDeliverySystem == 1 ? restaurant.maximumShippingCharge : zoneData.maximumShippingCharge;

    double deliveryCharge = checkoutController.distance! * perKmCharge;
    double charge = checkoutController.distance! * perKmCharge;

    if (deliveryCharge < minimumCharge) {
      deliveryCharge = minimumCharge;
      charge = minimumCharge;
    }

    if (restaurant.selfDeliverySystem == 0 && checkoutController.extraCharge != null) {
      deliveryCharge = deliveryCharge + checkoutController.extraCharge!;
      charge = charge + checkoutController.extraCharge!;
    }

    if (maximumCharge != null && deliveryCharge > maximumCharge) {
      deliveryCharge = maximumCharge;
      charge = maximumCharge;
    }

    if (restaurant.selfDeliverySystem == 0 && zoneData.increasedDeliveryFeeStatus == 1) {
      deliveryCharge = deliveryCharge + (deliveryCharge * (zoneData.increasedDeliveryFee! / 100));
      charge = charge + charge * (zoneData.increasedDeliveryFee! / 100);
    }

    if (restaurant.selfDeliverySystem == 0 &&
        Get.find<SplashController>().configModel!.freeDeliveryDistance != null &&
        Get.find<SplashController>().configModel!.freeDeliveryDistance! >= checkoutController.distance!) {
      deliveryCharge = 0;
      charge = 0;
    }

    if (restaurant.selfDeliverySystem == 1 &&
        restaurant.freeDeliveryDistanceStatus! &&
        restaurant.freeDeliveryDistanceValue! >= checkoutController.distance!) {
      deliveryCharge = 0;
      charge = 0;
    }

    double? maxCodOrderAmount;
    if (zoneData.maxCodOrderAmount != null) {
      maxCodOrderAmount = zoneData.maxCodOrderAmount;
    }

    if (returnMaxCodOrderAmount) {
      return maxCodOrderAmount;
    } else {
      if (returnDeliveryCharge) {
        return deliveryCharge;
      } else {
        return charge;
      }
    }
  }

  double calculatePrice(List<CartModel>? cartList) {
    double price = 0;
    double variationPrice = 0;

    for (var cartModel in cartList!) {
      price += (cartModel.price! * cartModel.quantity!);

      // Calculate variation price
      for (int index = 0; index < cartModel.product!.variations!.length; index++) {
        for (int i = 0; i < cartModel.product!.variations![index].variationValues!.length; i++) {
          if (cartModel.variations![index][i]!) {
            variationPrice +=
                (cartModel.product!.variations![index].variationValues![i].optionPrice! * cartModel.quantity!);
          }
        }
      }
    }

    return PriceConverter.toFixed(price + variationPrice);
  }

  double calculateAddonsPrice(List<CartModel>? cartList) {
    double addonPrice = 0;

    for (var cartModel in cartList!) {
      List<AddOns> addOnList = [];

      for (var addOnId in cartModel.addOnIds!) {
        for (AddOns addOns in cartModel.product!.addOns!) {
          if (addOns.id == addOnId.id) {
            addOnList.add(addOns);
            break;
          }
        }
      }

      for (int index = 0; index < addOnList.length; index++) {
        addonPrice += (addOnList[index].price! * cartModel.addOnIds![index].quantity!);
      }
    }

    return PriceConverter.toFixed(addonPrice);
  }

  double calculateDiscountPrice(List<CartModel>? cartList, Restaurant? restaurant, double price, double addOns) {
    double? discount = 0;
    if (restaurant != null) {
      for (var cartModel in cartList!) {
        double? dis = (restaurant.discount != null &&
                DateConverter.isAvailable(restaurant.discount!.startTime, restaurant.discount!.endTime))
            ? restaurant.discount!.discount
            : cartModel.product!.discount;
        String? disType = (restaurant.discount != null &&
                DateConverter.isAvailable(restaurant.discount!.startTime, restaurant.discount!.endTime))
            ? 'percent'
            : cartModel.product!.discountType;

        double d = ((cartModel.product!.price! -
                PriceConverter.convertWithDiscount(cartModel.product!.price!, dis, disType)!) *
            cartModel.quantity!);
        discount = discount! + d;
        discount = discount + calculateVariationPrice(restaurant: restaurant, cartModel: cartModel);
      }

      if (restaurant.discount != null) {
        if (restaurant.discount!.maxDiscount != 0 && restaurant.discount!.maxDiscount! < discount!) {
          discount = restaurant.discount!.maxDiscount;
        }
        if (restaurant.discount!.minPurchase != 0 && restaurant.discount!.minPurchase! > (price + addOns)) {
          discount = 0;
        }
      }
    }
    return PriceConverter.toFixed(discount!);
  }

  double calculateVariationPrice({required Restaurant? restaurant, required CartModel? cartModel}) {
    double variationPrice = 0;
    double variationDiscount = 0;
    if (restaurant != null && cartModel != null) {
      double? discount = (restaurant.discount != null &&
              DateConverter.isAvailable(restaurant.discount!.startTime, restaurant.discount!.endTime))
          ? restaurant.discount!.discount
          : cartModel.product!.discount;
      String? discountType = (restaurant.discount != null &&
              DateConverter.isAvailable(restaurant.discount!.startTime, restaurant.discount!.endTime))
          ? 'percent'
          : cartModel.product!.discountType;

      for (int index = 0; index < cartModel.product!.variations!.length; index++) {
        for (int i = 0; i < cartModel.product!.variations![index].variationValues!.length; i++) {
          if (cartModel.variations![index][i]!) {
            variationPrice += (PriceConverter.convertWithDiscount(
                    cartModel.product!.variations![index].variationValues![i].optionPrice!, discount, discountType,
                    isVariation: true)! *
                cartModel.quantity!);
            variationDiscount +=
                (cartModel.product!.variations![index].variationValues![i].optionPrice! * cartModel.quantity!);
          }
        }
      }
    }

    return variationDiscount - variationPrice;
  }

  double calculateSubTotal(double price, double addOnsPrice) {
    double subTotal = price + addOnsPrice;
    return PriceConverter.toFixed(subTotal);
  }

  double calculateOrderAmount(
      double price, double addOnsPrice, double discount, double couponDiscount, double referralDiscount) {
    double orderAmount = (price - discount) + addOnsPrice - couponDiscount - referralDiscount;
    return PriceConverter.toFixed(orderAmount);
  }

  double calculateTax(bool taxIncluded, double orderAmount, double? taxPercent) {
    double tax = 0;
    if (taxIncluded) {
      tax = orderAmount * taxPercent! / (100 + taxPercent);
    } else {
      tax = PriceConverter.calculation(orderAmount, taxPercent, 'percent', 1);
    }
    return PriceConverter.toFixed(tax);
  }

  int getSubscriptionQty({required CheckoutController checkoutController, required bool restaurantSubscriptionActive}) {
    int subscriptionQty = checkoutController.subscriptionOrder ? 0 : 1;
    if (restaurantSubscriptionActive) {
      if (checkoutController.subscriptionOrder && checkoutController.subscriptionRange != null) {
        if (checkoutController.subscriptionType == 'weekly') {
          List<int> weekDays = [];
          for (int index = 0; index < checkoutController.selectedDays.length; index++) {
            if (checkoutController.selectedDays[index] != null) {
              weekDays.add(index + 1);
            }
          }
          subscriptionQty = DateConverter.getWeekDaysCount(checkoutController.subscriptionRange!, weekDays);
        } else if (checkoutController.subscriptionType == 'monthly') {
          List<int> days = [];
          for (int index = 0; index < checkoutController.selectedDays.length; index++) {
            if (checkoutController.selectedDays[index] != null) {
              days.add(index + 1);
            }
          }
          subscriptionQty = DateConverter.getMonthDaysCount(checkoutController.subscriptionRange!, days);
        } else {
          subscriptionQty = checkoutController.subscriptionRange!.duration.inDays + 1;
        }
      }
    }
    return subscriptionQty;
  }

  double calculateTotal(double subTotal, double deliveryCharge, double discount, double couponDiscount,
      bool taxIncluded, double tax, bool showTips, double tips, double additionalCharge, double extraPackagingCharge) {
    double total = subTotal +
        deliveryCharge -
        discount -
        couponDiscount +
        (taxIncluded ? 0 : tax) +
        (showTips ? tips : 0) +
        additionalCharge +
        extraPackagingCharge;

    return PriceConverter.toFixed(total);
  }

  double calculateExtraPackagingCharge() {
    if ((restaurant != null &&
            restaurant!.isExtraPackagingActive! &&
            !restaurant!.extraPackagingStatusIsMandatory! &&
            Get.find<CartController>().needExtraPackage) ||
        (restaurant != null && restaurant!.isExtraPackagingActive! && restaurant!.extraPackagingStatusIsMandatory!)) {
      return restaurant?.extraPackagingAmount ?? 0;
    }
    return 0;
  }

  double calculateReferralDiscount(double subTotal, double discount, double couponDiscount, bool isSubscriptionOrder) {
    if (kDebugMode) {
      print('=====>>>ss>>>> $subTotal, $discount, $couponDiscount');
    }
    double referralDiscount = 0;
    if (Get.find<ProfileController>().userInfoModel != null &&
        Get.find<ProfileController>().userInfoModel!.isValidForDiscount! &&
        !isSubscriptionOrder) {
      if (Get.find<ProfileController>().userInfoModel!.discountAmountType! == "percentage") {
        referralDiscount = (Get.find<ProfileController>().userInfoModel!.discountAmount! / 100) *
            (subTotal - discount - couponDiscount);
      } else {
        referralDiscount = Get.find<ProfileController>().userInfoModel!.discountAmount!;
      }
    }
    return PriceConverter.toFixed(referralDiscount);
  }

  double calculateDeliveryFees(
      ConfigModel config, List<CartModel>? cartList, double deliveryCharge, double orderAmount) {
    if ((config.freeDeliveryOver ?? 0) < orderAmount) {
      return 0;
    }
    // Group the cartList by restaurant
    Map<String, List<CartModel>> restaurantGroupedCartList = {};
    for (var cartItem in cartList ?? <CartModel>[]) {
      String restaurantName = cartItem.product!.restaurantName!;
      if (!restaurantGroupedCartList.containsKey(restaurantName)) {
        restaurantGroupedCartList[restaurantName] = [];
      }
      restaurantGroupedCartList[restaurantName]!.add(cartItem);
    }
    // Calculate delivery charge for grouped orders
    double groupedDeliveryCharge = restaurantGroupedCartList.length > 1
        ? deliveryCharge +
            (restaurantGroupedCartList.length - 1) * Get.find<SplashController>().configModel!.deliveryFeeMultiVendor!
        : deliveryCharge;

    return groupedDeliveryCharge;
  }
}
