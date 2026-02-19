import 'package:get/get.dart';
import '../../../../../core/services/scraper/westmetall_scraper_service.dart';
import '../../../../../core/services/scraper/fx678_scraper_service.dart';

/// Settlement Controller - No free real-time API available
/// LME settlement data requires paid subscription
class SettlementController extends GetxController {
  final isLoading = false.obs;
  final settlements = <Settlement>[].obs;
  final watchlistIds = <String>[].obs;
  final dataSource = 'No Data'.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  
  // Filtering
  final selectedExchange = 'All'.obs;
  
  List<Settlement> get filteredSettlements {
    if (selectedExchange.value == 'All') return settlements;
    return settlements.where((s) => s.exchange == selectedExchange.value).toList();
  }

  void setExchange(String exchange) {
    selectedExchange.value = exchange;
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      
      final westmetallScraper = Get.put(WestmetallScraperService());
      final fx678Scraper = Get.put(FX678ScraperService());
      
      // 1. Fetch LME from Westmetall (Reference)
      final wmData = await westmetallScraper.fetchData();
      final lmeData = wmData.settlements;
      
      // 2. Fetch COMEX from Sina/FX678
      final comexData = await fx678Scraper.fetchCOMEX();
      
      // 3. Fetch SHFE from FX678
      final shfeData = await fx678Scraper.fetchSHFE();

      final List<Settlement> items = [];
      final now = DateTime.now();
      
      // Add LME
      for (final item in lmeData) {
        if (item.value > 0) {
          items.add(Settlement(
            id: 'settle_lme_${item.symbol.toLowerCase()}',
            metal: item.name,
            symbol: item.symbol,
            contract: 'Cash',
            exchange: 'LME',
            settlementPrice: item.value,
            previousSettlement: 0,
            change: 0,
            changePercent: 0,
            settlementDate: now,
            expiryDate: now.add(const Duration(days: 2)),
            lastUpdated: now,
          ));
        }
      }
      
      // Add COMEX
      for (final item in comexData) {
        items.add(Settlement(
          id: 'settle_comex_${item.symbol.toLowerCase()}',
          metal: item.name,
          symbol: item.symbol,
          contract: 'Front Month',
          exchange: 'COMEX',
          settlementPrice: item.price, // Use last price as settlement proxy
          previousSettlement: 0, 
          change: item.change,
          changePercent: item.changePercent,
          settlementDate: now,
          expiryDate: now.add(const Duration(days: 30)),
          lastUpdated: now,
        ));
      }
      
      // Add SHFE
      for (final item in shfeData) {
        // SHFE scraping via FX678 gives price. Use as settlement proxy.
        items.add(Settlement(
          id: 'settle_shfe_${item.symbol.toLowerCase()}',
          metal: item.name,
          symbol: item.symbol,
          contract: 'Spot',
          exchange: 'SHFE',
          settlementPrice: item.price,
          previousSettlement: 0,
          change: item.change,
          changePercent: item.changePercent,
          settlementDate: now,
          expiryDate: now.add(const Duration(days: 1)),
          lastUpdated: now,
        ));
      }
      
      if (items.isEmpty) {
          hasError.value = true;
          errorMessage.value = 'Settlement data not available.';
          settlements.value = [];
          dataSource.value = 'No Data';
          return;
      }
      
      settlements.value = items;
      dataSource.value = 'Scraped (Multi-Source)';
      
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error: $e';
      settlements.value = [];
      dataSource.value = 'Error';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    await loadData();
  }

  void toggleWatchlist(String id) {
    if (watchlistIds.contains(id)) {
      watchlistIds.remove(id);
      Get.snackbar('Removed', 'Removed from watchlist',
        snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
    } else {
      watchlistIds.add(id);
      Get.snackbar('Added', 'Added to watchlist',
        snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
    }
  }
}

class Settlement {
  final String id;
  final String metal;
  final String symbol;
  final String contract;
  final String exchange;
  final double settlementPrice;
  final double previousSettlement;
  final double change;
  final double changePercent;
  final DateTime settlementDate;
  final DateTime expiryDate;
  final DateTime lastUpdated;

  Settlement({
    required this.id,
    required this.metal,
    required this.symbol,
    required this.contract,
    required this.exchange,
    required this.settlementPrice,
    required this.previousSettlement,
    required this.change,
    required this.changePercent,
    required this.settlementDate,
    required this.expiryDate,
    required this.lastUpdated,
  });
}
