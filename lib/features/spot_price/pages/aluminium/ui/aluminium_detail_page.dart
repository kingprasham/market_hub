import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/metal_detail_template.dart';
import '../controller/aluminium_detail_controller.dart';

class AluminiumDetailPage extends StatelessWidget {
  const AluminiumDetailPage({super.key});

  AluminiumDetailController get controller => Get.put(AluminiumDetailController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => MetalDetailTemplate(
      title: 'Aluminium Prices',
      metalName: 'Aluminium Spot Prices',
      symbol: 'Al',
      gradientColors: const [Color(0xFF9E9E9E), Color(0xFF616161)],
      accentColor: Colors.blueGrey,
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
