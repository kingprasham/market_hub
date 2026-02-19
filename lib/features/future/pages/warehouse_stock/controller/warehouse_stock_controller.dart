import 'package:get/get.dart';
import '../../../../../core/services/scraper/westmetall_scraper_service.dart';

/// Warehouse Stock Controller - No free real-time API available
/// LME warehouse stock data requires paid subscription
class WarehouseStockController extends GetxController {
  final isLoading = false.obs;
  final warehouseStocks = <WarehouseStock>[].obs;
  final watchlistIds = <String>[].obs;
  final dataSource = 'No Data'.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      
      final scraper = Get.put(WestmetallScraperService());
      final wmData = await scraper.fetchData();
      final scrapedData = wmData.stocks;
      
      if (scrapedData.isEmpty) {
        hasError.value = true;
        errorMessage.value = 'Failed to fetch warehouse data.\nSource unavailable or network issue.';
        warehouseStocks.value = [];
        dataSource.value = 'No Data';
        return;
      }

      final List<WarehouseStock> stocks = [];
      final now = DateTime.now();

      for (final item in scrapedData) {
        if (item.value > 0) {
          stocks.add(WarehouseStock(
            id: 'stock_${item.symbol.toLowerCase()}',
            metal: item.name,
            symbol: item.symbol,
            location: 'LME Global',
            stockLevel: item.value.toInt(),
            unit: 'tonnes',
            previousStock: (item.value - item.change).toInt(), // Recover previous from change
            change: item.change.toInt(),
            changePercent: 0, // Westmetall might not provide pct, calculate if needed? (item.change/prev)*100
            lastUpdated: now,
          ));
        }
      }
      
      if (stocks.isEmpty) {
         // Some LME pages might hide stock column
         hasError.value = true;
         errorMessage.value = 'Warehouse details not currently published available on FX678.';
      }
      
      warehouseStocks.value = stocks;
      dataSource.value = 'FX678 (Scraped)';
      
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error: $e';
      warehouseStocks.value = [];
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

class WarehouseStock {
  final String id;
  final String metal;
  final String symbol;
  final String location;
  final int stockLevel;
  final String unit;
  final int previousStock;
  final int change;
  final double changePercent;
  final DateTime lastUpdated;

  WarehouseStock({
    required this.id,
    required this.metal,
    required this.symbol,
    required this.location,
    required this.stockLevel,
    required this.unit,
    required this.previousStock,
    required this.change,
    required this.changePercent,
    required this.lastUpdated,
  });
}
