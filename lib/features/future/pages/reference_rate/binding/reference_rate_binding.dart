import 'package:get/get.dart';
import '../controller/reference_rate_controller.dart';

class ReferenceRateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReferenceRateController>(() => ReferenceRateController());
  }
}
