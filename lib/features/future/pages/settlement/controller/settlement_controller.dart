import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../core/services/google_sheets_service.dart';
import '../../../../../core/services/admin_api_service.dart';
import '../../../../../data/models/market/historical_price_model.dart';

class SettlementController extends GetxController {
  final isLoading = false.obs;
  final settlementData = <SettlementModel>[].obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  
  // Historical Data for Charts
  final historicalData = <HistoricalPriceModel>[].obs;
  final isHistoricalLoading = false.obs;
  
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    final sheetsService = Get.find<GoogleSheetsService>();
    
    // Bind
    settlementData.bindStream(sheetsService.settlementData.stream);
    if (sheetsService.settlementData.isNotEmpty) {
      settlementData.value = sheetsService.settlementData;
    }
    
    ever(sheetsService.isLoading, (loading) {
      if (loading) {
        if (settlementData.isEmpty) {
          isLoading.value = true;
        }
      } else {
        isLoading.value = false;
      }
    });

    _startAutoRefresh(); // Start auto-refresh on init
  }

  @override
  void onClose() {
    _refreshTimer?.cancel(); // Cancel timer on close
    super.onClose();
  }

  Future<void> refreshData() async {
    final sheetsService = Get.find<GoogleSheetsService>();
    await sheetsService.fetchFuturesData();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => refreshData()); // Calls refreshData
  }

  /// Fetch historical data for a specific metal
  Future<void> fetchHistoricalPrices(String metal) async {
    isHistoricalLoading.value = true;
    historicalData.clear();
    
    try {
      final data = await AdminApiService.to.getHistoricalPrices(metal: metal);
      if (data.isNotEmpty) {
        // WestMetall returns data in descending order (newest first)
        // For charts, we usually want ascending order (oldest first)
        final parsed = data.map((json) => HistoricalPriceModel.fromJson(json)).toList();
        historicalData.value = parsed.reversed.toList();
      }
    } catch (e) {
      debugPrint('Error fetching historical prices for $metal: $e');
    } finally {
      isHistoricalLoading.value = false;
    }
  }
}
