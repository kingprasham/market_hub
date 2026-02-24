import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/services/watchlist_service.dart';
import '../../../../../core/services/scraper/fx678_scraper_service.dart';
import '../../../../../data/models/watchlist/watchlist_item_model.dart';
import '../../../../../core/utils/helpers.dart';

/// LME Controller — always shows fixed metal list, populates N/A when data unavailable
class LondonLMEController extends GetxController {
  final isLoading = false.obs;
  final metals = <LMEMetal>[].obs;
  final watchlistUpdateTrigger = 0.obs;
  final dataSource = 'Loading...'.obs;
  final hasError = false.obs;
  final isRefreshing = false.obs;
  final selectedFilter = 'All'.obs;
  final filterOptions = <String>[];

  /// Fixed ordered list — always displayed; prices filled from scraper
  static const _fixedList = [
    ('Copper',    'CU'),
    ('Aluminium', 'AL'),
    ('Zinc',      'ZN'),
    ('Nickel',    'NI'),
    ('Lead',      'PB'),
    ('Tin',       'SN'),
    ('Aluminium Alloy', 'AA'),
  ];

  WatchlistService? _watchlistService;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    _initServices();
    loadData();
    _startAutoRefresh();
  }

  void _initServices() {
    try {
      _watchlistService = Get.find<WatchlistService>();
      if (_watchlistService != null) {
        ever(_watchlistService!.watchlistItems, (_) => watchlistUpdateTrigger.value++);
        ever(_watchlistService!.starredItemIds, (_) => watchlistUpdateTrigger.value++);
      }
    } catch (e) {
      debugPrint('WatchlistService not found: $e');
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 30), (_) => loadData());
  }

  List<LMEMetal> get filteredMetals => metals;
  void setFilter(String filter) => selectedFilter.value = filter;

  List<String> get watchlistIds =>
      _watchlistService?.watchlistItems.map((i) => i.id).toList() ?? [];
  bool isInWatchlist(String id) => _watchlistService?.isInWatchlist(id) ?? false;

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      // Build base list with N/A values
      final now = DateTime.now();
      final base = _fixedList.map((entry) => LMEMetal(
        id: 'lme_${entry.$2.toLowerCase()}',
        symbol: entry.$2,
        name: 'LME ${entry.$1}',
        contract: '3-Month',
        lastPrice: null,
        high: null,
        low: null,
        prevHigh: null,
        prevLow: null,
        change: null,
        changePercent: null,
        lastUpdated: now,
        category: 'Base Metals',
      )).toList();

      // Try scraper — fill in prices where available
      try {
        final scraper = Get.put(FX678ScraperService());
        final scraped = await scraper.fetchLME();
        if (scraped.isNotEmpty) {
          for (int i = 0; i < base.length; i++) {
            final match = scraped.firstWhereOrNull(
              (s) => s.name.toUpperCase().contains(_fixedList[i].$1.toUpperCase()) ||
                     s.symbol.toUpperCase() == _fixedList[i].$2.toUpperCase(),
            );
            if (match != null) {
              base[i] = LMEMetal(
                id: base[i].id,
                symbol: base[i].symbol,
                name: base[i].name,
                contract: base[i].contract,
                lastPrice: match.price == 0 ? null : match.price,
                high: match.high == 0 ? null : match.high,
                low: match.low == 0 ? null : match.low,
                prevHigh: match.prevHigh == 0 ? null : match.prevHigh,
                prevLow: match.prevLow == 0 ? null : match.prevLow,
                change: match.change,
                changePercent: match.changePercent,
                lastUpdated: now,
                category: base[i].category,
              );
            }
          }
          dataSource.value = 'FX678 (Live)';
        } else {
          dataSource.value = 'Scraper Unavailable';
        }
      } catch (e) {
        debugPrint('LME scraper error: $e');
        dataSource.value = 'Scraper Error';
      }

      metals.value = base;
      debugPrint('✅ LME: ${base.where((m) => m.lastPrice != null).length}/${base.length} prices loaded');
    } catch (e) {
      debugPrint('Error in LME loadData: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshData() async {
    isRefreshing.value = true;
    await loadData();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  void toggleWatchlist(String id) {
    if (_watchlistService == null) {
      Helpers.showError('Watchlist service not available');
      return;
    }
    final metal = metals.firstWhereOrNull((m) => m.id == id);
    if (metal == null) return;

    if (_watchlistService!.isInWatchlist(id)) {
      _watchlistService!.removeFromWatchlist(id);
      Helpers.showSuccess('Removed from watchlist');
    } else {
      _watchlistService!.addToWatchlist(
        WatchlistItemModel.fromFuture(
          symbol: metal.symbol,
          name: metal.name,
          exchange: 'LME',
          price: metal.lastPrice ?? 0,
          change: metal.change ?? 0,
          changePercent: metal.changePercent ?? 0,
          currency: 'USD',
        ).copyWith(id: id),
      );
      _watchlistService!.toggleStar(id);
      Helpers.showSuccess('Added to watchlist');
    }
    watchlistUpdateTrigger.value++;
  }
}

class LMEMetal {
  final String id;
  final String symbol;
  final String name;
  final String contract;
  final double? lastPrice;
  final double? high;
  final double? low;
  final double? prevHigh;
  final double? prevLow;
  final double? change;
  final double? changePercent;
  final DateTime lastUpdated;
  final String category;

  const LMEMetal({
    required this.id,
    required this.symbol,
    required this.name,
    required this.contract,
    required this.lastPrice,
    required this.high,
    required this.low,
    this.prevHigh,
    this.prevLow,
    required this.change,
    required this.changePercent,
    required this.lastUpdated,
    required this.category,
  });

  bool get hasData => lastPrice != null;
}
