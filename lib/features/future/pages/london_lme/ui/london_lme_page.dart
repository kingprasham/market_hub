import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/constants/text_styles.dart';
import '../../../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/london_lme_controller.dart';
import '../../../../../shared/widgets/common/metal_detail_dialog.dart';
import 'package:intl/intl.dart';

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

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: ColorConstants.primaryBlue,
          child: CustomScrollView(
            slivers: [
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
                        return _buildMetalRow(metal);
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
        onSelected: (_) => controller.setFilter(label),
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

  Widget _buildMetalRow(LMEMetal metal) {
    final hasData = metal.hasData;
    final isPositive = (metal.change ?? 0) >= 0;

    return Obx(() {
      controller.watchlistUpdateTrigger.value;

      return InkWell(
        onTap: () {
          if (!hasData) return;
          MetalDetailDialog.show(
            Get.context!,
            title: metal.name,
            lastPrice: '\$${metal.lastPrice!.toStringAsFixed(2)}',
            high: metal.high != null ? '\$${metal.high!.toStringAsFixed(2)}' : null,
            low: metal.low != null ? '\$${metal.low!.toStringAsFixed(2)}' : null,
            change: '${metal.change! > 0 ? '+' : ''}${metal.change!.toStringAsFixed(2)} (${metal.changePercent!.toStringAsFixed(2)}%)',
            isPositive: isPositive,
            lastTrade: DateFormat('dd MMM hh:mma').format(metal.lastUpdated).toLowerCase(),
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
                // Symbol icon
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
                      metal.symbol.length >= 2 ? metal.symbol.substring(0, 2) : metal.symbol,
                      style: TextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & exchange badge
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

                // Price & change
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hasData ? '\$${metal.lastPrice!.toStringAsFixed(2)}' : 'N/A',
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
                            '${metal.change!.abs().toStringAsFixed(2)} (${metal.changePercent!.abs().toStringAsFixed(2)}%)',
                            style: TextStyles.caption.copyWith(
                              color: isPositive ? ColorConstants.positiveGreen : ColorConstants.negativeRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '—',
                        style: TextStyles.caption.copyWith(color: Colors.grey[400]),
                      ),
                  ],
                ),
              ],
            ),
            if (hasData) ...[
              const SizedBox(height: 8),
              _buildHighLowGrid(metal),
            ],
          ],
        ),
      ),
    );
  });
}

  List<Color> _getMetalGradient(String symbol) {
    if (symbol.contains('CU')) return [const Color(0xFFB87333), const Color(0xFF8B5A2B)];
    if (symbol.contains('AL')) return [const Color(0xFF9E9E9E), const Color(0xFF616161)];
    if (symbol.contains('ZN')) return [const Color(0xFF00BCD4), const Color(0xFF0097A7)];
    if (symbol.contains('NI')) return [const Color(0xFF3F51B5), const Color(0xFF303F9F)];
    if (symbol.contains('PB')) return [const Color(0xFF607D8B), const Color(0xFF455A64)];
    if (symbol.contains('SN')) return [const Color(0xFF795548), const Color(0xFF5D4037)];
    if (symbol.contains('AA')) return [const Color(0xFFFFD700), const Color(0xFFDAA520)];
    return [ColorConstants.primaryBlue, ColorConstants.primaryBlue.withOpacity(0.7)];
  }

  Widget _buildHighLowGrid(LMEMetal metal) {
    final c3mValue = metal.c3m ?? 0;
    final c3mColor = c3mValue > 0 
        ? ColorConstants.positiveGreen 
        : (c3mValue < 0 ? ColorConstants.negativeRed : ColorConstants.textPrimary);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ColorConstants.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoItem('High', metal.high != null ? '\$${metal.high!.toStringAsFixed(2)}' : '—'),
          _buildInfoItem('Low', metal.low != null ? '\$${metal.low!.toStringAsFixed(2)}' : '—'),
          _buildInfoItem(
            'C3M', 
            metal.c3m != null ? '\$${metal.c3m!.toStringAsFixed(2)}' : '—',
            valueColor: metal.c3m != null ? c3mColor : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? valueColor}) {
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
            color: valueColor ?? ColorConstants.textPrimary,
          ),
        ),
      ],
    );
  }
}
