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
    
    // Initial sync
    if (sheetsService.lmeWarehouseData.isNotEmpty) {
      lmeData.value = sheetsService.lmeWarehouseData;
    }
    if (sheetsService.warehouseDate.value.isNotEmpty) {
      warehouseDate.value = sheetsService.warehouseDate.value;
    }
    
    // Start auto-refresh
    _startAutoRefresh(); // Call the new method
    
    // Listen to loading state
    ever(sheetsService.isLoading, (loading) {
      if (loading) {
        if (lmeData.isEmpty) {
          isLoading.value = true;
        }
      } else {
        isLoading.value = false;
      }
    });
  }

  @override
  void onClose() {
    _refreshTimer?.cancel(); // Cancel the timer when the controller is closed
    super.onClose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => refreshData()); // Use refreshData
  }

  Future<void> refreshData() async {
    final sheetsService = Get.find<GoogleSheetsService>();
    await sheetsService.fetchFuturesData();
  }
}
