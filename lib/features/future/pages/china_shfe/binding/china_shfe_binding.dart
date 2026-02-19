import 'package:get/get.dart';
import '../controller/china_shfe_controller.dart';

class ChinaSHFEBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChinaSHFEController>(() => ChinaSHFEController());
  }
}
