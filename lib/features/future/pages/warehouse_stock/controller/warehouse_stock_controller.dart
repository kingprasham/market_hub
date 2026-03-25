import 'dart:async';
import 'package:get/get.dart';
import '../../../../../core/services/google_sheets_service.dart';

class WarehouseStockController extends GetxController {
  final isLoading = false.obs;
  final lmeData = <LmeWarehouseModel>[].obs;
  final warehouseDate = ''.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    final sheetsService = Get.find<GoogleSheetsService>();
    
    // Bind the data
    lmeData.bindStream(sheetsService.lmeWarehouseData.stream);
    warehouseDate.bindStream(sheetsService.warehouseDate.stream);
    
    // Parent FutureController handles periodic refreshes for all sub-tabs,
    // and GoogleSheetsService has its own global refresh timer.
    // Local timer is redundant and causes overlapping requests.
    
    // Initial sync
    if (sheetsService.lmeWarehouseData.isNotEmpty) {
      lmeData.value = sheetsService.lmeWarehouseData;
    }
    if (sheetsService.warehouseDate.value.isNotEmpty) {
      warehouseDate.value = sheetsService.warehouseDate.value;
    }
    
    
    // Listen to loading state
    ever(sheetsService.isLoading, (loading) {
      isLoading.value = loading;
    });
  }

  @override
  void onClose() {
    _refreshTimer?.cancel(); // Cancel the timer when the controller is closed
    super.onClose();
  }

  // Removed redundant _startAutoRefresh timer

  Future<void> refreshData() async {
    final sheetsService = Get.find<GoogleSheetsService>();
    await sheetsService.fetchFuturesData();
  }
}
