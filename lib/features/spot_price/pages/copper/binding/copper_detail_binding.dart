import 'package:get/get.dart';
import '../controller/copper_detail_controller.dart';

class CopperDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CopperDetailController>(() => CopperDetailController());
  }
}
