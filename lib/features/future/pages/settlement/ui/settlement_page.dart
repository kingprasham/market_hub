import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/constants/text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/settlement_controller.dart';

class SettlementPage extends StatelessWidget {
  const SettlementPage({super.key});

  SettlementController get controller => Get.put(SettlementController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const ShimmerListLoader();
        }

        // Show empty/error state
        if (controller.hasError.value || controller.settlements.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.refreshData,
            color: const Color(0xFF00897B),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Settlement Data Unavailable',
                        style: TextStyles.h5.copyWith(color: ColorConstants.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          controller.errorMessage.value.isNotEmpty 
                            ? controller.errorMessage.value
                            : 'LME/COMEX settlement prices\nrequire a paid API subscription.',
                          textAlign: TextAlign.center,
                          style: TextStyles.bodySmall.copyWith(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Contact support for access',
                              style: TextStyles.caption.copyWith(color: Colors.orange[700]),
                            ),
                          ],
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
              // Market Status Header
              SliverToBoxAdapter(
                child: _buildMarketStatusHeader(),
              ),

              // Filter Options
              SliverToBoxAdapter(
                child: _buildFilterOptions(),
              ),

              // Settlement List
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final settlement = controller.filteredSettlements[index];
                      return _buildSettlementCard(settlement);
                    },
                    childCount: controller.filteredSettlements.length,
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

  Widget _buildMarketStatusHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF00897B),
            Color(0xFF00897B).withOpacity(0.8),
          ],
        ),
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
                      'Updated',
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
            'Settlement Prices',
            style: TextStyles.h5.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Contract settlement prices and dates',
            style: TextStyles.caption.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All'),
          _buildFilterChip('LME'),
          _buildFilterChip('COMEX'),
          _buildFilterChip('SHFE'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Obx(() {
      final isSelected = controller.selectedExchange.value == label;
      return Container(
        margin: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (value) => controller.setExchange(label),
          backgroundColor: Colors.white,
          selectedColor: const Color(0xFF00897B).withOpacity(0.1),
          labelStyle: TextStyles.bodySmall.copyWith(
            color: isSelected ? const Color(0xFF00897B) : ColorConstants.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          side: BorderSide(
            color: isSelected ? const Color(0xFF00897B) : ColorConstants.borderColor,
          ),
        ),
      );
    });
  }

  Widget _buildSettlementCard(dynamic settlement) {
    final isPositive = settlement.change >= 0;
    final isInWatchlist = controller.watchlistIds.contains(settlement.id);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Header Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Metal Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getMetalGradient(settlement.symbol),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      settlement.metal.substring(0, 2),
                      style: TextStyles.h6.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Settlement Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settlement.metal,
                        style: TextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getExchangeColor(settlement.exchange).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              settlement.exchange,
                              style: TextStyles.caption.copyWith(
                                color: _getExchangeColor(settlement.exchange),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            settlement.contract,
                            style: TextStyles.caption.copyWith(
                              color: ColorConstants.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Watchlist Star
                IconButton(
                  onPressed: () => controller.toggleWatchlist(settlement.id),
                  icon: Icon(
                    isInWatchlist ? Icons.star : Icons.star_border,
                    color: isInWatchlist ? Colors.amber : ColorConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Settlement Price Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Settlement Price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settlement',
                        style: TextStyles.caption.copyWith(
                          color: ColorConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${settlement.settlementPrice.toStringAsFixed(2)}',
                        style: TextStyles.h5,
                      ),
                    ],
                  ),
                ),
                // Previous Settlement
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Previous',
                        style: TextStyles.caption.copyWith(
                          color: ColorConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${settlement.previousSettlement.toStringAsFixed(2)}',
                        style: TextStyles.bodyMedium.copyWith(
                          color: ColorConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Change
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change',
                        style: TextStyles.caption.copyWith(
                          color: ColorConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isPositive ? '+' : ''}\$${settlement.change.toStringAsFixed(2)}',
                        style: TextStyles.bodyMedium.copyWith(
                          color: isPositive
                              ? ColorConstants.positiveGreen
                              : ColorConstants.negativeRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Dates Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildDateInfo(
                    'Settlement Date',
                    dateFormat.format(settlement.settlementDate),
                    Icons.calendar_today,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: ColorConstants.borderColor,
                ),
                Expanded(
                  child: _buildDateInfo(
                    'Expiry Date',
                    dateFormat.format(settlement.expiryDate),
                    Icons.event,
                  ),
                ),
              ],
            ),
          ),

          // Change Info
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
                  '${isPositive ? '+' : ''}${settlement.changePercent.toStringAsFixed(2)}%',
                  style: TextStyles.bodyMedium.copyWith(
                    color: isPositive
                        ? ColorConstants.positiveGreen
                        : ColorConstants.negativeRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Updated: ${Formatters.formatTime(settlement.lastUpdated)}',
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

  Widget _buildDateInfo(String label, String date, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: ColorConstants.textSecondary,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyles.caption.copyWith(
            color: ColorConstants.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: TextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<Color> _getMetalGradient(String symbol) {
    if (symbol.contains('CU')) return [Color(0xFFB87333), Color(0xFF8B5A2B)];
    if (symbol.contains('AL')) return [Color(0xFF9E9E9E), Color(0xFF616161)];
    if (symbol.contains('ZN')) return [Color(0xFF00BCD4), Color(0xFF0097A7)];
    if (symbol.contains('NI')) return [Color(0xFF3F51B5), Color(0xFF303F9F)];
    if (symbol.contains('PB')) return [Color(0xFF607D8B), Color(0xFF455A64)];
    if (symbol.contains('SN')) return [Color(0xFF795548), Color(0xFF5D4037)];
    if (symbol.contains('GC') || symbol.toLowerCase().contains('gold')) {
      return [Color(0xFFFFD700), Color(0xFFFFA500)];
    }
    if (symbol.contains('SI') || symbol.toLowerCase().contains('silver')) {
      return [Color(0xFFC0C0C0), Color(0xFF9E9E9E)];
    }
    return [Color(0xFF00897B), Color(0xFF00897B).withOpacity(0.7)];
  }

  Color _getExchangeColor(String exchange) {
    if (exchange == 'LME') return ColorConstants.primaryOrange;
    if (exchange == 'COMEX') return Color(0xFF1976D2);
    if (exchange == 'SHFE') return Color(0xFFD32F2F);
    return ColorConstants.primaryBlue;
  }
}
