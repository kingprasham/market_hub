import 'package:get/get.dart';
import '../../../controller/generic_metal_controller.dart';

class CopperDetailController extends GenericMetalController {
  CopperDetailController() : super(metalName: 'Copper');

  // Legacy accessor for backward compatibility with existing UI
  List<MetalPrice> get copperPrices => prices;
}

// Legacy class for backward compatibility
// The MetalPrice class from GenericMetalController should be used instead
typedef CopperPrice = MetalPrice;
