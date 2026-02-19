import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/metal_detail_template.dart';
import '../controller/nickel_detail_controller.dart';

class NickelDetailPage extends StatelessWidget {
  const NickelDetailPage({super.key});

  NickelDetailController get controller => Get.put(NickelDetailController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => MetalDetailTemplate(
      title: 'Nickel Prices',
      metalName: 'Nickel Spot Prices',
      symbol: 'Ni',
      gradientColors: const [Color(0xFF3F51B5), Color(0xFF303F9F)],
      accentColor: Colors.indigo,
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
