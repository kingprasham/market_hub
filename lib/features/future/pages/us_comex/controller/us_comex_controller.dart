import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/services/watchlist_service.dart';
import '../../../../../core/services/scraper/fx678_scraper_service.dart';
import '../../../../../core/services/scraper/jijinhao_scraper_service.dart';
import '../../../../../core/services/market_session_service.dart';
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
    ('Copper', 'HG', 'Base Metals'),
    ('Gold', 'GC', 'Precious Metals'),
    ('Silver', 'SI', 'Precious Metals'),
    ('WTI Crude Oil', 'CL', 'NYMEX'),
    ('Natural Gas', 'OIL', 'NYMEX'),
  ];

  WatchlistService? _watchlistService;
  MarketSessionService? _sessionService;
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
      _sessionService = Get.put(MarketSessionService());
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
      
      // Use existing data as base if available, otherwise create null-filled list
      final List<ComexMetal> base = metals.isEmpty
        ? List.generate(_fixedList.length, (i) => ComexMetal(
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
          ))
        : List<ComexMetal>.from(metals);

      // Primary: Jijinhao API (quheqihuo.com source) — provides high/low
      try {
        final jijinhao = Get.put(JijinhaoScraperService());
        final scraped = await jijinhao.fetchCOMEX();
        if (scraped.isNotEmpty) {
          _applyScrapedData(base, scraped);
          dataSource.value = 'quheqihuo.com (Live)';
        } else {
          // Fallback: FX678/Sina
          final fx678 = Get.put(FX678ScraperService());
          final fallbackScraped = await fx678.fetchCOMEX();
          if (fallbackScraped.isNotEmpty) {
            _applyScrapedData(base, fallbackScraped);
            dataSource.value = 'Sina Finance (Fallback)';
          } else {
            dataSource.value = 'Data Unavailable';
          }
        }
      } catch (e) {
        debugPrint('COMEX scraper error: $e');
        dataSource.value = 'Connection Error';
      }

      metals.value = base;

      // Update Watchlist prices
      if (_watchlistService != null && base.isNotEmpty) {
        for (final metal in base) {
          if (metal.lastPrice != null) {
            _watchlistService!.updatePriceById(
              id: metal.id,
              price: metal.lastPrice,
              change: metal.change,
              changePercent: metal.changePercent,
            );
          }
        }
      }

      debugPrint('✅ COMEX: ${base.where((m) => m.lastPrice != null).length}/${base.length} prices loaded');
    } catch (e) {
      debugPrint('Error in COMEX loadData: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  void _applyScrapedData(List<ComexMetal> base, List<ScrapedMetal> scraped) {
    final now = DateTime.now();
    for (int i = 0; i < base.length; i++) {
      final match = scraped.firstWhereOrNull((s) =>
        s.symbol.toUpperCase() == _fixedList[i].$2.toUpperCase() ||
        s.name.toUpperCase().contains(_fixedList[i].$1.toUpperCase())
      );
      if (match != null) {
        double finalChange = match.change;
        double finalPercent = match.changePercent;

        if (_sessionService != null && match.price > 0) {
          final results = _sessionService!.calculateChange(
            match.change,
            match.changePercent,
            MarketType.comex,
            base[i].symbol,
            match.price,
            match.prev,
          );
          finalChange = results['change']!;
          finalPercent = results['percent']!;
          _sessionService!.updateReferencePrice(MarketType.comex, base[i].symbol, match.price);
        }

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
          change: finalChange,
          changePercent: finalPercent,
          lastUpdated: now,
          category: base[i].category,
        );
      }
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
