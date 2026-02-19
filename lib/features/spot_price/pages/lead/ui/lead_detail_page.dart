import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/metal_detail_template.dart';
import '../controller/lead_detail_controller.dart';

class LeadDetailPage extends StatelessWidget {
  const LeadDetailPage({super.key});

  LeadDetailController get controller => Get.put(LeadDetailController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => MetalDetailTemplate(
      title: 'Lead Prices',
      metalName: 'Lead Spot Prices',
      symbol: 'Pb',
      gradientColors: const [Color(0xFF607D8B), Color(0xFF455A64)],
      accentColor: Colors.grey[600]!,
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
