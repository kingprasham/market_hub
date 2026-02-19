import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../controller/home_controller.dart';
import '../../../data/models/content/update_model.dart'; // Ensure correct import
import '../../../data/models/content/update_model.dart'; // Ensure correct import
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';

class AllUpdatesPage extends StatelessWidget {
  const AllUpdatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Find the existing HomeController
    final controller = Get.find<HomeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Latest Updates'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          TextButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.liveNewsWebView),
            icon: const Icon(Icons.public, size: 18, color: ColorConstants.primaryBlue),
            label: const Text(
              'View Global News',
              style: TextStyle(color: ColorConstants.primaryBlue, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: ColorConstants.backgroundColor,
      body: Obx(() {
        if (controller.updates.isEmpty) {
          return const Center(child: Text('No updates available'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.updates.length,
          itemBuilder: (context, index) {
            final update = controller.updates[index];
            return _buildUpdateCard(update);
          },
        );
      }),
    );
  }

  Widget _buildUpdateCard(UpdateModel update) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: update.isImportant
            ? Border.all(color: ColorConstants.primaryOrange.withOpacity(0.5))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
         onTap: () {
          Get.dialog(
            AlertDialog(
              title: Text(update.title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Category', update.category ?? 'General'),
                    const SizedBox(height: 8),
                    _buildDetailRow('Time', Formatters.timeAgo(update.timestamp)),
                    const SizedBox(height: 16),
                    Text(
                      update.description,
                      style: TextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(update.category ?? 'General').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    update.category ?? 'General',
                    style: TextStyles.caption.copyWith(
                      color: _getCategoryColor(update.category ?? 'General'),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (update.isImportant) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.priority_high,
                    color: ColorConstants.primaryOrange,
                    size: 18,
                  ),
                ],
                const Spacer(),
                Text(
                  Formatters.timeAgo(update.timestamp),
                  style: TextStyles.caption.copyWith(
                    color: ColorConstants.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              update.title,
              style: TextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              update.description,
              style: TextStyles.bodySmall.copyWith(
                color: ColorConstants.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Market Update':
        return ColorConstants.primaryBlue;
      case 'Exchange News':
        return ColorConstants.primaryOrange;
      case 'FX Update':
        return Colors.purple;
      case 'Spot Price':
        return Colors.teal;
      case 'Futures':
        return Colors.indigo;
      default:
        return ColorConstants.textSecondary;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyles.bodySmall.copyWith(
              color: ColorConstants.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyles.bodySmall.copyWith(
              color: ColorConstants.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
