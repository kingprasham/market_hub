import 'package:get/get.dart';
import '../controller/forgot_pin_controller.dart';

class ForgotPinBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForgotPinController>(() => ForgotPinController(), fenix: true);
  }
}
