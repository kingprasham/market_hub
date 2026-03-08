import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../controller/home_controller.dart';
import '../../../app/routes/app_routes.dart';

/// Full-page view of all Market Hub Updates.
class AllUpdatesPage extends StatelessWidget {
  const AllUpdatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Market Hub Updates',
          style: TextStyles.h3.copyWith(
            color: ColorConstants.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: ColorConstants.textPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      backgroundColor: ColorConstants.backgroundColor,
      body: Column(
        children: [
          const Divider(height: 1, color: ColorConstants.dividerColor),

          // ─── Updates list ───────────────────────────────────────────
          Expanded(
            child: Obx(() {
              final updates = controller.homeUpdates;

              if (updates.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ColorConstants.primaryOrange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.rss_feed_rounded,
                          size: 40,
                          color: ColorConstants.primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No updates available',
                        style: TextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ColorConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Updates will appear here as they are posted',
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
                itemCount: updates.length,
                itemBuilder: (context, index) {
                  final update = updates[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {
                        if (update.hasPdf && update.pdfUrl != null) {
                          Get.toNamed(AppRoutes.pdfViewer, arguments: {
                            'url': update.pdfUrl,
                            'title': update.title,
                          });
                        } else {
                          Get.toNamed(AppRoutes.updateDetail, arguments: update);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (update.isImportant)
                                        Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                        ),
                                          child: const Text(
                                            'NEW',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          update.title,
                                          style: TextStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: ColorConstants.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    update.description,
                                    style: TextStyles.bodySmall.copyWith(
                                      color: ColorConstants.textSecondary,
                                      height: 1.5,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 14, color: ColorConstants.textHint),
                                      const SizedBox(width: 4),
                                      Text(
                                        Formatters.formatRelativeTime(update.createdAt),
                                        style: TextStyles.labelSmall.copyWith(color: ColorConstants.textHint),
                                      ),
                                      if (update.hasPdf) ...[
                                        const SizedBox(width: 16),
                                        const Icon(Icons.picture_as_pdf_outlined, size: 14, color: Colors.red),
                                        const SizedBox(width: 4),
                                        Text(
                                          'PDF',
                                          style: TextStyles.labelSmall.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (update.hasImage) ...[
                              const SizedBox(width: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  update.imageUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildUpdatePlaceholder(update.category),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(width: 16),
                              _buildUpdatePlaceholder(update.category),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatePlaceholder(String? category) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.primaryOrange,
            ColorConstants.primaryOrange.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primaryOrange.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          _getUpdateIcon(category),
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }

  IconData _getUpdateIcon(String? category) {
    final cat = category?.toLowerCase() ?? '';
    if (cat.contains('ferrous')) return Icons.factory_outlined;
    if (cat.contains('market')) return Icons.show_chart_rounded;
    if (cat.contains('price')) return Icons.monetization_on_rounded;
    return Icons.rss_feed_rounded;
  }
}
