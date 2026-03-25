import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/google_sheets_service.dart';
import '../../../core/services/news_api_service.dart';
import '../../../core/services/rss_news_service.dart';
import '../../../core/services/admin_api_service.dart';
import '../../../data/models/content/news_model.dart';
import '../../../app/routes/app_routes.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AlertsController extends GetxController {
  final selectedTabIndex = 0.obs;
  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final hasNewContent = false.obs;
  final newContentCount = 0.obs;

  late final WebViewController liveFeedWebController;
  late final WebViewController calendarWebController;

  final liveFeed = <NewsModel>[].obs;
  final news = <NewsModel>[].obs;
  final hindiNews = <NewsModel>[].obs;
  final circulars = <NewsModel>[].obs;
  final economicEvents = <NewsModel>[].obs;

  // Pagination
  final currentPage = 1.obs;
  final itemsPerPage = 10;
  final hasMoreItems = true.obs;
  final isLoadingMore = false.obs;

  StreamSubscription? _wsSubscription;
  Timer? _autoRefreshTimer;

  // Live Feed tab commented out per user request
  final tabs = ['News', 'Hindi', 'Circular', 'Calendar'];

  // Auto-refresh intervals (in seconds)
  static const int liveFeedInterval = 30; // 30 seconds for live feed
  static const int newsInterval = 60; // 1 minute for news
  static const int circularsInterval = 45; // 45 seconds for circulars
  static const int contentCheckInterval = 15; // Check for new content every 15 seconds

  NewsApiService? _newsApiService;
  RssNewsService? _rssNewsService;
  AdminApiService? _adminApiService;

  // Track previous counts for detecting new content
  int _previousNewsCount = 0;
  int _previousHindiNewsCount = 0;
  int _previousCircularsCount = 0;

  @override
  void onInit() {
    super.onInit();
    _initWebControllers();
    _initServices();
    _subscribeToSheetUpdates();
    _handleArguments();
    // Fetch initial data
    _fetchAllNews();
    _startAutoRefresh();
  }

  void _handleArguments() {
    final args = Get.arguments;
    if (args is Map) {
      if (args['tabIndex'] != null) {
        selectedTabIndex.value = args['tabIndex'];
      } else if (args['sub_tab'] != null) {
        selectedTabIndex.value = args['sub_tab'];
      }
    }
  }

  void _initWebControllers() {
    // Initialize Live News Controller
    liveFeedWebController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://widgets.tradingeconomics.com/news?utm_source=te-section'));

    // Initialize Calendar Controller
    calendarWebController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://sslecal2.investing.com?columns=exc_flags,exc_currency,exc_importance,exc_actual,exc_forecast,exc_previous&features=datepicker,timezone&countries=25,34,32,6,37,72,71,22,17,51,39,14,33,10,35,42,43,45,38,56,36,110,11,26,9,12,41,4,5,178&calType=week&timeZone=23&lang=56'));
  }

  void _initServices() {
    try {
      _adminApiService = Get.find<AdminApiService>();
    } catch (e) {
      debugPrint('AdminApiService not found');
    }

    try {
      _rssNewsService = Get.find<RssNewsService>();
    } catch (e) {
      debugPrint('RssNewsService not found');
    }

    try {
      _newsApiService = Get.find<NewsApiService>();
    } catch (e) {
      debugPrint('NewsApiService not found');
    }
  }

  void _subscribeToSheetUpdates() {
    // Removed Google Sheets subscription for circulars
    // Circulars now only come from Admin API
    // Keep method for potential future use with other sheet updates
  }
  
  /// Fetch news from Admin API (primary source)
  Future<void> _fetchAllNews() async {
    isLoading.value = true;

    // Primary: Use Admin API for all content
    if (_adminApiService != null) {
      await _fetchFromAdminApi();
    } else {
      // Fallback to RSS/NewsApi if AdminApiService not available
      await _fetchFromFallbackSources();
    }

    hasMoreItems.value = false; // All data loaded at once
    isLoading.value = false;
  }

  /// Fetch all content from Admin API
  Future<void> _fetchFromAdminApi({bool silent = false}) async {
    int newNewsCount = 0;
    int newHindiCount = 0;
    int newCircularsCount = 0;

    // 1. Fetch English news
    try {
      final englishNewsData = await _adminApiService!.getNews();
      final newsList = englishNewsData.map((json) {
        final newsItem = NewsModel.fromJson(json);
        return NewsModel(
          id: newsItem.id,
          title: newsItem.title,
          description: newsItem.description,
          imageUrl: newsItem.imageUrl,
          pdfUrl: newsItem.pdfUrl,
          sourceLink: newsItem.sourceLink,
          newsType: 'news',
          targetPlanIds: newsItem.targetPlanIds,
          publishedAt: newsItem.publishedAt,
          createdAt: newsItem.createdAt,
        );
      }).toList();

      newNewsCount = _previousNewsCount > 0 && newsList.length > _previousNewsCount
          ? newsList.length - _previousNewsCount
          : 0;

      news.assignAll(newsList);
      _previousNewsCount = newsList.length;
      debugPrint('Loaded ${newsList.length} English news from Admin API');
    } catch (e) {
      debugPrint('Error fetching English news: $e');
    }

    // 2. Fetch Hindi news
    try {
      final hindiNewsData = await _adminApiService!.getHindiNews();
      final hindiNewsList = hindiNewsData.map((json) {
        final newsItem = NewsModel.fromJson(json);
        return NewsModel(
          id: newsItem.id,
          title: newsItem.title,
          description: newsItem.description,
          imageUrl: newsItem.imageUrl,
          pdfUrl: newsItem.pdfUrl,
          sourceLink: newsItem.sourceLink,
          newsType: 'hindi_news',
          targetPlanIds: newsItem.targetPlanIds,
          publishedAt: newsItem.publishedAt,
          createdAt: newsItem.createdAt,
        );
      }).toList();

      newHindiCount = _previousHindiNewsCount > 0 && hindiNewsList.length > _previousHindiNewsCount
          ? hindiNewsList.length - _previousHindiNewsCount
          : 0;

      hindiNews.assignAll(hindiNewsList);
      _previousHindiNewsCount = hindiNewsList.length;
      debugPrint('Loaded ${hindiNewsList.length} Hindi news from Admin API');
    } catch (e) {
      debugPrint('Error fetching Hindi news: $e');
    }

    // 3. Fetch circulars
    try {
      final circularsData = await _adminApiService!.getCirculars();
      final circularsList = circularsData.map((json) {
        final newsItem = NewsModel.fromJson(json);
        return NewsModel(
          id: newsItem.id,
          title: newsItem.title,
          description: newsItem.description,
          imageUrl: newsItem.imageUrl,
          pdfUrl: newsItem.pdfUrl,
          newsType: 'circular',
          targetPlanIds: newsItem.targetPlanIds,
          publishedAt: newsItem.publishedAt,
          createdAt: newsItem.createdAt,
        );
      }).toList();

      newCircularsCount = _previousCircularsCount > 0 && circularsList.length > _previousCircularsCount
          ? circularsList.length - _previousCircularsCount
          : 0;

      circulars.assignAll(circularsList);
      _previousCircularsCount = circularsList.length;
      debugPrint('Loaded ${circularsList.length} circulars from Admin API');
    } catch (e) {
      debugPrint('Error fetching circulars: $e');
    }

    // Fallback if Admin API returns nothing for BOTH news and hindiNews
    if (news.isEmpty && hindiNews.isEmpty) {
      debugPrint('No news or Hindi news found in Admin API, trying fallback sources...');
      await _fetchFromFallbackSources();
    }

    // Show toast if new content is available (not on initial load or silent refresh)
    final totalNewItems = newNewsCount + newHindiCount + newCircularsCount;
    if (totalNewItems > 0 && !silent) {
      final categories = <String>[];
      if (newNewsCount > 0) categories.add('$newNewsCount News');
      if (newHindiCount > 0) categories.add('$newHindiCount Hindi');
      if (newCircularsCount > 0) categories.add('$newCircularsCount Circular');

      Get.snackbar(
        'New Content Available',
        categories.join(', '),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    }
  }

  void _startAutoRefresh() {
    // Auto-refresh every 30 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      debugPrint('Auto-refreshing alerts content...');
      if (_adminApiService != null) {
        _fetchFromAdminApi(silent: false); // Show toast if new content
      }
    });
  }

  /// Fallback to RSS/NewsApi sources
  Future<void> _fetchFromFallbackSources() async {
    // Use RSS feeds for English news
    if (_rssNewsService != null) {
      final rssNews = await _rssNewsService!.fetchNews();
      if (rssNews.isNotEmpty) {
        news.assignAll(rssNews);
      }
    }

    // Use NewsApiService for Hindi news
    if (_newsApiService != null) {
      await _newsApiService!.fetchHindiNews();
      hindiNews.assignAll(_newsApiService!.hindiNews);
    }

    // Removed Google Sheets fallback for circulars
    // Circulars should only come from Admin API
  }

  /// Update circulars from Google Sheets (DEPRECATED - keeping for backwards compatibility)
  /// Circulars now come from Admin API only
  void _updateCircularsFromSheets() {
    // This method is deprecated and no longer used
    // Circulars are fetched from Admin API only
    debugPrint('Warning: _updateCircularsFromSheets is deprecated, circulars come from Admin API');
  }

  @override
  void onClose() {
    _wsSubscription?.cancel();
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  // --- Legacy / Unused Methods (Kept as no-ops or simplified for UI compatibility) ---
  
  /// Open Economic Calendar WebView (Investing.com real-time)
  void openEconomicCalendarWebView() {
    Get.toNamed(AppRoutes.economicCalendarWebView);
  }

  /// Open Live News WebView (Trading Economics)
  void openLiveNewsWebView() {
    Get.toNamed(AppRoutes.liveNewsWebView);
  }

  Future<void> refreshData() async {
    isRefreshing.value = true;

    // Primary: Refresh from Admin API
    if (_adminApiService != null) {
      await _fetchFromAdminApi();
    } else {
      // Fallback refresh
      if (_rssNewsService != null) {
        final rssNews = await _rssNewsService!.refreshNews();
        if (rssNews.isNotEmpty) {
          news.assignAll(rssNews);
        }
      }

      if (_newsApiService != null) {
        await _newsApiService!.fetchHindiNews(forceRefresh: true);
        hindiNews.assignAll(_newsApiService!.hindiNews);
      }

      _updateCircularsFromSheets();
    }

    isRefreshing.value = false;
  }

  void changeTab(int index) {
    selectedTabIndex.value = index;
    // Reset pagination/new flags if needed
  }
  
  void loadMoreItems() async {
    // No-op for now, sheet data is all-in-one
  }

  void loadNewContent() {
    hasNewContent.value = false;
    newContentCount.value = 0;
  }

  List<NewsModel> getCurrentTabItems() {
    switch (selectedTabIndex.value) {
      case 0: return news;
      case 1: return hindiNews;
      case 2: return circulars;
      case 3: return economicEvents;
      default: return [];
    }
  }

  // Public fetch method - triggers a full refresh
  Future<void> fetchAllData() async {
    await refreshData();
  }
  Future<void> fetchLiveFeed() async {}
  Future<void> fetchNews() async {}
  Future<void> fetchHindiNews() async {}
  Future<void> fetchCirculars() async {}
  Future<void> fetchEconomicCalendar() async {}
}

