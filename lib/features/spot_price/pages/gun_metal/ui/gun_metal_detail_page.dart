import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/metal_detail_template.dart';
import '../controller/gun_metal_detail_controller.dart';

class GunMetalDetailPage extends StatelessWidget {
  const GunMetalDetailPage({super.key});

  GunMetalDetailController get controller => Get.put(GunMetalDetailController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => MetalDetailTemplate(
      title: 'Gun Metal Prices',
      metalName: 'Gun Metal Spot Prices',
      symbol: 'GM',
      gradientColors: const [Color(0xFF4A5568), Color(0xFF2D3748)],
      accentColor: Colors.blueGrey[700]!,
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
