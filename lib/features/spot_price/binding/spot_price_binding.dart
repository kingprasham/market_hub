import 'package:get/get.dart';
import '../controller/spot_price_controller.dart';
import '../pages/copper/controller/copper_detail_controller.dart';
import '../pages/brass/controller/brass_detail_controller.dart';
import '../pages/gun_metal/controller/gun_metal_detail_controller.dart';
import '../pages/lead/controller/lead_detail_controller.dart';
import '../pages/nickel/controller/nickel_detail_controller.dart';
import '../pages/tin/controller/tin_detail_controller.dart';
import '../pages/zinc/controller/zinc_detail_controller.dart';
import '../pages/aluminium/controller/aluminium_detail_controller.dart';

class SpotPriceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SpotPriceController>(() => SpotPriceController());
    Get.lazyPut<CopperDetailController>(() => CopperDetailController());
    Get.lazyPut<BrassDetailController>(() => BrassDetailController());
    Get.lazyPut<GunMetalDetailController>(() => GunMetalDetailController());
    Get.lazyPut<LeadDetailController>(() => LeadDetailController());
    Get.lazyPut<NickelDetailController>(() => NickelDetailController());
    Get.lazyPut<TinDetailController>(() => TinDetailController());
    Get.lazyPut<ZincDetailController>(() => ZincDetailController());
    Get.lazyPut<AluminiumDetailController>(() => AluminiumDetailController());
  }
}
