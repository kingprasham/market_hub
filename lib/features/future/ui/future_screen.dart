import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/future_controller.dart';
import '../widgets/fx678_webview.dart';
import '../pages/london_lme/ui/london_lme_page.dart';
import '../pages/china_shfe/ui/china_shfe_page.dart';
import '../pages/us_comex/ui/us_comex_page.dart';
import '../pages/fx/ui/fx_page.dart';
import '../pages/reference_rate/ui/reference_rate_page.dart';
import '../pages/warehouse_stock/ui/warehouse_stock_page.dart';
import '../pages/settlement/ui/settlement_page.dart';
import '../../home/ui/widgets/side_menu.dart';

class FutureScreen extends GetView<FutureController> {
  const FutureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      drawer: const SideMenu(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Future Prices',
          style: TextStyles.h4.copyWith(color: ColorConstants.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: controller.fetchAllData,
            icon: const Icon(
              Icons.refresh,
              color: ColorConstants.textPrimary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: Obx(() => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: List.generate(
                  controller.tabs.length,
                  (index) => _buildTabItem(index),
                ),
              ),
            )),
          ),

          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const ShimmerListLoader();
              }

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildTabContent(),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index) {
    final isSelected = controller.selectedTabIndex.value == index;

    return GestureDetector(
      onTap: () => controller.selectedTabIndex.value = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? ColorConstants.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? ColorConstants.primaryBlue
                : ColorConstants.borderColor,
          ),
        ),
        child: Text(
          controller.tabs[index],
          style: TextStyles.bodyMedium.copyWith(
            color: isSelected ? Colors.white : ColorConstants.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (controller.selectedTabIndex.value) {
      case 0:
        return const LondonLMEPage();
      case 1:
        return const ChinaSHFEPage();
      case 2:
        return const USComexPage();
      case 3:
        return const FxPage(); // Main Metals handled merged or separate?
      case 4:
        return const ReferenceRatePage();
      case 5:
        return const WarehouseStockPage();
      case 6:
        return const SettlementPage();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPriceCard(dynamic item) {
    final isPositive = item.change >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ColorConstants.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    item.symbol.substring(0, item.symbol.length > 2 ? 2 : item.symbol.length),
                    style: TextStyles.h6.copyWith(
                      color: ColorConstants.primaryBlue,
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
                      item.name,
                      style: TextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.exchange,
                      style: TextStyles.caption.copyWith(
                        color: ColorConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.currency ?? '\$'}${Formatters.formatNumber(item.price)}',
                    style: TextStyles.h5,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? ColorConstants.positiveGreen.withOpacity(0.1)
                          : ColorConstants.negativeRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 14,
                          color: isPositive
                              ? ColorConstants.positiveGreen
                              : ColorConstants.negativeRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isPositive ? '+' : ''}${item.changePercent.toStringAsFixed(2)}%',
                          style: TextStyles.caption.copyWith(
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
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem('High', Formatters.formatNumber(item.high)),
              _buildStatItem('Low', Formatters.formatNumber(item.low)),
              _buildStatItem('Open', Formatters.formatNumber(item.open)),
              _buildStatItem('Vol', Formatters.formatCompactNumber(item.volume.toDouble())),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last updated: ${Formatters.formatTime(item.lastUpdated)}',
                style: TextStyles.caption.copyWith(
                  color: ColorConstants.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () => _showAddToWatchlistDialog(item),
                child: Icon(
                  Icons.star_border,
                  color: ColorConstants.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFxCard(dynamic item) {
    final isPositive = item.change >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ColorConstants.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.currency_exchange,
                  color: ColorConstants.primaryOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.pair,
                  style: TextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.rate.toStringAsFixed(4),
                    style: TextStyles.h5,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? ColorConstants.positiveGreen.withOpacity(0.1)
                          : ColorConstants.negativeRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${item.changePercent.toStringAsFixed(2)}%',
                      style: TextStyles.caption.copyWith(
                        color: isPositive
                            ? ColorConstants.positiveGreen
                            : ColorConstants.negativeRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (item.bid != null && item.ask != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorConstants.positiveGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Bid',
                          style: TextStyles.caption.copyWith(
                            color: ColorConstants.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.bid.toStringAsFixed(4),
                          style: TextStyles.bodyLarge.copyWith(
                            color: ColorConstants.positiveGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorConstants.negativeRed.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Ask',
                          style: TextStyles.caption.copyWith(
                            color: ColorConstants.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.ask.toStringAsFixed(4),
                          style: TextStyles.bodyLarge.copyWith(
                            color: ColorConstants.negativeRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReferenceCard(dynamic item) {
    final isPositive = item.change >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item.source ?? 'REF',
                style: TextStyles.caption.copyWith(
                  color: Colors.indigo,
                  fontWeight: FontWeight.w700,
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
                  item.pair,
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Updated: ${Formatters.formatTime(item.lastUpdated)}',
                  style: TextStyles.caption.copyWith(
                    color: ColorConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.rate.toStringAsFixed(4),
                style: TextStyles.h5,
              ),
              if (item.change != 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${isPositive ? '+' : ''}${item.change.toStringAsFixed(4)}',
                  style: TextStyles.caption.copyWith(
                    color: isPositive
                        ? ColorConstants.positiveGreen
                        : ColorConstants.negativeRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyles.caption.copyWith(
              color: ColorConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToWatchlistDialog(dynamic item) {
    Get.snackbar(
      'Added to Watchlist',
      '${item.name} has been added to your watchlist',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: ColorConstants.positiveGreen,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 2),
    );
  }
}
