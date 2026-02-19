import 'package:get/get.dart';
import '../controller/settlement_controller.dart';

class SettlementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettlementController>(() => SettlementController());
  }
}
