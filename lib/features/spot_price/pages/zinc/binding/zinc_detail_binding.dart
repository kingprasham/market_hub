import 'package:get/get.dart';
import '../controller/zinc_detail_controller.dart';

class ZincDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ZincDetailController>(() => ZincDetailController());
  }
}
