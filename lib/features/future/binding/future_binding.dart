import 'package:get/get.dart';
import '../controller/future_controller.dart';
import '../pages/london_lme/controller/london_lme_controller.dart';
import '../pages/china_shfe/controller/china_shfe_controller.dart';
import '../pages/us_comex/controller/us_comex_controller.dart';
import '../pages/fx/controller/fx_controller.dart';
import '../pages/reference_rate/controller/reference_rate_controller.dart';
import '../pages/warehouse_stock/controller/warehouse_stock_controller.dart';
import '../pages/settlement/controller/settlement_controller.dart';

class FutureBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<FutureController>(FutureController());
    Get.put<LondonLMEController>(LondonLMEController());
    Get.put<ChinaSHFEController>(ChinaSHFEController());
    Get.put<USComexController>(USComexController());
    Get.put<FxController>(FxController());
    Get.put<ReferenceRateController>(ReferenceRateController());
    Get.put<WarehouseStockController>(WarehouseStockController());
    Get.put<SettlementController>(SettlementController());
  }
}
