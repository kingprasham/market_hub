import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/services/watchlist_service.dart';
import '../../../../../core/services/scraper/trading_economics_scraper_service.dart';
import '../../../../../data/models/watchlist/watchlist_item_model.dart';
import '../../../../../core/utils/helpers.dart';

/// FX Controller — always shows fixed pair list, populates N/A when data unavailable
class FxController extends GetxController {
  final isLoading = false.obs;
  final currencyPairs = <FxPair>[].obs;
  final watchlistUpdateTrigger = 0.obs;
  final dataSource = 'Loading...'.obs;
  final hasError = false.obs;
  final isRefreshing = false.obs;
  final selectedFilter = 'All'.obs;
  final filterOptions = <String>[];

  /// Fixed ordered list: (display pair, id key, match keywords)
  static const _fixedList = [
    ('USD/INR',      'usd_inr',  ['USDINR']),
    ('Dollar Index', 'dxy',      ['DXY']),
    ('EUR/USD',      'eur_usd',  ['EURUSD']),
    ('GBP/USD',      'gbp_usd',  ['GBPUSD']),
    ('USD/JPY',      'usd_jpy',  ['USDJPY']),
    ('USD/CNY',      'usd_cny',  ['USDCNY']),
  ];

  WatchlistService? _watchlistService;
  TradingEconomicsScraperService? _scraper;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    _initService();
    loadData();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => loadData());
  }

  void _initService() {
    try {
      _watchlistService = Get.find<WatchlistService>();
      if (_watchlistService != null) {
        ever(_watchlistService!.watchlistItems, (_) => watchlistUpdateTrigger.value++);
        ever(_watchlistService!.starredItemIds, (_) => watchlistUpdateTrigger.value++);
      }
    } catch (e) {
      debugPrint('WatchlistService not found: $e');
    }
    try {
      _scraper = TradingEconomicsScraperService();
    } catch (e) {
      debugPrint('TradingEconomicsScraperService error $e');
    }
  }

  List<FxPair> get filteredPairs => currencyPairs;
  void setFilter(String filter) => selectedFilter.value = filter;

  List<String> get watchlistIds =>
      _watchlistService?.watchlistItems.map((i) => i.id).toList() ?? [];
  bool isInWatchlist(String id) => _watchlistService?.isInWatchlist(id) ?? false;
  bool isStarred(String id) => _watchlistService?.isStarred(id) ?? false;

  Future<void> loadData() async {
    try {
      if (currencyPairs.isEmpty) {
        isLoading.value = true;
      }
      hasError.value = false;

      final now = DateTime.now();
      
      // 1. Create/Get base list. 
      // If we already have data, USE IT as the base so we don't show N/A while loading or on failure.
      final List<FxPair> base = currencyPairs.isEmpty 
        ? _fixedList.map((entry) => FxPair(
            id: 'fx_${entry.$2}',
            pair: entry.$1,
            bidPrice: null,
            askPrice: null,
            rate: null,
            high: null,
            low: null,
            prevHigh: null,
            prevLow: null,
            change: null,
            changePercent: null,
            lastUpdated: now,
            category: 'FX',
          )).toList()
        : List<FxPair>.from(currencyPairs);

      if (_scraper != null) {
        try {
          final fxModels = await _scraper!.fetchFX();
          if (fxModels.isNotEmpty) {
            for (int i = 0; i < base.length; i++) {
              final idKey = _fixedList[i].$2;
              final match = fxModels.firstWhereOrNull((fx) =>
                fx.symbol.toLowerCase() == idKey.toLowerCase()
              );
              
              if (match != null) {
                base[i] = FxPair(
                  id: base[i].id,
                  pair: base[i].pair,
                  bidPrice: null,
                  askPrice: null,
                  rate: match.price,
                  high: null,
                  low: null,
                  prevHigh: null,
                  prevLow: null,
                  change: match.change,
                  changePercent: match.changePercent,
                  lastUpdated: now,
                  category: base[i].category,
                );
              }
            }
            dataSource.value = 'TradingEconomics.com';
          } else {
            // If scraper succeeds but returns empty (rare), we keep existing data but update status
            dataSource.value = 'Data Unavailable';
          }
        } catch (e) {
          debugPrint('FX scraper error: $e');
          dataSource.value = 'Connection Error';
          // Keep existing base data!
        }
      } else {
        dataSource.value = 'Service Not Found';
      }

      currencyPairs.value = base;
      debugPrint('✅ FX: ${base.where((p) => p.rate != null).length}/${base.length} rates loaded');
    } catch (e) {
      debugPrint('Error in FX loadData: $e');
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
    final pair = currencyPairs.firstWhereOrNull((p) => p.id == id);
    if (pair == null) return;

    if (_watchlistService!.isInWatchlist(id)) {
      _watchlistService!.removeFromWatchlist(id);
      Helpers.showSuccess('Removed from watchlist');
    } else {
      final item = WatchlistItemModel.fromFx(
        pair: pair.pair,
        rate: pair.rate ?? 0,
        change: pair.change ?? 0,
        changePercent: pair.changePercent ?? 0,
      );
      _watchlistService!.addToWatchlist(item.copyWith(id: id));
      _watchlistService!.toggleStar(id);
      Helpers.showSuccess('Added to watchlist');
    }
    watchlistUpdateTrigger.value++;
  }
}

class FxPair {
  final String id;
  final String pair;
  final double? bidPrice;
  final double? askPrice;
  final double? rate;
  final double? high;
  final double? low;
  final double? prevHigh;
  final double? prevLow;
  final double? change;
  final double? changePercent;
  final DateTime lastUpdated;
  final String category;

  const FxPair({
    required this.id,
    required this.pair,
    required this.bidPrice,
    required this.askPrice,
    required this.rate,
    required this.high,
    required this.low,
    this.prevHigh,
    this.prevLow,
    required this.change,
    required this.changePercent,
    required this.lastUpdated,
    required this.category,
  });

  bool get hasData => rate != null;
}
