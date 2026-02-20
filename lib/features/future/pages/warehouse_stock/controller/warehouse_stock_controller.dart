import 'package:get/get.dart';
import '../../../../../core/services/google_sheets_service.dart';

class WarehouseStockController extends GetxController {
  final isLoading = false.obs;
  final lmeData = <LmeWarehouseModel>[].obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final sheetsService = Get.find<GoogleSheetsService>();
    
    // Bind the data
    lmeData.bindStream(sheetsService.lmeWarehouseData.stream);
    
    // Initial sync
    if (sheetsService.lmeWarehouseData.isNotEmpty) {
      lmeData.value = sheetsService.lmeWarehouseData;
    }
    
    // Listen to loading state
    ever(sheetsService.isLoading, (loading) {
      isLoading.value = loading;
    });
  }

  Future<void> refreshData() async {
    final sheetsService = Get.find<GoogleSheetsService>();
    await sheetsService.fetchFuturesData();
  }
}
