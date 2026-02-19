import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/loaders/shimmer_loader.dart';
import 'price_chart.dart';
import 'all_india_prices_widget.dart';

class MetalDetailTemplate extends StatelessWidget {
  final String title;
  final String metalName;
  final String symbol;
  final List<Color> gradientColors;
  final Color accentColor;
  final bool isLoading;
  final List<String> locations;
  final List<String> types;
  final RxString selectedLocation;
  final RxString selectedType;
  final List<dynamic> filteredPrices;
  final List<String> Function() watchlistIdsGetter;
  final RxInt watchlistUpdateTrigger;
  final Future<void> Function() onRefresh;
  final void Function(String) onToggleWatchlist;

  const MetalDetailTemplate({
    super.key,
    required this.title,
    required this.metalName,
    required this.symbol,
    required this.gradientColors,
    required this.accentColor,
    required this.isLoading,
    required this.locations,
    required this.types,
    required this.selectedLocation,
    required this.selectedType,
    required this.filteredPrices,
    required this.watchlistIdsGetter,
    required this.watchlistUpdateTrigger,
    required this.onRefresh,
    required this.onToggleWatchlist,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: ColorConstants.textPrimary),
        ),
        title: Text(
          title,
          style: TextStyles.h5.copyWith(color: ColorConstants.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, color: ColorConstants.textPrimary),
          ),
        ],
      ),
      body: isLoading
          ? const ShimmerListLoader()
          : RefreshIndicator(
              onRefresh: onRefresh,
              color: accentColor,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildMarketStatusHeader()),
                  SliverToBoxAdapter(child: _buildFilterOptions()),
                  SliverToBoxAdapter(child: _buildPriceChartPlaceholder()),
                  SliverToBoxAdapter(child: _buildAllIndiaPrices()),
                  SliverToBoxAdapter(child: _buildLocationWisePrices()),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }


  Widget _buildMarketStatusHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: ColorConstants.positiveGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Market Open',
                      style: TextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                Formatters.formatTime(DateTime.now()),
                style: TextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            metalName,
            style: TextStyles.h5.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Real-time prices across major Indian cities',
            style: TextStyles.caption.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Location',
            style: TextStyles.bodySmall.copyWith(
              color: ColorConstants.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  children: locations
                      .map((location) => _buildFilterChip(
                            location,
                            selectedLocation.value == location,
                            () => selectedLocation.value = location,
                          ))
                      .toList(),
                )),
          ),
          const SizedBox(height: 16),
          Text(
            'Filter by Type',
            style: TextStyles.bodySmall.copyWith(
              color: ColorConstants.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  children: types
                      .map((type) => _buildFilterChip(
                            type,
                            selectedType.value == type,
                            () => selectedType.value = type,
                          ))
                      .toList(),
                )),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : ColorConstants.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyles.bodySmall.copyWith(
            color: isSelected ? accentColor : ColorConstants.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceChartPlaceholder() {
    // Extract metal name from the title (e.g., "Copper Prices" -> "Copper")
    final metalNameMatch = RegExp(r'^(\w+)').firstMatch(metalName);
    final extractedMetal = metalNameMatch?.group(1) ?? 'Copper';
    
    return PriceChart(
      metalName: extractedMetal,
      accentColor: accentColor,
      gradientColors: gradientColors,
    );
  }

  Widget _buildLocationWisePrices() {
    // No Obx needed here - filteredPrices is a regular List passed from parent
    // The parent widget handles the reactivity via Obx wrapper around the entire build
    final groupedPrices = <String, List<dynamic>>{};
    for (var price in filteredPrices) {
      if (!groupedPrices.containsKey(price.location)) {
        groupedPrices[price.location] = [];
      }
      groupedPrices[price.location]!.add(price);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedPrices.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    entry.key,
                    style: TextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.map((price) => _buildPriceCard(price)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPriceCard(dynamic price) {
    final isPositive = price.change >= 0;

    // Use Obx only for the watchlist icon to minimize rebuilds
    // Access the observable inside the Obx builder
    final isInWatchlist = watchlistIdsGetter().contains(price.id);

      return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isInWatchlist
            ? Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          symbol,
                          style: TextStyles.h6.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            price.type,
                            style: TextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            price.unit,
                            style: TextStyles.caption.copyWith(
                              color: ColorConstants.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Obx(() {
                      // Observe watchlistUpdateTrigger to rebuild when watchlist changes
                      watchlistUpdateTrigger.value;
                      final isWatchlisted = watchlistIdsGetter().contains(price.id);
                      return IconButton(
                        onPressed: () => onToggleWatchlist(price.id),
                        icon: Icon(
                          isWatchlisted ? Icons.star : Icons.star_border,
                          color: isWatchlisted ? Colors.amber : ColorConstants.textSecondary,
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Price',
                            style: TextStyles.caption.copyWith(
                              color: ColorConstants.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${price.currentPrice.toStringAsFixed(2)}',
                            style: TextStyles.h5,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Previous Price',
                            style: TextStyles.caption.copyWith(
                              color: ColorConstants.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${price.previousPrice.toStringAsFixed(2)}',
                            style: TextStyles.bodyMedium.copyWith(
                              color: ColorConstants.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPositive
                  ? ColorConstants.positiveGreen.withOpacity(0.05)
                  : ColorConstants.negativeRed.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive
                      ? ColorConstants.positiveGreen
                      : ColorConstants.negativeRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${isPositive ? '+' : ''}₹${price.change.toStringAsFixed(2)}',
                  style: TextStyles.bodyMedium.copyWith(
                    color: isPositive
                        ? ColorConstants.positiveGreen
                        : ColorConstants.negativeRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${isPositive ? '+' : ''}${price.changePercent.toStringAsFixed(2)}%)',
                  style: TextStyles.caption.copyWith(
                    color: isPositive
                        ? ColorConstants.positiveGreen
                        : ColorConstants.negativeRed,
                  ),
                ),
                const Spacer(),
                Text(
                  Formatters.formatTime(price.lastUpdated),
                  style: TextStyles.caption.copyWith(
                    color: ColorConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllIndiaPrices() {
    // Extract metal name from the title
    final metalNameMatch = RegExp(r'^(\w+)').firstMatch(metalName);
    final extractedMetal = metalNameMatch?.group(1) ?? 'Copper';
    
    return AllIndiaPricesWidget(
      metalName: extractedMetal,
      accentColor: accentColor,
    );
  }
}
