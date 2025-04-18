import 'package:flutter/material.dart';
import 'package:gazzer_userapp/common/widgets/custom_app_bar_widget.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OrderMapWebViewScreen extends StatelessWidget {
  final String url;
  final String orderID;

  const OrderMapWebViewScreen({
    Key? key,
    required this.url,
    required this.orderID,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));

    return Scaffold(
      appBar: CustomAppBarWidget(
        title: '${'order'.tr} #$orderID',
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
