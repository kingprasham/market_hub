import 'package:get/get.dart';
import '../../../controller/generic_metal_controller.dart';

class TinDetailController extends GenericMetalController {
  TinDetailController() : super(metalName: 'Tin');

  // Legacy accessor for backward compatibility with existing UI
  List<MetalPrice> get tinPrices => prices;
}

// Legacy class for backward compatibility
typedef TinPrice = MetalPrice;
