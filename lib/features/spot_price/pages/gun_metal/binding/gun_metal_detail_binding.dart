import 'package:get/get.dart';
import '../controller/gun_metal_detail_controller.dart';

class GunMetalDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GunMetalDetailController>(() => GunMetalDetailController());
  }
}
