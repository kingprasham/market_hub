import 'package:get/get.dart';
import '../controller/tin_detail_controller.dart';

class TinDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TinDetailController>(() => TinDetailController());
  }
}
