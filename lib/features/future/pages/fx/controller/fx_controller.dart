import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/services/watchlist_service.dart';
import '../../../../../core/services/external_apis/fx_rates_service.dart';
import '../../../../../data/models/watchlist/watchlist_item_model.dart';
import '../../../../../core/utils/helpers.dart';

class FxController extends GetxController {
  final isLoading = false.obs;
  final currencyPairs = <FxPair>[].obs;
  final watchlistUpdateTrigger = 0.obs;
  final dataSource = 'Loading...'.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final selectedFilter = 'All'.obs;
  
  final filterOptions = ['All', 'Major', 'Cross', 'Exotic'];

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
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      loadData();
    });
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

  // Filtered pairs based on selected filter
  List<FxPair> get filteredPairs {
    if (selectedFilter.value == 'All') {
      return currencyPairs;
    }
    return currencyPairs.where((p) => p.category == selectedFilter.value).toList();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  List<String> get watchlistIds {
    if (_watchlistService == null) return [];
    return _watchlistService!.watchlistItems.map((item) => item.id).toList();
  }

  bool isInWatchlist(String id) {
    return _watchlistService?.isInWatchlist(id) ?? false;
  }

  bool isStarred(String id) {
    return _watchlistService?.isStarred(id) ?? false;
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      
      if (_fxService == null) {
        hasError.value = true;
        errorMessage.value = 'FX service not initialized';
        currencyPairs.value = [];
        dataSource.value = 'No Data';
        return;
      }
      
      final fxModels = await _fxService!.getFxRates();
      
      if (fxModels.isEmpty) {
        hasError.value = true;
        errorMessage.value = 'Failed to fetch FX rates from API';
        currencyPairs.value = [];
        dataSource.value = 'No Data';
        return;
      }
      
      currencyPairs.value = fxModels.map((fx) => FxPair(
        id: 'fx_${fx.pair.replaceAll('/', '_').toLowerCase()}',
        pair: fx.pair,
        bidPrice: fx.bid ?? fx.rate * 0.9999,
        askPrice: fx.ask ?? fx.rate * 1.0001,
        rate: fx.rate,
        high: fx.high ?? fx.rate * 1.005,
        low: fx.low ?? fx.rate * 0.995,
        change: fx.change,
        changePercent: fx.changePercent,
        lastUpdated: fx.lastUpdated,
        category: _getCurrencyCategory(fx.pair),
      )).toList();
      
      dataSource.value = fxModels.first.source ?? 'Live API';
      
    } catch (e) {
      debugPrint('Error loading FX data: $e');
      hasError.value = true;
      errorMessage.value = 'Error: $e';
      currencyPairs.value = [];
      dataSource.value = 'Error';
    } finally {
      isLoading.value = false;
    }
  }

  /// Categorize currency pairs as Major, Cross, or Exotic
  String _getCurrencyCategory(String pair) {
    final majorCurrencies = ['USD', 'EUR', 'GBP', 'JPY', 'CHF', 'AUD', 'NZD', 'CAD'];
    final parts = pair.split('/');
    if (parts.length != 2) return 'Other';
    
    final first = parts[0].toUpperCase();
    final second = parts[1].toUpperCase();
    
    // Major pairs: EUR/USD, GBP/USD, USD/JPY, USD/CHF, AUD/USD, NZD/USD, USD/CAD
    if ((first == 'USD' || second == 'USD') && 
        majorCurrencies.contains(first) && 
        majorCurrencies.contains(second)) {
      return 'Major';
    }
    
    // Cross pairs: Major currencies vs each other without USD
    if (first != 'USD' && second != 'USD' &&
        majorCurrencies.contains(first) && 
        majorCurrencies.contains(second)) {
      return 'Cross';
    }
    
    // Exotic: Major vs emerging market currency
    return 'Exotic';
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  Future<void> refreshData() async {
    await loadData();
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
        rate: pair.rate,
        change: pair.change,
        changePercent: pair.changePercent,
      );
      _watchlistService!.addToWatchlist(item.copyWith(id: id));
      _watchlistService!.toggleStar(id);
      Helpers.showSuccess('Added to watchlist & starred');
    }
    watchlistUpdateTrigger.value++;
  }
}

class FxPair {
  final String id;
  final String pair;
  final double bidPrice;
  final double askPrice;
  final double rate;
  final double high;
  final double low;
  final double change;
  final double changePercent;
  final DateTime lastUpdated;
  final String category; // Major, Cross, Exotic

  FxPair({
    required this.id,
    required this.pair,
    required this.bidPrice,
    required this.askPrice,
    required this.rate,
    required this.high,
    required this.low,
    required this.change,
    required this.changePercent,
    required this.lastUpdated,
    required this.category,
  });
}
