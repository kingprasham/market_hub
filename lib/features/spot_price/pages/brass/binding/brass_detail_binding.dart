import 'package:get/get.dart';
import '../controller/brass_detail_controller.dart';

class BrassDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BrassDetailController>(() => BrassDetailController());
  }
}
