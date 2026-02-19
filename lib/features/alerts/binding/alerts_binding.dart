import 'package:get/get.dart';
import '../controller/alerts_controller.dart';

class AlertsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AlertsController>(() => AlertsController());
  }
}
