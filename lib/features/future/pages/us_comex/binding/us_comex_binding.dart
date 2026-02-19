import 'package:get/get.dart';
import '../controller/us_comex_controller.dart';

class USComexBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<USComexController>(() => USComexController());
  }
}
