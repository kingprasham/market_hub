import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../home/data/market_update_data.dart';
import '../../../data/models/content/update_model.dart';

class UpdateDetailScreen extends StatelessWidget {
  const UpdateDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UpdateModel? update = Get.arguments as UpdateModel?;
    if (update == null) {
      return const Scaffold(body: Center(child: Text('Error: Update not found')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header (Image or Styled Placeholder)
          SliverAppBar(
            expandedHeight: update.hasImage ? 250 : 180,
            pinned: true,
            backgroundColor: ColorConstants.primaryBlue,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black26,
                child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: update.hasImage
                  ? Image.network(
                      update.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(update),
                    )
                  : _buildPlaceholder(update),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorConstants.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          update.category?.toUpperCase() ?? 'UPDATE',
                          style: TextStyles.labelSmall.copyWith(
                            color: ColorConstants.primaryOrange,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (update.isImportant) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'IMPORTANT',
                            style: TextStyles.labelSmall.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    update.title,
                    style: TextStyles.h3.copyWith(
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: ColorConstants.textHint),
                      const SizedBox(width: 6),
                      Text(
                        Formatters.formatDateFull(update.createdAt),
                        style: TextStyles.caption.copyWith(
                          color: ColorConstants.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                  Text(
                    update.description,
                    style: TextStyles.bodyLarge.copyWith(
                      color: ColorConstants.textPrimary.withValues(alpha: 0.85),
                      height: 1.6,
                      fontSize: 16,
                    ),
                  ),
                  
                  if (update.hasPdf) ...[
                    const SizedBox(height: 40),
                    _buildPdfButton(update),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(UpdateModel update) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.primaryBlue,
            ColorConstants.primaryBlue.withBlue(200),
          ],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.15,
          child: Image.asset(
            'assets/images/logo.png',
            width: 140,
            height: 140,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildPdfButton(UpdateModel update) {
    return InkWell(
      onTap: () {
        // Handle PDF opening logic
        if (update.pdfUrl != null) {
          // You can call your existing PDF viewer route here
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.picture_as_pdf, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View Document',
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    'Attached PDF document',
                    style: TextStyles.caption.copyWith(
                      color: Colors.red.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.red),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    final cat = category?.toLowerCase() ?? '';
    if (cat.contains('ferrous')) return Icons.factory_rounded;
    if (cat.contains('market')) return Icons.show_chart_rounded;
    if (cat.contains('price')) return Icons.monetization_on_rounded;
    return Icons.rss_feed_rounded;
  }
}
