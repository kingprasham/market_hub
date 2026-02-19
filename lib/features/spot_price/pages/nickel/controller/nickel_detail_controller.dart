import 'package:get/get.dart';
import '../../../controller/generic_metal_controller.dart';

class NickelDetailController extends GenericMetalController {
  NickelDetailController() : super(metalName: 'Nickel');

  // Legacy accessor for backward compatibility with existing UI
  List<MetalPrice> get nickelPrices => prices;
}

// Legacy class for backward compatibility
typedef NickelPrice = MetalPrice;
