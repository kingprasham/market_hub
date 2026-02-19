import 'package:get/get.dart';
import '../controller/london_lme_controller.dart';

class LondonLMEBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LondonLMEController>(() => LondonLMEController());
  }
}
