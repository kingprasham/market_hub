import 'package:get/get.dart';
import '../controller/nickel_detail_controller.dart';

class NickelDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NickelDetailController>(() => NickelDetailController());
  }
}
