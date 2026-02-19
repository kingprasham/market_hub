import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/color_constants.dart';

/// Embedded WebView widget for fx678.com exchange data
/// Used in Future tabs to display real-time LME, COMEX, SHFE data
class FX678WebView extends StatefulWidget {
  final String exchangeCode;
  final String title;
  
  const FX678WebView({
    super.key,
    required this.exchangeCode,
    required this.title,
  });

  @override
  State<FX678WebView> createState() => _FX678WebViewState();
}

class _FX678WebViewState extends State<FX678WebView> with AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _loadProgress = 0;
  Timer? _autoRefreshTimer;

  // URL mapping for fx678.com (Chinese source, translated via JS)
  static const Map<String, String> _urlMap = {
    'LME': 'https://quote.fx678.com/exchange/LME',
    'SHFE': 'https://quote.fx678.com/exchange/SHFE',
    'COMEX': 'https://quote.fx678.com/exchange/COMEX',
    'MAINMETAL': 'https://quote.fx678.com/exchange/MAINMETAL',
  };

  String get _url => _urlMap[widget.exchangeCode] ?? 'https://quote.fx678.com/exchange/LME';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _startAutoRefresh();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      // Use Desktop User-Agent to avoid mobile menu redirect and get full data tables
      ..setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            _injectDesktopAdaptations();
            if (mounted) {
              setState(() {
                _isLoading = false;
                _loadProgress = 100;
              });
            }
          },
          onWebResourceError: (error) {
            // Only show error for main frame errors
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _hasError = true;
                _isLoading = false;
                _errorMessage = _getErrorMessage(error);
              });
            }
          },
          onProgress: (progress) {
            if (mounted) setState(() => _loadProgress = progress);
          },
          onHttpError: (error) {
            debugPrint('FX678 HTTP Error: ${error.response?.statusCode}');
          },
        ),
      )
      ..loadRequest(Uri.parse(_url));
  }

  // Inject JS/CSS to adapt Desktop site for Mobile view and Translate
  void _injectDesktopAdaptations() {
    const js = """
      // 1. Force Viewport for Mobile Scaling
      const meta = document.createElement('meta');
      meta.name = 'viewport';
      meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=yes';
      document.getElementsByTagName('head')[0].appendChild(meta);

      // 2. CSS to Hide Desktop Clutter & Fix Layout
      const style = document.createElement('style');
      style.innerHTML = `
        /* Hide Headers, Footers, Sidebars, Ads */
        .top_nav, .header, .nav, .footer, .right_con, .ad_area, .login_box, 
        .search_box, .bread_nav, .h_r, .h_l, .logo, .nav_bar, .sub_nav,
        iframe, .advertisement, #header, #footer { display: none !important; }

        /* Make Main Content Full Width */
        .w1200 { width: 100% !important; margin: 0 !important; padding: 0 !important; }
        .main_con { width: 100% !important; float: none !important; }
        .left_con { width: 100% !important; float: none !important; }
        
        /* Table Styling */
        table { width: 100% !important; font-size: 14px !important; }
        th, td { padding: 8px 4px !important; text-align: center !important; }
        
        /* Body clean up */
        body { background: #fff !important; min-width: 100% !important; overflow-x: hidden; }
      `;
      document.head.appendChild(style);

      // 3. English Translation Dictionary
      const dict = {
        '最新价': 'Price', '涨跌': 'Chg', '涨跌幅': '%', 
        '买价': 'Bid', '卖价': 'Ask', '最高': 'High', '最低': 'Low',
        '今开': 'Open', '昨收': 'Prev', '持仓量': 'Vol', '品种': 'Symbol',
        '名称': 'Name', '时间': 'Time', '日期': 'Date', '结算价': 'Settle',
        'LME铜': 'Copper', 'LME铝': 'Aluminium', 'LME锌': 'Zinc',
        'LME铅': 'Lead', 'LME镍': 'Nickel', 'LME锡': 'Tin', 'LME合金': 'Alloy',
        'COMEX黄金': 'Gold', 'COMEX白银': 'Silver', 'COMEX铜': 'Copper', 
        '沪铜': 'Copper', '沪铝': 'Aluminium', '沪锌': 'Zinc', '沪铅': 'Lead', 
        '沪镍': 'Nickel', '沪锡': 'Tin', '沪金': 'Gold', '沪银': 'Silver',
        '行情中心': 'Market', '交易所': 'Exchange'
      };

      // 4. Translation Function
      function translatePage() {
        const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, null, false);
        let node;
        while(node = walker.nextNode()) {
            const text = node.nodeValue.trim();
            if(dict[text]) {
                node.nodeValue = dict[text];
            } else {
                for (let key in dict) {
                    if (text.includes(key)) {
                        node.nodeValue = node.nodeValue.replace(key, dict[key]);
                    }
                }
            }
        }
      }

      // Run Translation
      translatePage();
      setInterval(translatePage, 1000); // Keep translating dynamic updates
    """;
    
    _controller.runJavaScript(js);
  }

  String _getErrorMessage(WebResourceError error) {
    if (error.errorType == WebResourceErrorType.hostLookup) {
      return 'No internet connection';
    } else if (error.errorType == WebResourceErrorType.timeout) {
      return 'Connection timed out';
    }
    return 'Failed to load data';
  }

  void _startAutoRefresh() {
    // Auto-refresh every 60 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted && !_isLoading) {
        _controller.reload();
      }
    });
  }

  Future<void> _reload() async {
    setState(() {
      _hasError = false;
      _isLoading = true;
      _loadProgress = 0;
    });
    await _controller.reload();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_hasError) {
      return _buildErrorView();
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),

        // Loading progress bar
        if (_isLoading && _loadProgress > 0 && _loadProgress < 100)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _loadProgress / 100,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                ColorConstants.primaryBlue,
              ),
            ),
          ),

        // Full page loading indicator
        if (_isLoading && _loadProgress == 0)
          Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: ColorConstants.primaryBlue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading ${widget.title}...',
                    style: const TextStyle(
                      color: ColorConstants.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.signal_wifi_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: ColorConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
