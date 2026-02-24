import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/services/watchlist_service.dart';
import '../../../../../core/services/external_apis/fx_rates_service.dart';
import '../../../../../core/services/scraper/fx678_scraper_service.dart';
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
    ('USD/INR',      'usd_inr',  ['USD/INR', 'INR', 'USDINR']),
    ('Dollar Index', 'dxy',      ['DXY', 'DOLLAR INDEX', 'US DOLLAR INDEX']),
    ('EUR',          'eur_usd',  ['EUR/USD', 'EURUSD', 'EUR']),
    ('GBP',          'gbp_usd',  ['GBP/USD', 'GBPUSD', 'GBP']),
    ('YEN',          'usd_jpy',  ['USD/JPY', 'USDJPY', 'JPY']),
    ('YUAN',         'usd_cny',  ['USD/CNY', 'USDCNY', 'CNY', 'YUAN']),
  ];

  WatchlistService? _watchlistService;
  FxRatesService? _fxService;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    _initService();
    loadData();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) => loadData());
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
      _fxService = Get.find<FxRatesService>();
    } catch (e) {
      debugPrint('FxRatesService not found');
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
      isLoading.value = true;
      hasError.value = false;

      // Build base list with all N/A
      final now = DateTime.now();
      final base = _fixedList.map((entry) => FxPair(
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
      )).toList();

      // Try live FX service (handles all pairs except Dollar Index)
      if (_fxService != null) {
        try {
          final fxModels = await _fxService!.getFxRates();
          if (fxModels.isNotEmpty) {
            for (int i = 0; i < base.length; i++) {
              final keywords = _fixedList[i].$3;
              final match = fxModels.firstWhereOrNull((fx) =>
                keywords.any((kw) => fx.pair.toUpperCase().contains(kw.toUpperCase())),
              );
              if (match != null) {
                base[i] = FxPair(
                  id: base[i].id,
                  pair: base[i].pair,
                  bidPrice: match.bid,
                  askPrice: match.ask,
                  rate: match.rate == 0 ? null : match.rate,
                  high: match.high,
                  low: match.low,
                  prevHigh: match.prevHigh,
                  prevLow: match.prevLow,
                  change: match.change,
                  changePercent: match.changePercent,
                  lastUpdated: now,
                  category: base[i].category,
                );
              }
            }
            dataSource.value = fxModels.first.source ?? 'Live API';
          } else {
            dataSource.value = 'API Unavailable';
          }
        } catch (e) {
          debugPrint('FX service error: $e');
          dataSource.value = 'API Error';
        }
      } else {
        dataSource.value = 'Service Not Found';
      }

      // Dollar Index (index 1 in fixed list) — FX service usually doesn't provide DXY,
      // so fetch it separately from the scraper.
      if (base[1].rate == null) {
        try {
          final scraper = FX678ScraperService();
          final dxy = await scraper.fetchDollarIndex();
          if (dxy != null && dxy.price > 0) {
            base[1] = FxPair(
              id: base[1].id,
              pair: base[1].pair,
              bidPrice: null,
              askPrice: null,
              rate: dxy.price,
              high: dxy.high > 0 ? dxy.high : null,
              low: dxy.low > 0 ? dxy.low : null,
              prevHigh: dxy.prevHigh > 0 ? dxy.prevHigh : null,
              prevLow: dxy.prevLow > 0 ? dxy.prevLow : null,
              change: dxy.change,
              changePercent: dxy.changePercent,
              lastUpdated: now,
              category: base[1].category,
            );
            debugPrint('✅ Dollar Index loaded: ${dxy.price}');
          }
        } catch (e) {
          debugPrint('Dollar Index scraper error: $e');
        }
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
