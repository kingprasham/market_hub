import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/services/external_data_service.dart';
import '../../../core/services/google_sheets_service.dart';
import '../../../core/services/watchlist_service.dart';
import '../../../core/services/news_api_service.dart';
import '../../../core/services/rss_news_service.dart';
import '../../../core/services/admin_api_service.dart';
import '../../../data/models/content/update_model.dart';
import '../../../data/models/content/news_model.dart';
import '../../../data/models/user/user_model.dart';
import '../../../data/models/watchlist/watchlist_item_model.dart';
import '../../../app/routes/app_routes.dart';

class HomeController extends GetxController {
  final updates = <UpdateModel>[].obs;
  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final user = Rxn<UserModel>();

  // Real-time Data Sources
  final majorIndices = <Map<String, dynamic>>[].obs;
  final marketMovers = <Map<String, dynamic>>[].obs;
  final economicEvents = <Map<String, dynamic>>[].obs;

  // Starred items for KPI section
  final starredItems = <WatchlistItemModel>[].obs;

  // News preview for homepage
  final newsPreview = <NewsModel>[].obs;

  // SBI TT Rates
  final sbiTTRates = Rxn<SbiTTRates>();

  // RBI Reference Rates
  final rbiRates = <RbiReferenceRate>[].obs;

  // Google Sheets Data
  final sheetsData = <String, SheetData>{}.obs;

  StreamSubscription? _wsSubscription;
  WatchlistService? _watchlistService;
  NewsApiService? _newsApiService;
  RssNewsService? _rssNewsService;
  Timer? _autoRefreshTimer;
  int _previousUpdateCount = 0;

  // Ad carousel autoscroll
  late final PageController adPageController;
  Timer? _adAutoScrollTimer;
  static const int adCount = 7;
  final currentAdPage = 0.obs;

  @override
  void onInit() {
    super.onInit();
    adPageController = PageController(viewportFraction: 0.9);
    _startAdAutoScroll();
    loadUser();
    _initWatchlistService();
    _initNewsService();
    _loadAllData();
    _subscribeToWebSocket();
    _startAutoRefresh();
  }

  void _startAdAutoScroll() {
    _adAutoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (adPageController.hasClients) {
        currentAdPage.value = (currentAdPage.value + 1) % adCount;
        adPageController.animateToPage(
          currentAdPage.value,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  
  void _initNewsService() {
    try {
      _rssNewsService = Get.find<RssNewsService>();
      // Fetch news on init
      _loadNewsPreview();
    } catch (e) {
      debugPrint('RssNewsService not found, falling back to NewsApiService');
      try {
        _newsApiService = Get.find<NewsApiService>();
        _loadNewsPreviewFromApi();
      } catch (e) {
        debugPrint('NewsApiService not found');
      }
    }
  }
  
  Future<void> _loadNewsPreview() async {
    if (_rssNewsService == null) {
      await _loadNewsPreviewFromApi();
      return;
    }
    
    final news = await _rssNewsService!.fetchNews();
    if (news.isNotEmpty) {
      newsPreview.assignAll(news.take(5).toList());
    } else {
      // Fallback to API if RSS fails
      await _loadNewsPreviewFromApi();
    }
  }
  
  Future<void> _loadNewsPreviewFromApi() async {
    if (_newsApiService == null) return;
    
    await _newsApiService!.fetchEnglishNews();
    
    // Take first 5 news items for preview
    final news = _newsApiService!.englishNews;
    if (news.isNotEmpty) {
      newsPreview.assignAll(news.take(5).toList());
    }
  }

  void _initWatchlistService() {
    try {
      _watchlistService = Get.find<WatchlistService>();
      // Listen for changes in starred items
      ever(_watchlistService!.starredItemIds, (_) {
        _updateStarredItems();
      });
      ever(_watchlistService!.watchlistItems, (_) {
        _updateStarredItems();
      });
      _updateStarredItems();
    } catch (e) {
      // WatchlistService not available
    }
  }

  void _updateStarredItems() {
    if (_watchlistService != null) {
      starredItems.assignAll(_watchlistService!.starredItems);
    }
  }

  void loadUser() {
    user.value = LocalStorage.getUser();
  }

  Future<void> _loadAllData() async {
    isLoading.value = true;

    await Future.wait([
      fetchUpdates(),
      _loadExternalData(),
      _loadGoogleSheetsData(),
    ]);

    isLoading.value = false;
  }
  

  Future<void> _loadExternalData() async {
    try {
      final externalService = Get.find<ExternalDataService>();

      // Load SBI TT Rates
      sbiTTRates.value = externalService.sbiTTRatesValue;

      // Load RBI Reference Rates
      rbiRates.assignAll(externalService.rbiReferenceRates);

      // Load Economic Events
      _updateEconomicEvents(externalService.economicEvents);
      // Listen for updates using Rx getters
      ever(externalService.sbiTTRates, (SbiTTRates? rates) {
        sbiTTRates.value = rates;
      });

      ever(externalService.economicEventsRx, (List<EconomicEvent> events) {
        _updateEconomicEvents(events);
      });
    } catch (e) {
      // No fallback data
      debugPrint('Error loading external data: $e');
    }
  }

  Future<void> _loadGoogleSheetsData() async {
    try {
      final sheetsService = Get.find<GoogleSheetsService>();
      sheetsData.assignAll(sheetsService.allSheets);

      // Update major indices and market movers from spot bulletin
      _updateFromSpotBulletin(sheetsService);

      // Also try RATES sheet if available
      _updateIndicesFromSheets();

      // Load latest updates from news
      /*
      if (sheetsService.allIndiaNews.isNotEmpty) {
        updates.assignAll(sheetsService.allIndiaNews);
      }
      */
    } catch (e) {
      debugPrint('Error loading Google Sheets data: $e');
    }
  }

  void _updateFromSpotBulletin(GoogleSheetsService sheetsService) {
    final bulletin = sheetsService.spotBulletin;
    if (bulletin == null) return;

    final indicesData = <Map<String, dynamic>>[];
    final moversData = <Map<String, dynamic>>[];

    // Get unique metals from spot bulletin
    for (final section in bulletin.metalSections) {
      // Get first entry for each metal (Delhi prices as default)
      final entries = section.entries.where((e) =>
        e.city.toLowerCase() == 'delhi' || e.city.toLowerCase() == 'all india'
      ).toList();

      if (entries.isEmpty && section.entries.isNotEmpty) {
        // Use first available city
        final entry = section.entries.first;
        _addPriceEntry(entry, indicesData, moversData);
      } else if (entries.isNotEmpty) {
        final entry = entries.first;
        _addPriceEntry(entry, indicesData, moversData);
      }
    }

    // Add BME rates if available
    for (final bme in sheetsService.bmeRates) {
      moversData.add({
        'name': '${bme.metalName} ${bme.purity}',
        'price': bme.price,
        'change': bme.changePercent,
        'isPositive': bme.changePercent >= 0,
        'route': _getRouteForMetal(bme.metalName),
      });
    }

    if (indicesData.isNotEmpty) {
      majorIndices.assignAll(indicesData.take(8).toList());
    }

    if (moversData.isNotEmpty) {
      marketMovers.assignAll(moversData.take(10).toList());
    }
  }

  void _addPriceEntry(dynamic entry, List<Map<String, dynamic>> indices, List<Map<String, dynamic>> movers) {
    final name = entry.subtype.isNotEmpty ? '${entry.metalName} ${entry.subtype}' : entry.metalName;
    final change = entry.changePercent ?? 0.0;

    final data = {
      'name': name,
      'price': entry.cashPrice,
      'change': change,
      'isPositive': change >= 0,
      'route': _getRouteForMetal(entry.metalName),
    };

    indices.add(data);
    movers.add(data);
  }

  void _updateIndicesFromSheets() {
    // Check if we have RATES sheet with real data
    final ratesSheet = sheetsData['RATES'];
    if (ratesSheet != null && ratesSheet.isNotEmpty) {
      // Parse real rates from Google Sheets
      final updatedIndices = <Map<String, dynamic>>[];

      for (final row in ratesSheet.toMapList()) {
        final name = row['Name'] ?? row['METAL'] ?? '';
        final priceStr = row['Price'] ?? row['RATE'] ?? '0';
        final changeStr = row['Change'] ?? row['CHG'] ?? '0';

        if (name.isNotEmpty) {
          final price = double.tryParse(priceStr.replaceAll(',', '')) ?? 0;
          final change = double.tryParse(changeStr.replaceAll('%', '')) ?? 0;

          updatedIndices.add({
            'name': name,
            'price': price,
            'change': change,
            'isPositive': change >= 0,
            'route': _getRouteForMetal(name),
          });
        }
      }

      if (updatedIndices.isNotEmpty && majorIndices.isEmpty) {
        majorIndices.assignAll(updatedIndices);
      }
    }
  }

  String _getRouteForMetal(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('copper')) return AppRoutes.londonLme;
    if (lowerName.contains('gold')) return AppRoutes.spotPrice;
    if (lowerName.contains('silver')) return AppRoutes.spotPrice;
    if (lowerName.contains('usd') || lowerName.contains('inr')) return AppRoutes.fx;
    if (lowerName.contains('nickel')) return AppRoutes.nickelDetail;
    if (lowerName.contains('zinc')) return AppRoutes.zincDetail;
    if (lowerName.contains('lead')) return AppRoutes.leadDetail;
    if (lowerName.contains('aluminium')) return AppRoutes.aluminiumDetail;
    return AppRoutes.future;
  }

  void _updateEconomicEvents(List<EconomicEvent> events) {
    final mappedEvents = events.take(5).map((e) => {
      'event': e.eventName,
      'time': _formatEventTime(e.time),
      'impact': e.impact.name,
      'country': e.country,
      'actual': e.actual,
      'forecast': e.forecast,
      'previous': e.previous,
    }).toList();

    if (mappedEvents.isNotEmpty) {
      economicEvents.assignAll(mappedEvents);
    }
  }

  String _formatEventTime(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) {
      return 'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Tomorrow, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[date.weekday - 1]}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  void _subscribeToWebSocket() {
    try {
      final wsService = Get.find<WebSocketService>();
      _wsSubscription = wsService.dataStream.listen((update) {
        _handleWebSocketUpdate(update);
      });
    } catch (e) {
      // WebSocket not available
    }
  }

  void _handleWebSocketUpdate(MarketUpdate update) {
    if (update.payload is! Map<String, dynamic>) return;
    final data = update.payload as Map<String, dynamic>;

    switch (update.channel) {
      case 'lme':
      case 'shfe':
      case 'comex':
        _updateMajorIndicesFromWS(data);
        break;
      case 'fx':
        _updateFxFromWS(data);
        break;
    }

    // Also update starred items if they match
    _updateStarredItemFromWS(data);
  }

  void _updateMajorIndicesFromWS(Map<String, dynamic> data) {
    final symbol = data['symbol']?.toString() ?? '';
    final price = data['price']?.toDouble() ?? 0;
    final change = data['changePercent']?.toDouble() ?? 0;

    final index = majorIndices.indexWhere((item) =>
      item['name'].toString().toLowerCase().contains(symbol.toLowerCase()));

    if (index != -1) {
      majorIndices[index] = {
        ...majorIndices[index],
        'price': price,
        'change': change,
        'isPositive': change >= 0,
      };
    }

    // Also update market movers
    final moverIndex = marketMovers.indexWhere((item) =>
      item['name'].toString().toLowerCase().contains(symbol.toLowerCase()));

    if (moverIndex != -1) {
      marketMovers[moverIndex] = {
        ...marketMovers[moverIndex],
        'price': price,
        'change': change,
        'isPositive': change >= 0,
      };
    }
  }

  void _updateFxFromWS(Map<String, dynamic> data) {
    final pair = data['pair']?.toString() ?? '';
    final rate = data['rate']?.toDouble() ?? 0;
    final change = data['changePercent']?.toDouble() ?? 0;

    final index = majorIndices.indexWhere((item) =>
      item['name'].toString().contains(pair));

    if (index != -1) {
      majorIndices[index] = {
        ...majorIndices[index],
        'price': rate,
        'change': change,
        'isPositive': change >= 0,
      };
    }
  }

  void _updateStarredItemFromWS(Map<String, dynamic> data) {
    if (_watchlistService == null) return;

    final symbol = data['symbol']?.toString() ?? data['pair']?.toString() ?? '';
    final price = data['price']?.toDouble() ?? data['rate']?.toDouble();
    final change = data['change']?.toDouble();
    final changePercent = data['changePercent']?.toDouble();

    if (symbol.isNotEmpty && price != null) {
      _watchlistService!.updatePrice(
        symbol: symbol,
        price: price,
        change: change,
        changePercent: changePercent,
      );
    }
  }

  Future<void> fetchUpdates({bool silent = false}) async {
    try {
      // OVERRIDE: Hardcoded market update as requested
      //Replaces existing fetched data
      updates.assignAll([
        UpdateModel(
          id: 'copper_update_${DateTime.now().millisecondsSinceEpoch}',
          title: 'ALL INDIA COPPER PRICE UPDATE',
          description: '''MARKET HUB

ALL INDIA COPPER PRICE UPDATE

Reference Rates Only

BHIWADI MARKET 
CCR ROD : 1215+
SCRAP (ARM)
CASH: 1130+
CREDIT: 1132+
==========================

DELHI 

COPPER ROD
(8 MM / 1.6MM)
CC ROD: 1240+/1330/(1.6 MM: 1340)
CCR ROD: 1215+/1285/(1.6 MM: 1295)
SUPER D: 1193+/1258/(1.6 MM: 1272)
ZERO: 1183+/1248/(1.6 MM: 1262)
==========================

MUMBAI
COPPER ARM (CREDIT): 1155+
COPPER UTENSILS SCRAP: 1075+
JALI PATTI/HEAVY SCRAP : 1165+
LAL PATTI/COPPER CABLE : 1175+
==========================

AHMEDABAD
(PLUS GST RATE)
COPPER CCR: 1180
COPPER CCR 1.6 MM: 1190
BUNCH: 1212
TUKADI: 1142
SCRAP (ARM): 1105
==========================

PUNE
SCRAP (ARM) : 1145
DELHI RASA: 1045
TAMBA BARTAN: 1055
==========================

HYDERABAD
CC ROD: 1312+/1361
SUPER D: 1195+/1249
ARM: 1178 
==========================

NAGPUR
ARM : 1175
BARIK: 1117
KALYA: 1097
==========================

CHENNAI
ARM 1125
LAAL 1135
SUPER 1050
==========================

KOLKATA
ARM 1170
JALA 1180
SUPER 1122
==========================

RAIPUR
ARM 1175
JALA: 1185
SUPER: 1125

Reference Rates Only

MARKET HUB : 86240-72648, 0250-2469270''',
          category: 'Market Update',
          isImportant: true,
          createdAt: DateTime.now(),
        ),
      ]);
      _previousUpdateCount = updates.length;
      return;

      /*
      // Fetch combined updates from Admin Dashboard API (news, circulars, home updates)
      final adminApi = Get.find<AdminApiService>();
      final latestUpdates = await adminApi.getLatestUpdates(limit: 20);

      if (latestUpdates.isNotEmpty) {
        final updateList = latestUpdates.map((json) => UpdateModel(
          id: json['id']?.toString() ?? '',
          title: json['title'] ?? '',
          description: json['description'] ?? '',
          imageUrl: json['imageUrl'],
          pdfUrl: json['pdfUrl'],
          category: json['category'] ?? json['contentType'] ?? 'Update',
          createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
          isImportant: json['isImportant'] ?? false,
          targetPlanIds: json['targetPlans'] != null
              ? List<String>.from(json['targetPlans'])
              : const ['all'],
        )).toList();

        // Check if there are new updates
        final currentCount = updateList.length;
        final hasNewUpdates = _previousUpdateCount > 0 && currentCount > _previousUpdateCount;
        final newItemsCount = currentCount - _previousUpdateCount;

        updates.assignAll(updateList);


        debugPrint('Loaded $currentCount combined updates from admin API');

        // Show notification if new content is available (but not on initial load or silent refresh)
        if (hasNewUpdates && !silent) {
          Get.snackbar(
            'New Content Available',
            '$newItemsCount new update(s) added',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 3),
            backgroundColor: Get.theme.colorScheme.primary,
            colorText: Get.theme.colorScheme.onPrimary,
          );
        }

        _previousUpdateCount = currentCount;
        return;
      }
      */

      // Fallback to Google Sheets
      final sheetsService = Get.find<GoogleSheetsService>();
      if (sheetsService.allIndiaNews.isNotEmpty) {
         updates.assignAll(sheetsService.allIndiaNews);
         _previousUpdateCount = updates.length;
      }
    } catch (e) {
      debugPrint('Error fetching updates: $e');
      // Fallback to Google Sheets on error
      try {
        final sheetsService = Get.find<GoogleSheetsService>();
        if (sheetsService.allIndiaNews.isNotEmpty) {
           updates.assignAll(sheetsService.allIndiaNews);
           _previousUpdateCount = updates.length;
        }
      } catch (_) {}
    }
  }

  void _startAutoRefresh() {
    // Auto-refresh every 3 minutes
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      debugPrint('Auto-refreshing content...');
      fetchUpdates(silent: false); // Show toast if new content
    });
  }

  Future<void> refreshUpdates() async {
    isRefreshing.value = true;

    await Future.wait([
      fetchUpdates(),
      _loadExternalData(),
      _loadGoogleSheetsData(),
    ]);

    _updateStarredItems();

    isRefreshing.value = false;
  }



  @override
  void onClose() {
    _wsSubscription?.cancel();
    _autoRefreshTimer?.cancel();
    _adAutoScrollTimer?.cancel();
    adPageController.dispose();
    super.onClose();
  }
}
