import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/services/watchlist_service.dart';
import '../../../../../core/services/scraper/fx678_scraper_service.dart';
import '../../../../../data/models/watchlist/watchlist_item_model.dart';
import '../../../../../core/utils/helpers.dart';

/// COMEX Controller - Fetches real-time COMEX prices from Metals.Dev API
/// Data: Gold, Silver, Platinum, Palladium (Precious) + Copper (Base)
class USComexController extends GetxController {
  final isLoading = false.obs;
  final metals = <ComexMetal>[].obs;
  final watchlistUpdateTrigger = 0.obs;
  final dataSource = 'Loading...'.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final selectedFilter = 'All'.obs;
  
  final filterOptions = ['All', 'Precious Metals', 'Base Metals'];

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
    // Refresh every 30 minutes to conserve API quota (100 requests/month free)
    _refreshTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      loadData();
    });
  }

  // Filtered metals based on selected filter
  List<ComexMetal> get filteredMetals {
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

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final scraper = Get.put(FX678ScraperService());
      
      // Fetch COMEX data from scraper
      final scrapedData = await scraper.fetchCOMEX();
      
      if (scrapedData.isEmpty) {
        hasError.value = true;
        errorMessage.value = 'Failed to fetch COMEX prices.\nSource unavailable or network issue.';
        metals.value = [];
        dataSource.value = 'No Data';
        return;
      }
      
      final now = DateTime.now();
      final List<ComexMetal> comexMetals = [];
      
      for (final item in scrapedData) {
        String category = 'Precious Metals';
        if (item.name.contains('Copper')) {
          category = 'Base Metals';
        }
        
        comexMetals.add(ComexMetal(
          id: 'comex_${item.symbol.toLowerCase()}',
          symbol: item.symbol,
          name: item.name,
          contract: 'Front Month',
          lastPrice: item.price,
          high: item.high,
          low: item.low,
          change: item.change,
          changePercent: item.changePercent,
          lastUpdated: now,
          category: category,
        ));
      }
      
      metals.value = comexMetals;
      dataSource.value = 'FX678 (Scraped)';
      debugPrint('✅ Loaded ${comexMetals.length} COMEX metals from FX678 Scraper');
      
    } catch (e) {
      debugPrint('Error loading COMEX data: $e');
      hasError.value = true;
      errorMessage.value = e.toString();
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
          exchange: 'COMEX',
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


class ComexMetal {
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
  final String category; // Precious Metals, Base Metals

  ComexMetal({
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
