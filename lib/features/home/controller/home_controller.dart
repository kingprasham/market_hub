import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/services/external_data_service.dart';
import '../../../core/services/google_sheets_service.dart';
import '../../../core/services/watchlist_service.dart';
import '../../../core/services/news_api_service.dart';
import '../../../core/services/rss_news_service.dart';
import '../../../core/services/admin_api_service.dart';
import '../../../data/models/content/news_model.dart';
import '../../../data/models/content/update_model.dart';
import '../../../data/models/user/user_model.dart';
import '../../../data/models/watchlist/watchlist_item_model.dart';
import '../../../data/models/market/price_change_model.dart';
import '../../../core/constants/api_constants.dart';
import '../../../app/routes/app_routes.dart';

class HomeController extends GetxController {
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
  
  // Home Updates for homepage
  final homeUpdates = <UpdateModel>[].obs;

  // SBI TT Rates
  final sbiTTRates = Rxn<SbiTTRates>();

  // RBI Reference Rates
  final rbiRates = <RbiReferenceRate>[].obs;

  // Google Sheets Data
  final sheetsData = <String, SheetData>{}.obs;

  // ─── Price Change Tracking (Non-Ferrous Only) ───────────────────────────
  /// Detected price changes (only Non-Ferrous metals that actually changed).
  final priceChanges = <PriceChange>[].obs;

  /// Current "live" Non-Ferrous prices (flat list for the new details page).
  final nfCurrentPrices = <PriceChange>[].obs;

  /// Baseline snapshot: key → formatted price string.
  final Map<String, String> _priceSnapshot = {};

  /// Whether the very first load has been captured as the baseline.
  bool _baselineCaptured = false;

  /// Direct reactive getters — identical data the Spot tab displays.
  GoogleSheetsService? _sheetsServiceRef;

  /// Public accessor for the Live Prices section in the UI.
  GoogleSheetsService? get sheetsServiceRef => _sheetsServiceRef;

  StreamSubscription? _wsSubscription;
  WatchlistService? _watchlistService;
  NewsApiService? _newsApiService;
  RssNewsService? _rssNewsService;
  AdminApiService? _adminApiService;
  Timer? _autoRefreshTimer;

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
    _loadPriceSnapshots();
    _loadPriceChanges();
    _initSheetsRef();
    _loadAllData();
    _subscribeToWebSocket();
    _startAutoRefresh();
  }

  /// Cache a reference to GoogleSheetsService and start change tracking.
  void _initSheetsRef() {
    try {
      _sheetsServiceRef = Get.find<GoogleSheetsService>();
      _initPriceTracking();
    } catch (e) {
      debugPrint('[Home] GoogleSheetsService not available for live prices: $e');
    }
  }

  // ─── Change Tracking (Non-Ferrous Only) ─────────────────────────────────

  /// Hook `ever()` listener on Non-Ferrous data source.
  void _initPriceTracking() {
    final svc = _sheetsServiceRef;
    if (svc == null) return;

    // We only track Non-Ferrous changes as requested.
    ever(svc.nonFerrousData, (_) => _scanForChanges());
  }

  /// Build a flat key→price map from current Non-Ferrous data, then compare.
  void _scanForChanges() {
    final svc = _sheetsServiceRef;
    final nfData = svc?.nonFerrousData.value;
    if (nfData == null) return;

    final current = <String, _PriceEntry>{};

    // ── Scan only Non-Ferrous ──
    for (final city in nfData.cities) {
      for (final section in city.sections) {
        for (final item in section.items) {
          if (item.isSubHeader) continue;
          final p1 = item.price1;
          final p2 = item.price2;
          final cp = p1 ?? p2;
          if (cp == null || cp <= 0) continue;

          final key = 'NonFerrous|${section.sectionName}|${item.name}|${city.cityName}';
          String priceStr;
          if (p1 != null && p2 != null) {
            priceStr = '${p1.toStringAsFixed(0)}/${p2.toStringAsFixed(0)}';
          } else {
            priceStr = cp.toStringAsFixed(0);
          }

          current[key] = _PriceEntry(
            name: '${section.sectionName} – ${item.name}',
            city: city.cityName,
            category: 'Non-Ferrous',
            price: priceStr,
          );
        }
      }
    }

    final now = DateTime.now();

    // ── Update current live list ──
    final currentList = current.entries.map((e) => PriceChange(
      key: e.key,
      name: e.value.name,
      city: e.value.city,
      category: e.value.category,
      oldPrice: '', // Not used for current view
      newPrice: e.value.price,
      detectedAt: now,
    )).toList();
    nfCurrentPrices.assignAll(currentList);

    // ── First load → capture baseline ──
    if (!_baselineCaptured) {
      _baselineCaptured = true;
      for (final e in current.entries) {
        _priceSnapshot[e.key] = e.value.price;
      }
      debugPrint('[PriceTracker] Non-Ferrous baseline captured (${_priceSnapshot.length} entries)');
      _savePriceSnapshots();
      return;
    }

    // ── Compare to snapshot and detect changes ──
    final newChanges = <PriceChange>[];

    for (final e in current.entries) {
      final oldPrice = _priceSnapshot[e.key];
      if (oldPrice != null && oldPrice != e.value.price) {
        newChanges.add(PriceChange(
          key: e.key,
          name: e.value.name,
          city: e.value.city,
          category: e.value.category,
          oldPrice: '₹$oldPrice',
          newPrice: '₹${e.value.price}',
          detectedAt: now,
        ));
      }
      // Update snapshot to the latest value
      _priceSnapshot[e.key] = e.value.price;
    }

    if (newChanges.isNotEmpty) {
      // Prepend new changes and deduplicate by key (keep latest)
      final merged = [...newChanges, ...priceChanges];
      final seen = <String>{};
      final deduped = merged.where((c) {
        if (seen.contains(c.key)) return false;
        seen.add(c.key);
        return true;
      }).toList();
      priceChanges.assignAll(deduped);
      debugPrint('[PriceTracker] ${newChanges.length} Non-Ferrous change(s) detected');
      
      _savePriceChanges();
    }
    
    // Always persist latest snapshot state
    _savePriceSnapshots();
  }

  /// Load persisted snapshots from storage.
  void _loadPriceSnapshots() {
    try {
      final cached = LocalStorage.getCachedData('price_snapshots');
      if (cached != null && cached is Map) {
        _priceSnapshot.addAll(Map<String, String>.from(cached));
        _baselineCaptured = true;
        debugPrint('[PriceTracker] Loaded ${_priceSnapshot.length} persisted snapshots');
      }
    } catch (e) {
      debugPrint('[PriceTracker] Error loading snapshots: $e');
    }
  }

  /// Persist current snapshots to storage.
  void _savePriceSnapshots() {
    try {
      LocalStorage.cacheData('price_snapshots', _priceSnapshot);
    } catch (e) {
      debugPrint('[PriceTracker] Error saving snapshots: $e');
    }
  }

  /// Load persisted changes from storage.
  void _loadPriceChanges() {
    try {
      final cached = LocalStorage.getCachedData('nf_price_changes');
      if (cached != null && cached is List) {
        final loaded = cached
            .map((json) => PriceChange.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        priceChanges.assignAll(loaded);
        debugPrint('[PriceTracker] Loaded ${priceChanges.length} persisted changes');
      }
    } catch (e) {
      debugPrint('[PriceTracker] Error loading price changes: $e');
    }
  }

  /// Persist current changes to storage.
  void _savePriceChanges() {
    try {
      final data = priceChanges.map((c) => c.toJson()).toList();
      LocalStorage.cacheData('nf_price_changes', data);
    } catch (e) {
      debugPrint('[PriceTracker] Error saving price changes: $e');
    }
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
  
  Future<void> _loadHomeUpdates() async {
    if (_adminApiService == null) return;
    try {
      debugPrint('[HomeController] Fetching home updates from: ${ApiConstants.adminHomeUpdates}');
      final updatesData = await _adminApiService!.getHomeUpdates();
      debugPrint('[HomeController] Received ${updatesData.length} home updates from fallback/API');
      
      if (updatesData.isNotEmpty) {
        final updates = updatesData.map((json) => UpdateModel.fromJson(json)).toList();
        homeUpdates.assignAll(updates);
        debugPrint('[HomeController] Successfully matched ${homeUpdates.length} updates');
      } else {
        debugPrint('[HomeController] No home updates found in API response');
      }
    } catch (e) {
      debugPrint('[HomeController] Error loading home updates: $e');
    }
  }
  
  void _initNewsService() {
    try {
      _adminApiService = Get.find<AdminApiService>();
      _loadNewsPreview();
    } catch (e) {
      debugPrint('AdminApiService not found, falling back to RSS');
      try {
        _rssNewsService = Get.find<RssNewsService>();
        _loadNewsPreview();
      } catch (e) {
        debugPrint('RSS services not found');
      }
    }
  }
  
  Future<void> _loadNewsPreview() async {
    // Primary: Admin API News
    if (_adminApiService != null) {
      try {
        final newsData = await _adminApiService!.getNews();
        if (newsData.isNotEmpty) {
          final newsList = newsData.map((json) => NewsModel.fromJson(json)).toList();
          newsPreview.assignAll(newsList.take(5).toList());
          debugPrint('Loaded ${newsPreview.length} news preview items from Admin API');
          return;
        }
      } catch (e) {
        debugPrint('Error loading news from Admin API for home: $e');
      }
    }

    // Fallback: RSS News
    if (_rssNewsService != null) {
      final news = await _rssNewsService!.fetchNews();
      if (news.isNotEmpty) {
        newsPreview.assignAll(news.take(5).toList());
        debugPrint('Loaded ${newsPreview.length} news preview items from RSS fallback');
        return;
      }
    }
    
    // Last effort: NewsApiService
    await _loadNewsPreviewFromApi();
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
      ever(_watchlistService!.starredItemIds, (_) => _updateStarredItems());
      ever(_watchlistService!.watchlistItems, (_) => _updateStarredItems());
      _updateStarredItems();
    } catch (e) {
      // WatchlistService not available
    }
  }

  // _initSpotUpdates and _mergeSpotUpdates removed — live data is read
  // directly from GoogleSheetsService reactive observables.

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
      _loadExternalData(),
      _loadGoogleSheetsData(),
      _loadHomeUpdates(),
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
      
      // Explicitly trigger a fresh fetch to ensure we have latest data
      await sheetsService.fetchAllSheets();
      
      sheetsData.assignAll(sheetsService.allSheets);

      // Update major indices and market movers from spot bulletin
      _updateFromSpotBulletin(sheetsService);

      // Also try RATES sheet if available
      _updateIndicesFromSheets();
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

  // fetchUpdates() removed — live prices are read directly from
  // GoogleSheetsService reactive observables.

  void _startAutoRefresh() {
    // Auto-refresh every 3 minutes
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      debugPrint('Auto-refreshing content...');
      _loadGoogleSheetsData();
      _loadHomeUpdates();
    });
  }

  Future<void> refreshUpdates() async {
    isRefreshing.value = true;

    await Future.wait([
      _loadExternalData(),
      _loadGoogleSheetsData(),
      _loadHomeUpdates(),
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

/// Lightweight helper used by _scanForChanges to hold current-state entries.
class _PriceEntry {
  final String name;
  final String city;
  final String category;
  final String price;

  const _PriceEntry({
    required this.name,
    required this.city,
    required this.category,
    required this.price,
  });
}
