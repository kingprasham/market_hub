import 'package:get/get.dart';
import '../controller/warehouse_stock_controller.dart';

class WarehouseStockBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WarehouseStockController>(() => WarehouseStockController());
  }
}
