import 'dart:async';
import 'package:get/get.dart';
import '../../../../../core/services/google_sheets_service.dart';

class SettlementController extends GetxController {
  final isLoading = false.obs;
  final settlementData = <SettlementModel>[].obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
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
}
