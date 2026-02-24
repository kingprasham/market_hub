import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/services/watchlist_service.dart';
import '../../../../../core/services/scraper/fx678_scraper_service.dart';
import '../../../../../data/models/watchlist/watchlist_item_model.dart';
import '../../../../../core/utils/helpers.dart';

/// COMEX Controller — always shows fixed list, populates N/A when data unavailable
class USComexController extends GetxController {
  final isLoading = false.obs;
  final metals = <ComexMetal>[].obs;
  final watchlistUpdateTrigger = 0.obs;
  final dataSource = 'Loading...'.obs;
  final hasError = false.obs;
  final isRefreshing = false.obs;
  final selectedFilter = 'All'.obs;
  final filterOptions = <String>[];

  static const _fixedList = [
    ('Copper',        'HG', 'Base Metals'),
    ('Gold',          'GC', 'Precious Metals'),
    ('Silver',        'SI', 'Precious Metals'),
    ('WTI Crude Oil', 'CL', 'Energy'),
    ('Brent Crude Oil','OIL','Energy'),
    ('Natural Gas',   'NG', 'Energy'),
    ('Platinum',      'PL', 'Precious Metals'),
    ('Palladium',     'PA', 'Precious Metals'),
  ];

  static const _matchKeywords = [
    ['Copper'],
    ['Gold'],
    ['Silver'],
    ['WTI', 'Crude Oil'],
    ['Brent'],
    ['Natural Gas'],
    ['Platinum'],
    ['Palladium'],
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
      debugPrint('WatchlistService not found');
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => loadData());
  }

  List<ComexMetal> get filteredMetals => metals;
  void setFilter(String filter) => selectedFilter.value = filter;

  List<String> get watchlistIds =>
      _watchlistService?.watchlistItems.map((i) => i.id).toList() ?? [];

  Future<void> loadData() async {
    try {
      if (metals.isEmpty) {
        isLoading.value = true;
      }
      hasError.value = false;

      final now = DateTime.now();
      final base = List.generate(_fixedList.length, (i) => ComexMetal(
        id: 'comex_${_fixedList[i].$2.toLowerCase()}',
        symbol: _fixedList[i].$2,
        name: _fixedList[i].$1,
        contract: 'Front Month',
        lastPrice: null,
        high: null,
        low: null,
        prevHigh: null,
        prevLow: null,
        change: null,
        changePercent: null,
        lastUpdated: now,
        category: _fixedList[i].$3,
      ));

      try {
        final scraper = Get.put(FX678ScraperService());
        final scraped = await scraper.fetchCOMEX();
        if (scraped.isNotEmpty) {
          for (int i = 0; i < base.length; i++) {
            final keywords = _matchKeywords[i];
            final match = scraped.firstWhereOrNull((s) =>
              keywords.any((kw) => s.name.toUpperCase().contains(kw.toUpperCase())),
            );
            if (match != null) {
              base[i] = ComexMetal(
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
          dataSource.value = 'COMEX/NYMEX (Live)';
        } else {
          dataSource.value = 'Scraper Unavailable';
        }
      } catch (e) {
        debugPrint('COMEX scraper error: $e');
        dataSource.value = 'Scraper Error';
      }

      metals.value = base;
      debugPrint('✅ COMEX: ${base.where((m) => m.lastPrice != null).length}/${base.length} prices loaded');
    } catch (e) {
      debugPrint('Error in COMEX loadData: $e');
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
          exchange: 'COMEX',
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

class ComexMetal {
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

  const ComexMetal({
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
