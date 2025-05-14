import 'package:in_app_review/in_app_review.dart';

class AppReview {
  static Future<void> initReview() async {
    final InAppReview inAppReview = InAppReview.instance;
    try {
      inAppReview.openStoreListing(appStoreId: "6670802440");
    } catch (e) {
      ///
    }
  }
}
