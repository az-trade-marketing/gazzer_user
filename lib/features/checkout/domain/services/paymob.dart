import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:gazzer_userapp/features/auth/controllers/auth_controller.dart';
import 'package:gazzer_userapp/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class Paymob {
  Future<Map<String, String>?> getPaymobIntention({
    required double amount,
    required List<int> cartIDs,
  }) async {
    try {
      String url =
          "${AppConstants.baseUrl}/api/v1/customer/paymob/intention?amount=${amount.toStringAsFixed(2)}&cart_ids=${cartIDs.join(",")}";
      debugPrint("url:::: $url");
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer ${Get.find<AuthController>().getUserToken()}",
          "Content-Type": "application/json",
        },
      );

      final List<dynamic> data = jsonDecode(response.body);
      if (data[0] is Map && data[0].containsKey('checkout_url')) {
        if (data.isNotEmpty) {
          String checkoutUrl = data[0]['checkout_url'];
          String paymentId = data[0]['payment_id'];
          debugPrint("checkout_url: $checkoutUrl");
          debugPrint("payment_id: $paymentId");
          return {
            'checkout_url': checkoutUrl,
            'payment_id': paymentId,
          };
        }
      } else  if (data[0] is Map && data[0].containsKey('original')) {
        debugPrint('Error: ${response.statusCode} ${response.body}');
        return {"error": data[0]['original']['error']};
      }
    } catch (e, s) {
      log('Exception: $e', stackTrace: s);
      return {"error": 'Exception: $e'};
    }

    return null; // Return null if no URL is found
  }

  Future<Map<String, String>?> checkPaymentStatus({
    required String paymentId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse("${AppConstants.baseUrl}/api/v1/customer/check-payment/$paymentId"),
        headers: {
          "Authorization": "Bearer ${Get.find<AuthController>().getUserToken()}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          String paymentStatus = data['payment_status'];
          String message = data['message'];
          debugPrint("payment_status: $paymentStatus");
          debugPrint("message: $message");
          return {
            'payment_status': paymentStatus,
            'message': message,
          };
        }
      } else {
        debugPrint('Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception: $e');
    }

    return null; // Return null if no URL is found
  }
}
