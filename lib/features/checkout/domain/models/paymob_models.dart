enum IntegrationType { onlineCard, mobileWallet }

extension IntegrationTypeExtension on IntegrationType {
  String get name {
    switch (this) {
      case IntegrationType.onlineCard:
        return "online_card";
      case IntegrationType.mobileWallet:
        return "mobile_wallet";
    }
  }
}

class PaymobCheckoutRequest {
  double amount;
  List<int> cartIDs;
  IntegrationType integrationType;

  PaymobCheckoutRequest({
    required this.amount,
    required this.cartIDs,
    required this.integrationType,
  });

  String get query =>
      "?amount=${amount.toStringAsFixed(2)}&cart_ids=${cartIDs.join(",")}&integration_type=${integrationType.name}";
}

class PaymobSuccessResponse {
  String? url;
  String? id;

  PaymobSuccessResponse({this.url, this.id});

  factory PaymobSuccessResponse.fromJson(Map<String, dynamic> json) {
    return PaymobSuccessResponse(
      url: json['checkout_url'],
      id: json['payment_id'],
    );
  }
}

class PaymobErrorResponse {
  String? error;
  List<String>? _details;

  String? get details => _details?.join(", ");

  PaymobErrorResponse({this.error, List<String>? details}) : _details = details;

  PaymobErrorResponse.fromJson(Map<String, dynamic> json) {
    if (json['message'] is String) {
      // our backend error
      error = json['message'];
      _details = [error.toString()];
    } else {
      error = json['error'];
      _details = [];
      if (json['details'] is Map) {
        for (var val in (json['details'] as Map).values) {
          if (val is List) {
            val.forEach((element) => _details?.add(element.toString()));
          } else {
            _details?.add(val.toString());
          }
        }
      }
    }
  }
}
