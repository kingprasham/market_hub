import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/constants/text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/fx_controller.dart';

class FxPage extends StatelessWidget {
  const FxPage({super.key});

  FxController get controller => Get.put(FxController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const ShimmerListLoader();
        }

        // Show error state
        if (controller.hasError.value || controller.currencyPairs.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.refreshData,
            color: ColorConstants.primaryOrange,
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
                            : 'Unable to fetch FX data.\nCheck your internet connection.',
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
                          backgroundColor: ColorConstants.primaryOrange,
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
              // Market Status Header (Removed to match China/London style)


              // Filter Options
              SliverToBoxAdapter(
                child: _buildFilterOptions(),
              ),

              // Currency Pairs List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: Obx(() {
                  final pairs = controller.filteredPairs;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final pair = pairs[index];
                        return _buildCompactCurrencyRow(pair, index, pairs.length);
                      },
                      childCount: pairs.length,
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
        selectedColor: ColorConstants.primaryOrange.withOpacity(0.1),
        labelStyle: TextStyles.bodySmall.copyWith(
          color: isSelected ? ColorConstants.primaryOrange : ColorConstants.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? ColorConstants.primaryOrange : ColorConstants.borderColor,
        ),
      ),
    );
  }

  Widget _buildCompactCurrencyRow(dynamic pair, int index, int totalCount) {
    final isPositive = pair.change >= 0;

    return Obx(() {
      // Observe watchlistUpdateTrigger to rebuild when watchlist changes
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
                  colors: _getCurrencyGradient(pair.pair),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  pair.pair.substring(0, 3),
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
                    pair.pair,
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
                          'FX',
                          style: TextStyles.caption.copyWith(
                            color: ColorConstants.primaryOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
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
                  pair.rate.toStringAsFixed(4),
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
                      '${pair.change.abs().toStringAsFixed(4)} (${pair.changePercent.abs().toStringAsFixed(2)}%)',
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

  List<Color> _getCurrencyGradient(String pair) {
    if (pair.contains('USD')) return [Color(0xFF2E7D32), Color(0xFF1B5E20)];
    if (pair.contains('EUR')) return [Color(0xFF1565C0), Color(0xFF0D47A1)];
    if (pair.contains('GBP')) return [Color(0xFF6A1B9A), Color(0xFF4A148C)];
    if (pair.contains('JPY')) return [Color(0xFFC62828), Color(0xFFB71C1C)];
    if (pair.contains('CNY')) return [Color(0xFFD32F2F), Color(0xFFC62828)];
    return [ColorConstants.primaryOrange, ColorConstants.primaryOrange.withOpacity(0.7)];
  }
}
