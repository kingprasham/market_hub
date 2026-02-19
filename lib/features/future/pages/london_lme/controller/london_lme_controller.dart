import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/services/watchlist_service.dart';
import '../../../../../core/services/scraper/fx678_scraper_service.dart';
import '../../../../../data/models/watchlist/watchlist_item_model.dart';
import '../../../../../core/utils/helpers.dart';

/// LME Controller - Fetches real-time LME prices from Metals.Dev API
/// Data: Copper, Aluminum, Zinc, Lead, Nickel, Tin (Base Metals)
class LondonLMEController extends GetxController {
  final isLoading = false.obs;
  final metals = <LMEMetal>[].obs;
  final watchlistUpdateTrigger = 0.obs;
  final dataSource = 'Loading...'.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final selectedFilter = 'All'.obs;
  
  final filterOptions = ['All', 'Base Metals'];

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
    // Refresh every 30 minutes to conserve API quota (100 requests/month free)
    _refreshTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      loadData();
    });
  }

  // Filtered metals based on selected filter
  List<LMEMetal> get filteredMetals {
    if (selectedFilter.value == 'All') {
      return metals;
    }
    return metals.where((m) => m.category == selectedFilter.value).toList();
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

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      
      final scraper = Get.put(FX678ScraperService());
      
      // Fetch LME data from scraper
      final scrapedData = await scraper.fetchLME();
      
      if (scrapedData.isEmpty) {
        hasError.value = true;
        errorMessage.value = 'Failed to fetch LME prices.\nSource unavailable or network issue.';
        metals.value = [];
        dataSource.value = 'No Data';
        return;
      }
      
      final now = DateTime.now();
      final List<LMEMetal> lmeMetals = [];
      
      for (final item in scrapedData) {
        lmeMetals.add(LMEMetal(
          id: 'lme_${item.symbol.toLowerCase()}',
          symbol: item.symbol,
          name: item.name,
          contract: '3-Month', // Default for LME usually
          lastPrice: item.price,
          high: item.high, 
          low: item.low,  
          change: item.change,
          changePercent: item.changePercent,
          lastUpdated: now,
          category: 'Base Metals',
        ));
      }
      
      metals.value = lmeMetals;
      dataSource.value = 'FX678 (Scraped)';
      debugPrint('✅ Loaded ${lmeMetals.length} LME metals from FX678 Scraper');
      
    } catch (e) {
      debugPrint('Error loading LME data: $e');
      hasError.value = true;
      errorMessage.value = 'Error: $e';
      metals.value = [];
      dataSource.value = 'Error';
    } finally {
      isLoading.value = false;
    }
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
          price: metal.lastPrice,
          change: metal.change,
          changePercent: metal.changePercent,
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
  final double lastPrice;
  final double high;
  final double low;
  final double change;
  final double changePercent;
  final DateTime lastUpdated;
  final String category; // Base Metals, Precious

  LMEMetal({
    required this.id,
    required this.symbol,
    required this.name,
    required this.contract,
    required this.lastPrice,
    required this.high,
    required this.low,
    required this.change,
    required this.changePercent,
    required this.lastUpdated,
    required this.category,
  });
}
