import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/metal_detail_template.dart';
import '../controller/copper_detail_controller.dart';

class CopperDetailPage extends StatelessWidget {
  const CopperDetailPage({super.key});

  CopperDetailController get controller => Get.put(CopperDetailController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => MetalDetailTemplate(
      title: 'Copper Prices',
      metalName: 'Copper Spot Prices',
      symbol: 'Cu',
      gradientColors: const [Color(0xFFB87333), Color(0xFF8B5A2B)],
      accentColor: Colors.orange[800]!,
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
