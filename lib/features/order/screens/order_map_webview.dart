import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OrderMapWebViewScreen extends StatelessWidget {
  final String url;

  const OrderMapWebViewScreen({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: WebViewWidget(controller: WebViewController()..loadRequest(Uri.parse(url))),
    );
  }
}