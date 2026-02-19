import 'package:get/get.dart';
import '../../../controller/generic_metal_controller.dart';

class BrassDetailController extends GenericMetalController {
  BrassDetailController() : super(metalName: 'Brass');

  // Legacy accessor for backward compatibility with existing UI
  List<MetalPrice> get brassPrices => prices;
}

// Legacy class for backward compatibility
typedef BrassPrice = MetalPrice;
