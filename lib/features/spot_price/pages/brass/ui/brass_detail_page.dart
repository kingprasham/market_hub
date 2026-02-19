import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/metal_detail_template.dart';
import '../controller/brass_detail_controller.dart';

class BrassDetailPage extends StatelessWidget {
  const BrassDetailPage({super.key});

  BrassDetailController get controller => Get.put(BrassDetailController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => MetalDetailTemplate(
      title: 'Brass Prices',
      metalName: 'Brass Spot Prices',
      symbol: 'Br',
      gradientColors: const [Color(0xFFD4AF37), Color(0xFFC5A029)],
      accentColor: Colors.amber[700]!,
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
