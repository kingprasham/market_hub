import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../shared/widgets/loaders/shimmer_loader.dart';
import '../../home/ui/widgets/side_menu.dart';
import '../controller/forex_controller.dart';
import '../../../data/models/forex/sbi_forex_rate_model.dart';

class ForexScreen extends GetView<ForexController> {
  const ForexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SideMenu(),
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('SBI Forex Rates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const ShimmerListLoader();
        }

        // Show error state
        if (controller.hasError.value || controller.currencyRates.isEmpty) {
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
                            : 'Unable to fetch forex data.\nCheck your internet connection.',
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
              // Filter Options
              SliverToBoxAdapter(
                child: _buildFilterOptions(),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: Obx(() {
                  final currenciesList = controller.filteredCurrencies;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final rate = currenciesList[index];
                        return _buildCompactCurrencyRow(rate, index, currenciesList.length);
                      },
                      childCount: currenciesList.length,
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
        selectedColor: ColorConstants.primaryBlue.withValues(alpha: 0.1),
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

  Widget _buildCompactCurrencyRow(SbiForexRateModel rate, int index, int totalCount) {
    final sellRate = controller.getSellRate(rate);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: ColorConstants.borderColor.withValues(alpha: 0.5),
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
                colors: _getCurrencyGradient(rate.currencyCode),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                rate.currencyCode.substring(0, 2),
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
                  rate.currencyCode,
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
                        color: ColorConstants.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'SBI FOREX',
                        style: TextStyles.caption.copyWith(
                          color: ColorConstants.primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      controller.rateType.value,
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

          // 3. Price & Change (Right Aligned)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Price (Sell Rate as default)
              Text(
                sellRate != null ? '₹${sellRate.toStringAsFixed(2)}' : 'N/A',
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              // Change Indicator
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (rate.change != null) ...[
                    Icon(
                      rate.change! >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: rate.change! >= 0 ? ColorConstants.positiveGreen : ColorConstants.negativeRed,
                      size: 16,
                    ),
                    Text(
                      '${rate.change!.abs().toStringAsFixed(2)} (${rate.percentChange?.abs().toStringAsFixed(2) ?? '0.00'}%)',
                      style: TextStyles.caption.copyWith(
                        color: rate.change! >= 0 ? ColorConstants.positiveGreen : ColorConstants.negativeRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                     Text(
                      '0.00 (0.00%)',
                      style: TextStyles.caption.copyWith(
                        color: ColorConstants.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _getCurrencyGradient(String currencyCode) {
    switch (currencyCode) {
      case 'USD': return [const Color(0xFF85bb65), const Color(0xFF4caf50)];
      case 'EUR': return [const Color(0xFF003399), const Color(0xFF0055cc)];
      case 'GBP': return [const Color(0xFFC8102E), const Color(0xFF012169)];
      case 'JPY': return [const Color(0xFFBC002D), const Color(0xFFE04050)];
      case 'AUD': return [const Color(0xFF00008B), const Color(0xFFFF0000)];
      case 'CAD': return [const Color(0xFFFF0000), const Color(0xFFCC0000)];
      case 'CHF': return [const Color(0xFFFF0000), const Color(0xFFD80000)];
      case 'CNY': return [const Color(0xFFDE2910), const Color(0xFFFF4040)];
      case 'HKD': return [const Color(0xFFDE2910), const Color(0xFFE04050)];
      case 'NZD': return [const Color(0xFF00247D), const Color(0xFFCC142B)];
      case 'SEK': return [const Color(0xFF006AA7), const Color(0xFFFECC00)];
      case 'SKR': return [const Color(0xFF005293), const Color(0xFFFECB00)];
      case 'SGD': return [const Color(0xFFED2939), const Color(0xFFFFFFFF)];
      case 'AED': return [const Color(0xFF00732F), const Color(0xFFCE1126)];
      case 'INR': return [const Color(0xFFFF9933), const Color(0xFF138808)];
      default: return [ColorConstants.primaryBlue, ColorConstants.primaryBlue.withValues(alpha: 0.7)];
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About SBI Forex Rates'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This data is sourced from the SBI FX RateKeeper repository on GitHub.',
              ),
              const SizedBox(height: 12),
              const Text('Data Source:'),
              const SizedBox(height: 4),
              SelectableText(
                'https://github.com/sahilgupta/sbi-fx-ratekeeper',
                style: TextStyles.caption.copyWith(color: Colors.blue),
              ),
              const SizedBox(height: 12),
              const Text(
                'Rates are updated twice daily (morning and evening).',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
