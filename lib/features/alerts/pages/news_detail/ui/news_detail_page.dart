import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/constants/text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/news_detail_controller.dart';

class NewsDetailPage extends GetView<NewsDetailController> {
  const NewsDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const ShimmerListLoader();
        }

        return CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderImage(),
                  _buildContent(),
                  _buildRelatedNews(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        );
      }),
      floatingActionButton: _buildActionButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.arrow_back, color: ColorConstants.textPrimary),
      ),
      actions: [
        // PDF button - only show if news has PDF
        if (controller.newsItem.hasPdf)
          IconButton(
            onPressed: controller.openPdf,
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            tooltip: 'View PDF',
          ),
        Obx(() => IconButton(
          onPressed: controller.toggleSave,
          icon: Icon(
            controller.isSaved.value ? Icons.bookmark : Icons.bookmark_border,
            color: controller.isSaved.value
                ? ColorConstants.primaryOrange
                : ColorConstants.textPrimary,
          ),
        )),
        IconButton(
          onPressed: controller.shareArticle,
          icon: const Icon(Icons.share_outlined, color: ColorConstants.textPrimary),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeaderImage() {
    if (controller.newsItem.hasImage) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorConstants.primaryBlue.withOpacity(0.1),
        ),
        child: Image.network(
          controller.newsItem.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.image_outlined,
                size: 64,
                color: ColorConstants.textSecondary.withOpacity(0.5),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        ),
      );
    }

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ColorConstants.primaryBlue.withOpacity(0.1),
      ),
      child: Center(
        child: Icon(
          Icons.article_outlined,
          size: 64,
          color: ColorConstants.primaryBlue.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source and Date
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  controller.newsItem.sourceName,
                  style: TextStyles.bodySmall.copyWith(
                    color: ColorConstants.primaryOrange,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: ColorConstants.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.formatDate(controller.newsItem.publishedAt),
                    style: TextStyles.bodySmall.copyWith(
                      color: ColorConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            controller.newsItem.title,
            style: TextStyles.h3.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Author (if available)
          if (controller.newsItem.sourceLink != null)
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: ColorConstants.primaryBlue.withOpacity(0.1),
                  child: Icon(
                    Icons.person_outline,
                    color: ColorConstants.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Market Hub Editorial',
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Senior Analyst',
                      style: TextStyles.bodySmall.copyWith(
                        color: ColorConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 24),

          // Divider
          Container(
            height: 1,
            color: ColorConstants.borderColor,
          ),
          const SizedBox(height: 24),

          // Article Content
          Text(
            controller.newsItem.description,
            style: TextStyles.bodyMedium.copyWith(
              height: 1.8,
              color: ColorConstants.textPrimary,
            ),
          ),

          const SizedBox(height: 32),

          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag('Commodities'),
              _buildTag('Market Analysis'),
              _buildTag('Trading'),
              _buildTag('Metals'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ColorConstants.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstants.borderColor),
      ),
      child: Text(
        tag,
        style: TextStyles.bodySmall.copyWith(
          color: ColorConstants.textSecondary,
        ),
      ),
    );
  }

  Widget _buildRelatedNews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 1,
                color: ColorConstants.borderColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Related Articles',
                style: TextStyles.h4.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Obx(() => ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.relatedNews.length,
          itemBuilder: (context, index) {
            final news = controller.relatedNews[index];
            return _buildRelatedNewsCard(news);
          },
        )),
      ],
    );
  }

  Widget _buildRelatedNewsCard(dynamic news) {
    return GestureDetector(
      onTap: () => controller.openRelatedNews(news),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 70,
              decoration: BoxDecoration(
                color: ColorConstants.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: news.hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        news.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.article_outlined,
                            size: 32,
                            color: ColorConstants.primaryBlue.withOpacity(0.5),
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.article_outlined,
                      size: 32,
                      color: ColorConstants.primaryBlue.withOpacity(0.5),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.timeAgo(news.publishedAt),
                    style: TextStyles.caption.copyWith(
                      color: ColorConstants.textSecondary,
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

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: controller.shareArticle,
              icon: const Icon(Icons.share_outlined, size: 20),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.primaryBlue,
                side: const BorderSide(color: ColorConstants.primaryBlue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => ElevatedButton.icon(
              onPressed: controller.toggleSave,
              icon: Icon(
                controller.isSaved.value ? Icons.bookmark : Icons.bookmark_border,
                size: 20,
              ),
              label: Text(controller.isSaved.value ? 'Saved' : 'Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.isSaved.value
                    ? ColorConstants.primaryOrange
                    : ColorConstants.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }
}
