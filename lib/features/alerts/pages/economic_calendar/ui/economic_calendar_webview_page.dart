import 'package:flutter/material.dart';
import '../../../../../shared/widgets/webview/enhanced_webview.dart';

class EconomicCalendarWebViewPage extends StatelessWidget {
  const EconomicCalendarWebViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    const calendarUrl = 'https://sslecal2.investing.com?columns=exc_flags,exc_currency,exc_importance,exc_actual,exc_forecast,exc_previous&features=datepicker,timezone&countries=25,34,32,6,37,72,71,22,17,51,39,14,33,10,35,42,43,45,38,56,36,110,11,26,9,12,41,4,5,178&calType=week&timeZone=23&lang=56';

    return EnhancedWebView(
      url: calendarUrl,
      title: 'Economic Calendar',
      timeoutSeconds: 45, // Longer timeout for complex widget
      enablePullToRefresh: true,
      onLoadComplete: () {
        debugPrint('Economic Calendar loaded successfully');
      },
      onError: (error) {
        debugPrint('Economic Calendar load error: $error');
      },
    );
  }
}
