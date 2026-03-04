import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/constants/text_styles.dart';
import '../../../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/fx_controller.dart';
import '../../../../../shared/widgets/common/metal_detail_dialog.dart';
import 'package:intl/intl.dart';

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

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: ColorConstants.primaryBlue,
          child: CustomScrollView(
            slivers: [
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
    if (controller.filterOptions.isEmpty) return const SizedBox.shrink();
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
    final hasData = pair.rate != null;
    final isPositive = (pair.change ?? 0) >= 0;

    return Obx(() {
      controller.watchlistUpdateTrigger.value;

      return InkWell(
          onTap: () {
            if (!hasData) return;
            MetalDetailDialog.show(
              Get.context!,
              title: pair.pair,
              lastPrice: pair.rate!.toStringAsFixed(4),
              change: '${pair.change! > 0 ? '+' : ''}${pair.change!.toStringAsFixed(4)} (${pair.changePercent!.toStringAsFixed(2)}%)',
              isPositive: isPositive,
              lastTrade: DateFormat('dd MMM hh:mma').format(pair.lastUpdated ?? DateTime.now()).toLowerCase(),
            );
          },
          child: Container(
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
        child: Column(
          children: [
            Row(
              children: [
                // 1. Symbol/Icon
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
                      pair.pair.length >= 3 ? pair.pair.substring(0, 3) : pair.pair,
                      style: TextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Name & Badge
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
                ),

                // 3. Rate & Change
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hasData ? pair.rate!.toStringAsFixed(4) : 'N/A',
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: hasData ? null : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (hasData)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                            color: isPositive ? ColorConstants.positiveGreen : ColorConstants.negativeRed,
                            size: 16,
                          ),
                          Text(
                            '${pair.change!.abs().toStringAsFixed(4)} (${pair.changePercent!.abs().toStringAsFixed(2)}%)',
                            style: TextStyles.caption.copyWith(
                              color: isPositive ? ColorConstants.positiveGreen : ColorConstants.negativeRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      Text('—', style: TextStyles.caption.copyWith(color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
          ],
        ),
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

  Widget _buildHighLowGrid(dynamic pair) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ColorConstants.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoItem('High', pair.high != null ? pair.high!.toStringAsFixed(4) : '—'),
          _buildInfoItem('Low', pair.low != null ? pair.low!.toStringAsFixed(4) : '—'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.caption.copyWith(
            fontSize: 9,
            color: ColorConstants.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyles.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: ColorConstants.textPrimary,
          ),
        ),
      ],
    );
  }
}
