import 'package:get/get.dart';
import '../../../../../core/services/google_sheets_service.dart';

class SettlementController extends GetxController {
  final isLoading = false.obs;
  final settlementData = <SettlementModel>[].obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

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
      isLoading.value = loading;
    });
  }

  Future<void> refreshData() async {
    final sheetsService = Get.find<GoogleSheetsService>();
    await sheetsService.fetchFuturesData();
  }
}
