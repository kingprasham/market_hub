import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/services/watchlist_service.dart';
import '../../../../../core/services/scraper/fx678_scraper_service.dart';
import '../../../../../core/services/market_session_service.dart';
import '../../../../../data/models/watchlist/watchlist_item_model.dart';
import '../../../../../core/utils/helpers.dart';

/// SHFE Controller — always shows fixed metal list, populates N/A when data unavailable
class ChinaSHFEController extends GetxController {
  final isLoading = false.obs;
  final metals = <SHFEMetal>[].obs;
  final watchlistUpdateTrigger = 0.obs;
  final dataSource = 'Loading...'.obs;
  final hasError = false.obs;
  final isRefreshing = false.obs;
  final selectedFilter = 'All'.obs;
  final filterOptions = <String>[];

  /// Fixed ordered list — symbol used for matching
  static const _fixedList = [
    ('Copper',                    'CU'),
    ('Aluminium',                 'AL'),
    ('Zinc',                      'ZN'),
    ('Nickel',                    'NI'),
    ('Lead',                      'PB'),
    ('Tin',                       'SN'),
    ('Gold',                      'AU'),
    ('Silver',                    'AG'),
    ('Ferro Silicon',             'SF'),
    ('Ferro Manganese Silicon',   'SM'),
    ('SS',                        'SS'),
    ('WR',                        'WR'),
    ('Rebar',                     'RB'),
  ];

  /// Match keywords used to find scraped data for each entry
  static const _matchKeywords = [
    ['Copper'],
    ['Aluminium', 'Aluminum'],
    ['Zinc'],
    ['Nickel'],
    ['Lead'],
    ['Tin'],
    ['Gold'],
    ['Silver'],
    ['Ferro Silicon'],
    ['Ferro Manganese', 'Ferro Mn', 'Manganese Silicon'],
    ['SS', 'Stainless'],
    ['WR', 'Wire Rod'],
    ['Rebar'],
  ];

  WatchlistService? _watchlistService;
  MarketSessionService? _sessionService;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    _initService();
    loadData();
    _startAutoRefresh();
  }

  void _initService() {
    try {
      _watchlistService = Get.find<WatchlistService>();
      _sessionService = Get.put(MarketSessionService());
      if (_watchlistService != null) {
        ever(_watchlistService!.watchlistItems, (_) => watchlistUpdateTrigger.value++);
        ever(_watchlistService!.starredItemIds, (_) => watchlistUpdateTrigger.value++);
      }
    } catch (e) {
      debugPrint('WatchlistService not found: $e');
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => loadData());
  }

  List<SHFEMetal> get filteredMetals => metals;
  void setFilter(String filter) => selectedFilter.value = filter;

  List<String> get watchlistIds =>
      _watchlistService?.watchlistItems.map((i) => i.id).toList() ?? [];
  bool isInWatchlist(String id) => _watchlistService?.isInWatchlist(id) ?? false;
  bool isStarred(String id) => _watchlistService?.isStarred(id) ?? false;

  Future<void> loadData() async {
    try {
      if (metals.isEmpty) {
        isLoading.value = true;
      }
      hasError.value = false;

      final now = DateTime.now();
      
      // Use existing data as base if available, otherwise create null-filled list
      final List<SHFEMetal> base = metals.isEmpty
        ? List.generate(_fixedList.length, (i) => SHFEMetal(
            id: 'shfe_${_fixedList[i].$2.toLowerCase()}',
            symbol: _fixedList[i].$2,
            name: 'SHFE ${_fixedList[i].$1}',
            contract: 'Main Continuous',
            lastPrice: null,
            high: null,
            low: null,
            prevHigh: null,
            prevLow: null,
            change: null,
            changePercent: null,
            lastUpdated: now,
          ))
        : List<SHFEMetal>.from(metals);

      try {
        final scraper = Get.put(FX678ScraperService());
        final scraped = await scraper.fetchSHFE();
        if (scraped.isNotEmpty) {
          for (int i = 0; i < base.length; i++) {
            final keywords = _matchKeywords[i];
            final match = scraped.firstWhereOrNull((s) =>
              keywords.any((kw) => s.name.toUpperCase().contains(kw.toUpperCase())),
            );
            if (match != null) {
              // Custom change calculation based on session time
              double finalChange = match.change;
              double finalPercent = match.changePercent;

              if (_sessionService != null && match.price > 0) {
                final results = _sessionService!.calculateChange(
                  match.change,
                  match.changePercent,
                  MarketType.china, 
                  base[i].symbol, 
                  match.price, 
                  match.prev,
                );
                finalChange = results['change']!;
                finalPercent = results['percent']!;
                
                // Track current price for reference capture
                _sessionService!.updateReferencePrice(MarketType.china, base[i].symbol, match.price);
              }

              base[i] = SHFEMetal(
                id: base[i].id,
                symbol: base[i].symbol,
                name: base[i].name,
                contract: base[i].contract,
                lastPrice: match.price == 0 ? null : match.price,
                high: match.high == 0 ? null : match.high,
                low: match.low == 0 ? null : match.low,
                prevHigh: match.prevHigh == 0 ? null : match.prevHigh,
                prevLow: match.prevLow == 0 ? null : match.prevLow,
                change: finalChange,
                changePercent: finalPercent,
                lastUpdated: now,
              );
            }
          }
          dataSource.value = 'SHFE (Live)';
        } else {
          dataSource.value = 'Data Unavailable';
        }
      } catch (e) {
        debugPrint('SHFE scraper error: $e');
        dataSource.value = 'Connection Error';
      }

      metals.value = base;
      debugPrint('✅ SHFE: ${base.where((m) => m.lastPrice != null).length}/${base.length} prices loaded');
    } catch (e) {
      debugPrint('Error in SHFE loadData: $e');
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
      final item = WatchlistItemModel.fromFuture(
        symbol: metal.symbol,
        name: metal.name,
        exchange: 'SHFE',
        price: metal.lastPrice ?? 0,
        change: metal.change ?? 0,
        changePercent: metal.changePercent ?? 0,
        currency: 'CNY',
      );
      _watchlistService!.addToWatchlist(item.copyWith(id: id));
      _watchlistService!.toggleStar(id);
      Helpers.showSuccess('Added to watchlist');
    }
    watchlistUpdateTrigger.value++;
  }
}

class SHFEMetal {
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

  const SHFEMetal({
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
  });

  bool get hasData => lastPrice != null;
}
