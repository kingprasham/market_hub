import 'package:get/get.dart';
import '../controller/aluminium_detail_controller.dart';

class AluminiumDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AluminiumDetailController>(() => AluminiumDetailController());
  }
}
