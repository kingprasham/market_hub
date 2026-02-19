import 'package:get/get.dart';
import '../../../controller/generic_metal_controller.dart';

class GunMetalDetailController extends GenericMetalController {
  GunMetalDetailController() : super(metalName: 'Gun Metal');

  // Legacy accessor for backward compatibility with existing UI
  List<MetalPrice> get gunMetalPrices => prices;
}

// Legacy class for backward compatibility
typedef GunMetalPrice = MetalPrice;
