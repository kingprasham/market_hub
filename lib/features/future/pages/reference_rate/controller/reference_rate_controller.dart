import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/services/external_apis/fx_rates_service.dart';
import '../../../../../core/services/external_data_service.dart';
import '../../../../../core/services/watchlist_service.dart';
import '../../../../../data/models/watchlist/watchlist_item_model.dart';
import '../../../../../data/models/forex/forex_sheet_data.dart';
import '../../../../../core/utils/helpers.dart';

/// Reference Rate Controller
/// Fetches SBI TT Rates and RBI Reference Rates
class ReferenceRateController extends GetxController {
  final isLoading = false.obs;
  final referenceRates = <ReferenceRate>[].obs;
  final selectedFilter = 'All'.obs;
  final filterOptions = ['All', 'SBI TT Rates', 'RBI Reference'];
  final dataSource = 'Loading...'.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  WatchlistService? _watchlistService;
  Timer? _refreshTimer;
  final watchlistUpdateTrigger = 0.obs;
  
  final sbiTableRows = <SbiTableRow>[].obs;
  final rbiTableRows = <RbiTableRow>[].obs;
  
  // Filtered list based on selected filter
  List<ReferenceRate> get filteredRates {
    if (selectedFilter.value == 'All') {
      return referenceRates;
    }
    return referenceRates.where((rate) => rate.source == selectedFilter.value).toList();
  }

  FxRatesService? _fxRatesService;
  ExternalDataService? _externalDataService;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    loadData();
    _startAutoRefresh();
  }

  void _initializeServices() {
    try {
      _externalDataService = Get.find<ExternalDataService>();
    } catch (e) {
      debugPrint('ExternalDataService not found');
    }

    try {
      _fxRatesService = Get.find<FxRatesService>();
    } catch (e) {
      debugPrint('FxRatesService not found');
    }

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

  List<String> get watchlistIds {
    if (_watchlistService == null) return [];
    return _watchlistService!.watchlistItems.map((item) => item.id).toList();
  }

  void _startAutoRefresh() {
    // Refresh every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      loadData();
    });
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      
      final List<ReferenceRate> allRates = [];
      String source = '';
      final now = DateTime.now();
      
      // Fetch SBI TT Rates
      // Fetch Google Sheets Data (New Priority)
      if (_externalDataService != null) {
        final sheetData = await _externalDataService!.fetchForexFromSheet();
        
        if (sheetData != null && (sheetData.sbiRows.isNotEmpty || sheetData.rbiRows.isNotEmpty)) {
          sbiTableRows.value = sheetData.sbiRows;
          rbiTableRows.value = sheetData.rbiRows;
          
          // Populate legacy list for compatibility or summary
          if (sheetData.sbiRows.isNotEmpty) {
            final latestCtx = sheetData.sbiRows.first; // Assuming sorted descending or first is latest
            // Actually csv parsing goes 2->end. If date is ascending, last is latest.
            // Let's sort them to be safe or check csv order.
            // CSV is usually chronological. Let's assume last is latest or sort.
            
            // For now, let's just use the table rows in the UI.
          }

          source = 'Google Sheets (Sync)';
        } else {
          // Fallback
          // ... (keep existing fallback logic for now if needed, or clear)
        }
      }
      
      if (sbiTableRows.isNotEmpty || rbiTableRows.isNotEmpty || allRates.isNotEmpty) {
        referenceRates.value = allRates;
        dataSource.value = source.isEmpty ? 'Live Data' : source;
        hasError.value = false;
        errorMessage.value = '';
      } else {
        hasError.value = true;
        errorMessage.value = 'Reference Rates Unavailable.\n'
            'Could not fetch data from Google Sheets.';
        referenceRates.value = [];
        dataSource.value = 'No Data Available';
      }
    } catch (e) {
      debugPrint('Error loading reference rates: $e');
      hasError.value = true;
      errorMessage.value = 'Error: $e';
      referenceRates.value = [];
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
    if (_watchlistService == null) return;
    
    final rate = referenceRates.firstWhereOrNull((r) => r.id == id);
    if (rate == null) return;

    if (_watchlistService!.isInWatchlist(id)) {
      _watchlistService!.removeFromWatchlist(id);
      Helpers.showSuccess('Removed from watchlist');
    } else {
      _watchlistService!.addToWatchlist(
        WatchlistItemModel(
          id: id,
          symbol: rate.name, // Using name as symbol for Reference Rates
          name: rate.name,
          type: 'ReferenceRate',
          price: rate.rate,
          change: rate.change,
          changePercent: rate.changePercent,
          lastUpdated: rate.lastUpdated,
          exchange: rate.source,
          itemType: 'ReferenceRate', currency: 'INR',
        ),
      );
      _watchlistService!.toggleStar(id);
      Helpers.showSuccess('Added to watchlist');
    }
    watchlistUpdateTrigger.value++;
  }
}

class ReferenceRate {
  final String id;
  final String name;
  final String source;
  final String type;
  final double rate;
  final double previousRate;
  final double change;
  final double changePercent;
  final DateTime lastUpdated;

  ReferenceRate({
    required this.id,
    required this.name,
    required this.source,
    required this.type,
    required this.rate,
    required this.previousRate,
    required this.change,
    required this.changePercent,
    required this.lastUpdated,
  });
}
