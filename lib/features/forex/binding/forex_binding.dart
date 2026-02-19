import 'package:get/get.dart';
import '../../../core/services/sbi_forex_service.dart';
import '../controller/forex_controller.dart';

class ForexBinding extends Bindings {
  @override
  void dependencies() {
    // Register SBI Forex Service as singleton if not already registered
    if (!Get.isRegistered<SbiForexService>()) {
      Get.lazyPut<SbiForexService>(() => SbiForexService(), fenix: true);
    }

    // Register Forex Controller
    Get.lazyPut<ForexController>(() => ForexController());
  }
}
