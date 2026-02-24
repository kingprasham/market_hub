import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/color_constants.dart';
import '../common/common_app_bar_title.dart';

class EnhancedWebView extends StatefulWidget {
  final String url;
  final String title;
  final int timeoutSeconds;
  final bool enablePullToRefresh;
  final String? javascriptInjection;
  final VoidCallback? onLoadComplete;
  final Function(String)? onError;

  const EnhancedWebView({
    super.key,
    required this.url,
    required this.title,
    this.javascriptInjection,
    this.timeoutSeconds = 30,
    this.enablePullToRefresh = true,
    this.onLoadComplete,
    this.onError,
  });

  @override
  State<EnhancedWebView> createState() => _EnhancedWebViewState();
}

class _EnhancedWebViewState extends State<EnhancedWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _timeoutTimer;
  int _loadProgress = 0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: _onPageStarted,
          onPageFinished: _onPageFinished,
          onWebResourceError: _onWebResourceError,
          onProgress: (progress) {
            if (mounted) {
              setState(() => _loadProgress = progress);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    _startTimeoutTimer();
  }

  void _onPageStarted(String url) {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _loadProgress = 0;
      });
    }
    _startTimeoutTimer();
  }

  void _onPageFinished(String url) {
    _cancelTimeoutTimer();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _loadProgress = 100;
      });
    }
    if (widget.javascriptInjection != null) {
      _controller.runJavaScript(widget.javascriptInjection!);
    }
    widget.onLoadComplete?.call();
  }

  void _onWebResourceError(WebResourceError error) {
    _cancelTimeoutTimer();

    final errorMsg = error.errorType != null 
        ? _getErrorMessage(error.errorType!) 
        : 'An error occurred while loading the page.';

    if (mounted) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = errorMsg;
      });
    }

    widget.onError?.call(errorMsg);
  }

  String _getErrorMessage(WebResourceErrorType errorType) {
    switch (errorType) {
      case WebResourceErrorType.hostLookup:
        return 'Could not find the server. Please check your internet connection.';
      case WebResourceErrorType.timeout:
        return 'The connection timed out. Please try again.';
      case WebResourceErrorType.connect:
        return 'Failed to connect to the server.';
      case WebResourceErrorType.badUrl:
        return 'Invalid URL.';
      case WebResourceErrorType.authentication:
        return 'Authentication failed.';
      case WebResourceErrorType.unsupportedScheme:
        return 'Unsupported URL scheme.';
      case WebResourceErrorType.fileNotFound:
        return 'Resource not found.';
      default:
        return 'Failed to load page. Please try again.';
    }
  }

  void _startTimeoutTimer() {
    _cancelTimeoutTimer();
    _timeoutTimer = Timer(Duration(seconds: widget.timeoutSeconds), () {
      if (_isLoading && mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = 'Connection timed out after ${widget.timeoutSeconds} seconds';
        });
        widget.onError?.call(_errorMessage);
      }
    });
  }

  void _cancelTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
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
    _cancelTimeoutTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CommonAppBarTitle(title: widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
            tooltip: 'Reload',
          ),
        ],
      ),
      body: widget.enablePullToRefresh
          ? RefreshIndicator(
              onRefresh: _reload,
              color: ColorConstants.primaryBlue,
              child: _buildContent(),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
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
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: ColorConstants.primaryBlue,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
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
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ColorConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: ColorConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
