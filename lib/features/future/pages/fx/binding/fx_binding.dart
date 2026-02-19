import 'package:get/get.dart';
import '../controller/fx_controller.dart';

class FxBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FxController>(() => FxController());
  }
}
