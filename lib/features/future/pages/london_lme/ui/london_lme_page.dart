import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/constants/text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/london_lme_controller.dart';

class LondonLMEPage extends StatelessWidget {
  const LondonLMEPage({super.key});

  LondonLMEController get controller => Get.put(LondonLMEController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const ShimmerListLoader();
        }

        // Show error state
        if (controller.hasError.value || controller.metals.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.refreshData,
            color: ColorConstants.primaryBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No Data Available',
                        style: TextStyles.h5.copyWith(color: ColorConstants.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          controller.errorMessage.value.isNotEmpty 
                            ? controller.errorMessage.value
                            : 'Unable to fetch LME data.\nCheck your API key and internet connection.',
                          textAlign: TextAlign.center,
                          style: TextStyles.bodySmall.copyWith(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: controller.refreshData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Data Source: ${controller.dataSource.value}',
                        style: TextStyles.caption.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: ColorConstants.primaryBlue,
          child: CustomScrollView(
            slivers: [
              // Market Status Header


              // Filter Options
              SliverToBoxAdapter(
                child: _buildFilterOptions(),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: Obx(() {
                  final metalsList = controller.filteredMetals;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final metal = metalsList[index];
                        return _buildCompactMetalRow(metal, index, metalsList.length);
                      },
                      childCount: metalsList.length,
                    ),
                  );
                }),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      }),
    );
  }



  Widget _buildFilterOptions() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() => ListView(
        scrollDirection: Axis.horizontal,
        children: controller.filterOptions.map((filter) {
          final isSelected = controller.selectedFilter.value == filter;
          return _buildFilterChip(filter, isSelected);
        }).toList(),
      )),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (value) {
          controller.setFilter(label);
        },
        backgroundColor: Colors.white,
        selectedColor: ColorConstants.primaryBlue.withOpacity(0.1),
        labelStyle: TextStyles.bodySmall.copyWith(
          color: isSelected ? ColorConstants.primaryBlue : ColorConstants.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? ColorConstants.primaryBlue : ColorConstants.borderColor,
        ),
      ),
    );
  }

  Widget _buildCompactMetalRow(dynamic metal, int index, int totalCount) {
    final isPositive = metal.change >= 0;

    return Obx(() {
      controller.watchlistUpdateTrigger.value;
      
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: ColorConstants.borderColor.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 1. Symbol/Icon (Compact)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getMetalGradient(metal.symbol),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  metal.symbol.substring(0, 2),
                  style: TextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 2. Name & Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metal.name,
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: ColorConstants.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'LME',
                          style: TextStyles.caption.copyWith(
                            color: ColorConstants.primaryOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        metal.contract,
                        style: TextStyles.caption.copyWith(
                          color: ColorConstants.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Price & Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${metal.lastPrice.toStringAsFixed(2)}',
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: isPositive ? ColorConstants.positiveGreen : ColorConstants.negativeRed,
                      size: 16,
                    ),
                    Text(
                      '${metal.change.abs().toStringAsFixed(2)} (${metal.changePercent.abs().toStringAsFixed(2)}%)',
                      style: TextStyles.caption.copyWith(
                        color: isPositive ? ColorConstants.positiveGreen : ColorConstants.negativeRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  List<Color> _getMetalGradient(String symbol) {
    if (symbol.contains('CU')) return [Color(0xFFB87333), Color(0xFF8B5A2B)];
    if (symbol.contains('AL')) return [Color(0xFF9E9E9E), Color(0xFF616161)];
    if (symbol.contains('ZN')) return [Color(0xFF00BCD4), Color(0xFF0097A7)];
    if (symbol.contains('NI')) return [Color(0xFF3F51B5), Color(0xFF303F9F)];
    if (symbol.contains('PB')) return [Color(0xFF607D8B), Color(0xFF455A64)];
    if (symbol.contains('SN')) return [Color(0xFF795548), Color(0xFF5D4037)];
    return [ColorConstants.primaryBlue, ColorConstants.primaryBlue.withOpacity(0.7)];
  }
}
