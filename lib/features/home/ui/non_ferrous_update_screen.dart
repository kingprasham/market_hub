import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../controller/home_controller.dart';
import '../../../data/models/market/price_change_model.dart';

class NonFerrousUpdateScreen extends GetView<HomeController> {
  const NonFerrousUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ColorConstants.textPrimary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Non-Ferrous Price History',
          style: TextStyles.h4.copyWith(color: ColorConstants.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final history = controller.priceChanges
            .where((c) => c.category == 'Non-Ferrous')
            .toList();
            
        if (history.isEmpty) {
          return _buildEmptyState('No price history detected yet');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final h = history[index];
            return _buildHistoryCard(h);
          },
        );
      }),
    );
  }

  Widget _buildHistoryCard(PriceChange h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: ColorConstants.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  h.name.replaceFirst(RegExp(r'^General\s*[-–—]\s*', caseSensitive: false), ''),
                  style: TextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: ColorConstants.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.formatRelativeTime(h.detectedAt),
                style: TextStyles.caption.copyWith(color: ColorConstants.textHint, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (h.city.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(h.city, style: TextStyles.labelSmall.copyWith(color: ColorConstants.primaryOrange, fontSize: 9)),
                ),
              const Spacer(),
              Text(
                h.oldPrice,
                style: TextStyles.bodySmall.copyWith(
                  color: ColorConstants.textHint,
                  decoration: TextDecoration.lineThrough,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: ColorConstants.textHint),
              const SizedBox(width: 8),
              Text(
                h.newPrice,
                style: TextStyles.bodyLarge.copyWith(
                  color: ColorConstants.primaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 48, color: ColorConstants.textHint.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(message, style: TextStyles.bodyMedium.copyWith(color: ColorConstants.textHint)),
        ],
      ),
    );
  }
}
