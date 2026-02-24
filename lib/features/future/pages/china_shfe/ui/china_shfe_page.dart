import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/constants/text_styles.dart';
import '../../../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/china_shfe_controller.dart';

class ChinaSHFEPage extends StatelessWidget {
  const ChinaSHFEPage({super.key});

  ChinaSHFEController get controller => Get.put(ChinaSHFEController());

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
          color: const Color(0xFFDE2910),
          child: CustomScrollView(
            slivers: [
              // Filter Options
              SliverToBoxAdapter(
                child: _buildFilterOptions(),
              ),

              // Metal List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final metal = controller.filteredMetals[index];
                      return _buildCompactMetalRow(metal, index, controller.filteredMetals.length);
                    },
                    childCount: controller.filteredMetals.length,
                  ),
                ),
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
        selectedColor: const Color(0xFFDE2910).withOpacity(0.1),
        labelStyle: TextStyles.bodySmall.copyWith(
          color: isSelected ? const Color(0xFFDE2910) : ColorConstants.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? const Color(0xFFDE2910) : ColorConstants.borderColor,
        ),
      ),
    );
  }

  Widget _buildCompactMetalRow(dynamic metal, int index, int totalCount) {
    final hasData = metal.lastPrice != null;
    final isPositive = (metal.change ?? 0) >= 0;

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
        child: Column(
          children: [
            Row(
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
                              color: const Color(0xFFDE2910).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'SHFE',
                              style: TextStyles.caption.copyWith(
                                color: const Color(0xFFDE2910),
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
                      hasData ? '¥${metal.lastPrice!.toStringAsFixed(0)}' : 'N/A',
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
                            '${metal.change!.abs().toStringAsFixed(0)} (${metal.changePercent!.abs().toStringAsFixed(2)}%)',
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
            if (hasData) ...[
              const SizedBox(height: 8),
              _buildHighLowGrid(metal),
            ],
          ],
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
    if (symbol.contains('AU')) return [const Color(0xFFFFD700), const Color(0xFFDAA520)];
    if (symbol.contains('AG')) return [const Color(0xFFC0C0C0), const Color(0xFFA8A8A8)];
    return [const Color(0xFFDE2910), const Color(0xFFDE2910).withOpacity(0.7)];
  }

  Widget _buildHighLowGrid(dynamic metal) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ColorConstants.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoItem('High', metal.high != null ? '¥${metal.high!.toStringAsFixed(0)}' : '—'),
          _buildInfoItem('Low', metal.low != null ? '¥${metal.low!.toStringAsFixed(0)}' : '—'),
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
