import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/services/watchlist_service.dart';
import '../../../../../core/services/scraper/fx678_scraper_service.dart';
import '../../../../../core/services/external_apis/fx_rates_service.dart';
import '../../../../../data/models/watchlist/watchlist_item_model.dart';
import '../../../../../core/utils/helpers.dart';

/// SHFE Controller - Shows LME prices converted to CNY as market proxy
/// No free real-time SHFE API is available, so we use LME data with FX conversion
class ChinaSHFEController extends GetxController {
  final isLoading = false.obs;
  final metals = <SHFEMetal>[].obs;
  final watchlistUpdateTrigger = 0.obs;
  final dataSource = 'No Data'.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  // Filter logic
  final selectedFilter = 'All'.obs;
  final filterOptions = ['All', 'Base Metals', 'Precious', 'Ferrous', 'Energy', 'Chemicals'];

  List<SHFEMetal> get filteredMetals {
    if (selectedFilter.value == 'All') {
      return metals;
    }

    return metals.where((metal) {
      final symbol = metal.symbol.toUpperCase();
      switch (selectedFilter.value) {
        case 'Base Metals':
          return ['CU', 'AL', 'ZN', 'PB', 'NI', 'SN', 'AO'].any((s) => symbol.contains(s));
        case 'Precious':
          return ['AU', 'AG'].any((s) => symbol.contains(s));
        case 'Ferrous':
          return ['RB', 'HC', 'SS', 'I'].any((s) => symbol.startsWith(s)); // I for Iron Ore
        case 'Energy':
          return ['SC', 'FU', 'LU'].any((s) => symbol.startsWith(s));
        case 'Chemicals':
          return ['RU', 'NR', 'BU', 'SP', 'EG', 'EB'].any((s) => symbol.startsWith(s));
        default:
          return true;
      }
    }).toList();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  WatchlistService? _watchlistService;
  FxRatesService? _fxRatesService;

  @override
  void onInit() {
    super.onInit();
    _initService();
    loadData();
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
      _fxRatesService = Get.find<FxRatesService>();
    } catch (e) {
      debugPrint('FxRatesService not found: $e');
    }
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
      
      final scraper = Get.put(FX678ScraperService());
      
      // Fetch SHFE data from scraper
      final scrapedData = await scraper.fetchSHFE();
      
      if (scrapedData.isEmpty) {
        hasError.value = true;
        errorMessage.value = 'Failed to fetch market data.\nAccess to SHFE denied.';
        metals.value = [];
        dataSource.value = 'No Data';
        return;
      }
      
      final now = DateTime.now();
      final List<SHFEMetal> shfeMetals = [];
      
      for (final item in scrapedData) {
        shfeMetals.add(SHFEMetal(
          id: 'shfe_${item.symbol.toLowerCase()}',
          symbol: item.symbol,
          name: item.name,
          contract: 'Main Contract',
          lastPrice: item.price,
          high: item.high,
          low: item.low,
          change: item.change,
          changePercent: item.changePercent,
          lastUpdated: now,
        ));
      }
      
      metals.value = shfeMetals;
      dataSource.value = 'SHFE (Live)';
      debugPrint('✅ Loaded ${shfeMetals.length} SHFE metals from FX678 Scraper');
      
    } catch (e) {
      debugPrint('Error loading SHFE data: $e');
      hasError.value = true;
      errorMessage.value = 'Error: $e';
      metals.value = [];
      dataSource.value = 'Error';
    } finally {
      isLoading.value = false;
    }
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
      final item = WatchlistItemModel.fromFuture(
        symbol: metal.symbol,
        name: metal.name,
        exchange: 'SHFE',
        price: metal.lastPrice,
        change: metal.change,
        changePercent: metal.changePercent,
        currency: 'CNY',
      );
      _watchlistService!.addToWatchlist(item.copyWith(id: id));
      _watchlistService!.toggleStar(id);
      Helpers.showSuccess('Added to watchlist');
    }
  }
}


class SHFEMetal {
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

  SHFEMetal({
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
  });
}
