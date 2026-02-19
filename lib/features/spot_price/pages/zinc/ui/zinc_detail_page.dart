import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/metal_detail_template.dart';
import '../controller/zinc_detail_controller.dart';

class ZincDetailPage extends StatelessWidget {
  const ZincDetailPage({super.key});

  ZincDetailController get controller => Get.put(ZincDetailController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => MetalDetailTemplate(
      title: 'Zinc Prices',
      metalName: 'Zinc Spot Prices',
      symbol: 'Zn',
      gradientColors: const [Color(0xFF00BCD4), Color(0xFF0097A7)],
      accentColor: Colors.cyan,
      isLoading: controller.isLoading.value,
      locations: controller.locations,
      types: controller.types,
      selectedLocation: controller.selectedLocation,
      selectedType: controller.selectedType,
      filteredPrices: controller.filteredPrices,
      watchlistIdsGetter: () => controller.watchlistIds,
      watchlistUpdateTrigger: controller.watchlistUpdateTrigger,
      onRefresh: controller.refreshData,
      onToggleWatchlist: controller.toggleWatchlist,
    ));
  }
}
