import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/models/market/price_change_model.dart';
import '../controller/home_controller.dart';

/// Full-page view of all detected Non-Ferrous price changes.
class AllUpdatesPage extends StatelessWidget {
  const AllUpdatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Non-Ferrous Price Changes'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      backgroundColor: ColorConstants.backgroundColor,
      body: Column(
        children: [
          const Divider(height: 1, color: ColorConstants.dividerColor),

          // ─── Change list ────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              final changes = controller.priceChanges
                      .where((c) => c.category == 'Non-Ferrous')
                      .toList();

              if (changes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 48,
                        color: ColorConstants.textHint.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Non-Ferrous changes detected',
                        style: TextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.textHint,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Changes will appear as prices update',
                        style: TextStyles.caption.copyWith(
                          color: ColorConstants.textHint,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: changes.length,
                itemBuilder: (context, index) {
                  return _buildChangeCard(changes[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeCard(PriceChange change) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          // Category icon (Non-Ferrous icon)
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ColorConstants.primaryOrange.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.diamond_outlined,
              size: 18,
              color: ColorConstants.primaryOrange,
            ),
          ),
          const SizedBox(width: 12),

          // Name + city
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  change.name,
                  style: TextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (change.city.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryOrange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      change.city,
                      style: TextStyles.labelSmall.copyWith(
                        color: ColorConstants.primaryOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Old → New price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                change.newPrice,
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.textPrimary,
                  fontSize: 14,
                ),
              ),
              Text(
                change.oldPrice,
                style: TextStyles.labelSmall.copyWith(
                  color: ColorConstants.textHint,
                  fontSize: 10,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
