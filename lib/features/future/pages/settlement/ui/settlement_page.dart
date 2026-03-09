import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/constants/text_styles.dart';
import '../../../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/settlement_controller.dart';
import '../../../../../shared/widgets/common/metal_detail_dialog.dart';
import 'package:intl/intl.dart';

class SettlementPage extends StatelessWidget {
  const SettlementPage({super.key});

  SettlementController get controller => Get.put(SettlementController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: Obx(() {
        if (controller.isLoading.value && controller.settlementData.isEmpty) {
          return const ShimmerListLoader();
        }

        if (controller.settlementData.isEmpty) {
          return Center(
            child: Text(
              'No Settlement Data Available',
              style: TextStyles.bodyMedium.copyWith(color: ColorConstants.textSecondary),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: ColorConstants.primaryBlue,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = controller.settlementData[index];
                      return _buildSettlementCard(context, item);
                    },
                    childCount: controller.settlementData.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00695C),
            const Color(0xFF00897B),
          ],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'LME SETTLEMENT PRICES',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Official Cash & 3-Month Settlements',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementCard(BuildContext context, dynamic item) {
    return InkWell(
      onTap: () {
        MetalDetailDialog.show(
          context,
          title: '${item.metal} Settlement',
          lastPrice: 'Cash: \$${item.bidCash.toStringAsFixed(0)}/\$${item.askCash.toStringAsFixed(0)}',
          high: '3M: \$${item.bid3M.toStringAsFixed(0)}',
          low: '3M: \$${item.ask3M.toStringAsFixed(0)}',
          lastTrade: DateFormat('dd MMM hh:mma').format(DateTime.now()).toLowerCase(),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: ColorConstants.borderColor.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            // Card Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.metal,
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primaryBlue,
                    ),
                  ),
                  if (item.date.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.date,
                      style: TextStyles.caption.copyWith(
                        fontSize: 10,
                        color: ColorConstants.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Cash Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPriceSectionHeader('CASH (USD)'),
                        const SizedBox(height: 8),
                        _buildPriceRow('Bid', item.bidCash),
                        const SizedBox(height: 4),
                        _buildPriceRow('Ask', item.askCash),
                      ],
                    ),
                  ),
                  
                  Container(
                    height: 60,
                    width: 1,
                    color: ColorConstants.borderColor.withOpacity(0.5),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  
                  // 3M Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPriceSectionHeader('3-MONTH (USD)'),
                        const SizedBox(height: 8),
                        _buildPriceRow('Bid', item.bid3M),
                        const SizedBox(height: 4),
                        _buildPriceRow('Ask', item.ask3M),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSectionHeader(String title) {
    return Text(
      title,
      style: TextStyles.caption.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: ColorConstants.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildPriceRow(String label, double value) {
    final displayValue = value > 0 ? value.toStringAsFixed(0) : '-';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyles.bodySmall.copyWith(
            color: ColorConstants.textSecondary,
          ),
        ),
        Text(
          displayValue,
          style: TextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: value > 0 ? ColorConstants.textPrimary : Colors.grey,
          ),
        ),
      ],
    );
  }
}
