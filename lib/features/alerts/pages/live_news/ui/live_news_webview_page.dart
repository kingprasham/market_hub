import 'package:flutter/material.dart';
import '../../../../../shared/widgets/webview/enhanced_webview.dart';

class LiveNewsWebViewPage extends StatelessWidget {
  const LiveNewsWebViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EnhancedWebView(
      url: 'https://widgets.tradingeconomics.com/news?utm_source=te-section',
      title: '', // No title needed as per user request
      javascriptInjection: "document.querySelectorAll('header, footer, .te-logo-container, .te-brand, [href*=\"tradingeconomics.com\"]').forEach(e => e.style.display = 'none');",
      timeoutSeconds: 30,
      enablePullToRefresh: true,
      onLoadComplete: () {
        debugPrint('Live News loaded successfully');
      },
      onError: (error) {
        debugPrint('Live News load error: $error');
      },
    );
  }
}
