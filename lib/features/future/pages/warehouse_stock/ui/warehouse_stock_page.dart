import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/constants/text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/warehouse_stock_controller.dart';

class WarehouseStockPage extends StatelessWidget {
  const WarehouseStockPage({super.key});

  WarehouseStockController get controller => Get.put(WarehouseStockController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const ShimmerListLoader();
        }

        // Show empty/error state
        if (controller.hasError.value || controller.warehouseStocks.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.refreshData,
            color: const Color(0xFF7B1FA2),
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
                        'Warehouse Data Unavailable',
                        style: TextStyles.h5.copyWith(color: ColorConstants.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          controller.errorMessage.value.isNotEmpty 
                            ? controller.errorMessage.value
                            : 'LME warehouse inventory data\nrequires a paid API subscription.',
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

              // Warehouse Stock List
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final stock = controller.warehouseStocks[index];
                      return _buildWarehouseCard(stock);
                    },
                    childCount: controller.warehouseStocks.length,
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
            Color(0xFF7B1FA2),
            Color(0xFF7B1FA2).withOpacity(0.8),
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
            'Warehouse Stock',
            style: TextStyles.h5.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Global warehouse inventory levels',
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
          _buildFilterChip('All', true),
          _buildFilterChip('London', false),
          _buildFilterChip('Singapore', false),
          _buildFilterChip('Rotterdam', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (value) {},
        backgroundColor: Colors.white,
        selectedColor: Color(0xFF7B1FA2).withOpacity(0.1),
        labelStyle: TextStyles.bodySmall.copyWith(
          color: isSelected ? Color(0xFF7B1FA2) : ColorConstants.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? Color(0xFF7B1FA2) : ColorConstants.borderColor,
        ),
      ),
    );
  }

  Widget _buildWarehouseCard(dynamic stock) {
    final isPositive = stock.change >= 0;
    final isInWatchlist = controller.watchlistIds.contains(stock.id);

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
                      colors: _getMetalGradient(stock.symbol),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      stock.symbol,
                      style: TextStyles.h6.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Stock Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.metal,
                        style: TextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: ColorConstants.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            stock.location,
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
                  onPressed: () => controller.toggleWatchlist(stock.id),
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

          // Stock Levels
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Current Stock
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Stock',
                        style: TextStyles.caption.copyWith(
                          color: ColorConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Formatters.formatNumber(stock.stockLevel.toDouble())} ${stock.unit}',
                        style: TextStyles.h6,
                      ),
                    ],
                  ),
                ),
                // Previous Stock
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
                        '${Formatters.formatNumber(stock.previousStock.toDouble())} ${stock.unit}',
                        style: TextStyles.bodyMedium.copyWith(
                          color: ColorConstants.textSecondary,
                        ),
                      ),
                    ],
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
                  '${isPositive ? '+' : ''}${Formatters.formatNumber(stock.change.toDouble())} ${stock.unit}',
                  style: TextStyles.bodyMedium.copyWith(
                    color: isPositive
                        ? ColorConstants.positiveGreen
                        : ColorConstants.negativeRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${stock.changePercent.toStringAsFixed(2)}%)',
                  style: TextStyles.caption.copyWith(
                    color: isPositive
                        ? ColorConstants.positiveGreen
                        : ColorConstants.negativeRed,
                  ),
                ),
                const Spacer(),
                Text(
                  Formatters.formatTime(stock.lastUpdated),
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

  List<Color> _getMetalGradient(String symbol) {
    if (symbol.contains('CU')) return [Color(0xFFB87333), Color(0xFF8B5A2B)];
    if (symbol.contains('AL')) return [Color(0xFF9E9E9E), Color(0xFF616161)];
    if (symbol.contains('ZN')) return [Color(0xFF00BCD4), Color(0xFF0097A7)];
    if (symbol.contains('NI')) return [Color(0xFF3F51B5), Color(0xFF303F9F)];
    if (symbol.contains('PB')) return [Color(0xFF607D8B), Color(0xFF455A64)];
    if (symbol.contains('SN')) return [Color(0xFF795548), Color(0xFF5D4037)];
    return [Color(0xFF7B1FA2), Color(0xFF7B1FA2).withOpacity(0.7)];
  }
}
