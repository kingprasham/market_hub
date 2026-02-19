import 'package:get/get.dart';
import '../../../controller/generic_metal_controller.dart';

class ZincDetailController extends GenericMetalController {
  ZincDetailController() : super(metalName: 'Zinc');

  // Legacy accessor for backward compatibility with existing UI
  List<MetalPrice> get zincPrices => prices;
}

// Legacy class for backward compatibility
typedef ZincPrice = MetalPrice;
