import 'package:get/get.dart';
import '../../../controller/generic_metal_controller.dart';

class AluminiumDetailController extends GenericMetalController {
  AluminiumDetailController() : super(metalName: 'Aluminium');

  // Legacy accessor for backward compatibility with existing UI
  List<MetalPrice> get aluminiumPrices => prices;
}

// Legacy class for backward compatibility
typedef AluminiumPrice = MetalPrice;
