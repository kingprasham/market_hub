import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/metal_detail_template.dart';
import '../controller/tin_detail_controller.dart';

class TinDetailPage extends StatelessWidget {
  const TinDetailPage({super.key});

  TinDetailController get controller => Get.put(TinDetailController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => MetalDetailTemplate(
      title: 'Tin Prices',
      metalName: 'Tin Spot Prices',
      symbol: 'Sn',
      gradientColors: const [Color(0xFF795548), Color(0xFF5D4037)],
      accentColor: Colors.brown,
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
