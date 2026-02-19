import 'package:get/get.dart';
import '../../../controller/generic_metal_controller.dart';

class LeadDetailController extends GenericMetalController {
  LeadDetailController() : super(metalName: 'Lead');

  // Legacy accessor for backward compatibility with existing UI
  List<MetalPrice> get leadPrices => prices;
}

// Legacy class for backward compatibility
typedef LeadPrice = MetalPrice;
