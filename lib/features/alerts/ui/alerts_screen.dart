import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/alerts_controller.dart';
import '../../../app/routes/app_routes.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../home/ui/widgets/side_menu.dart';

class AlertsScreen extends GetView<AlertsController> {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        if (controller.selectedTabIndex.value == 0) { // Live Feed Tab
          final canGoBack = await controller.liveFeedWebController.canGoBack();
          if (canGoBack) {
            controller.liveFeedWebController.goBack();
            return;
          }
        }
        
        // Show exit confirmation dialog
        if (context.mounted) {
          _showExitDialog(context);
        }
      },
      child: Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      drawer: const SideMenu(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'News & Alerts',
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

          // New Content Banner
          Obx(() {
            if (!controller.hasNewContent.value) return const SizedBox.shrink();
            return GestureDetector(
              onTap: controller.loadNewContent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ColorConstants.primaryBlue,
                      ColorConstants.primaryBlue.withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      controller.newContentCount.value > 0
                          ? 'Tap to load ${controller.newContentCount.value} new update${controller.newContentCount.value > 1 ? 's' : ''}'
                          : 'New content available',
                      style: TextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          }),

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
      ),
    );
  }

  Widget _buildTabItem(int index) {
    final isSelected = controller.selectedTabIndex.value == index;
    final icons = [
      Icons.bolt,
      Icons.article,
      Icons.translate,
      Icons.description,
      Icons.calendar_month,
    ];

    return GestureDetector(
      onTap: () => controller.changeTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? ColorConstants.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? ColorConstants.primaryBlue
                : ColorConstants.borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icons[index],
              size: 16,
              color: isSelected ? Colors.white : ColorConstants.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              controller.tabs[index],
              style: TextStyles.bodySmall.copyWith(
                color: isSelected ? Colors.white : ColorConstants.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (controller.selectedTabIndex.value) {
      case 0:
        return _buildLiveFeedContent();
      case 1:
        return _buildNewsContent();
      case 2:
        return _buildHindiNewsContent();
      case 3:
        return _buildCircularsContent();
      case 4:
        return _buildEconomicCalendarContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLiveFeedContent() {
    return WebViewWidget(controller: controller.liveFeedWebController);
  }

  Widget _buildNewsContent() {
    return Obx(() {
      if (controller.news.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.article_outlined,
                size: 64,
                color: ColorConstants.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No news available',
                style: TextStyles.bodyMedium.copyWith(
                  color: ColorConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for updates',
                style: TextStyles.caption.copyWith(
                  color: ColorConstants.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.news.length,
        itemBuilder: (context, index) {
          final item = controller.news[index];
          return _buildNewsCard(item);
        },
      );
    });
  }

  Widget _buildHindiNewsContent() {
    return Obx(() {
      if (controller.hindiNews.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.translate_outlined,
                size: 64,
                color: ColorConstants.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'कोई समाचार उपलब्ध नहीं',
                style: TextStyles.bodyMedium.copyWith(
                  color: ColorConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'बाद में अपडेट के लिए जांचें',
                style: TextStyles.caption.copyWith(
                  color: ColorConstants.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.hindiNews.length,
        itemBuilder: (context, index) {
          final item = controller.hindiNews[index];
          return _buildNewsCard(item, isHindi: true);
        },
      );
    });
  }

  Widget _buildCircularsContent() {
    return Obx(() {
      if (controller.circulars.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 64,
                color: ColorConstants.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No circulars available',
                style: TextStyles.bodyMedium.copyWith(
                  color: ColorConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for updates',
                style: TextStyles.caption.copyWith(
                  color: ColorConstants.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.circulars.length,
        itemBuilder: (context, index) {
          final item = controller.circulars[index];
          return _buildCircularCard(item);
        },
      );
    });
  }

  Widget _buildEconomicCalendarContent() {
    return WebViewWidget(controller: controller.calendarWebController);
  }

  Widget _buildLoadMoreButton() {
    return Obx(() {
      if (!controller.hasMoreItems.value) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No more items to load',
              style: TextStyles.bodySmall.copyWith(
                color: ColorConstants.textSecondary,
              ),
            ),
          ),
        );
      }

      if (controller.isLoadingMore.value) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(ColorConstants.primaryBlue),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(16),
        child: OutlinedButton.icon(
          onPressed: controller.loadMoreItems,
          icon: const Icon(Icons.expand_more, size: 20),
          label: Text('Load More (Page ${controller.currentPage.value + 1})'),
          style: OutlinedButton.styleFrom(
            foregroundColor: ColorConstants.primaryBlue,
            side: BorderSide(color: ColorConstants.primaryBlue),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLiveFeedCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item.isUrgent
                      ? ColorConstants.negativeRed
                      : ColorConstants.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 60,
                color: ColorConstants.borderColor,
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: item.isUrgent
                    ? Border.all(color: ColorConstants.negativeRed.withOpacity(0.3))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: ColorConstants.negativeRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'URGENT',
                            style: TextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      Text(
                        Formatters.timeAgo(item.timestamp),
                        style: TextStyles.caption.copyWith(
                          color: ColorConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.content,
                    style: TextStyles.bodySmall.copyWith(
                      color: ColorConstants.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(dynamic item, {bool isHindi = false}) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.newsDetail, arguments: item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or placeholder
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: ColorConstants.primaryBlue.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: item.hasImage
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.article_outlined,
                              size: 48,
                              color: ColorConstants.primaryBlue.withOpacity(0.5),
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
                              strokeWidth: 2,
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.article_outlined,
                        size: 48,
                        color: ColorConstants.primaryBlue.withOpacity(0.5),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ColorConstants.primaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.sourceName,
                            style: TextStyles.caption.copyWith(
                              color: ColorConstants.primaryOrange,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Formatters.timeAgo(item.timestamp),
                        style: TextStyles.caption.copyWith(
                          color: ColorConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.title,
                    style: TextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.content,
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
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.newsDetail, arguments: item),
                        child: Text(
                          'Read More',
                          style: TextStyles.bodySmall.copyWith(
                            color: ColorConstants.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // PDF button - only shown if item has PDF
                      if (item.hasPdf)
                        IconButton(
                          onPressed: () => Get.toNamed(AppRoutes.pdfViewer, arguments: item),
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'View PDF',
                        ),
                      if (item.hasPdf) const SizedBox(width: 12),
                      // Share button
                      IconButton(
                        onPressed: () {
                          final StringBuffer shareText = StringBuffer();
                          shareText.writeln(item.title);
                          shareText.writeln();
                          
                          // Truncate description to 100 characters
                          String description = item.description;
                          if (description.length > 100) {
                            description = '${description.substring(0, 100)}...';
                          }
                          shareText.writeln(description);
                          shareText.writeln();
                          
                          // Add App Link
                          shareText.write('Read full story on Market Hub app:\nhttps://play.google.com/store/apps/details?id=com.markethub.app');
                          
                          Share.share(shareText.toString(), subject: item.title);
                        },
                        icon: const Icon(Icons.share_outlined),
                        iconSize: 20,
                        color: ColorConstants.textSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.bookmark_border),
                        iconSize: 20,
                        color: ColorConstants.textSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularCard(dynamic item) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.pdfViewer, arguments: item),
      child: Container(
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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        item.newsType.toUpperCase(),
                        style: TextStyles.caption.copyWith(
                          color: ColorConstants.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyles.caption.copyWith(
                          color: ColorConstants.textSecondary,
                        ),
                      ),
                      Text(
                        Formatters.formatDate(item.publishedAt),
                        style: TextStyles.caption.copyWith(
                          color: ColorConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Get.toNamed(AppRoutes.pdfViewer, arguments: item),
              icon: const Icon(Icons.download_outlined),
              color: ColorConstants.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEconomicEventCard(dynamic item) {
    final isUpcoming = item.publishedAt.isAfter(DateTime.now());
    final importance = item.newsType == 'economic' ? 'high' : 'medium';

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.eventDetail, arguments: item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: importance == 'high'
                ? ColorConstants.primaryOrange.withOpacity(0.3)
                : ColorConstants.borderColor,
          ),
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
            // Date Column
            Container(
              width: 60,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isUpcoming
                    ? ColorConstants.primaryBlue.withOpacity(0.1)
                    : ColorConstants.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    Formatters.formatDayOfMonth(item.publishedAt),
                    style: TextStyles.h4.copyWith(
                      color: isUpcoming
                          ? ColorConstants.primaryBlue
                          : ColorConstants.textSecondary,
                    ),
                  ),
                  Text(
                    Formatters.formatMonth(item.publishedAt),
                    style: TextStyles.caption.copyWith(
                      color: isUpcoming
                          ? ColorConstants.primaryBlue
                          : ColorConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCountryColor(_getCountryFromTitle(item.title)).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getCountryFromTitle(item.title),
                          style: TextStyles.caption.copyWith(
                            color: _getCountryColor(_getCountryFromTitle(item.title)),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (importance == 'high')
                        Row(
                          children: List.generate(
                            3,
                            (index) => Icon(
                              Icons.star,
                              size: 12,
                              color: ColorConstants.primaryOrange,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyles.bodySmall.copyWith(
                      color: ColorConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined),
              color: ColorConstants.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _getCountryFromTitle(String title) {
    if (title.contains('US') || title.contains('Fed')) return 'USA';
    if (title.contains('China') || title.contains('Chinese')) return 'China';
    if (title.contains('India') || title.contains('RBI')) return 'India';
    if (title.contains('ECB') || title.contains('Euro')) return 'Eurozone';
    if (title.contains('UK') || title.contains('BOE')) return 'UK';
    if (title.contains('Japan') || title.contains('BOJ')) return 'Japan';
    return 'Global';
  }

  Color _getCountryColor(String country) {
    switch (country) {
      case 'USA':
        return Colors.blue;
      case 'China':
        return Colors.red;
      case 'India':
        return Colors.orange;
      case 'Eurozone':
        return Colors.indigo;
      case 'UK':
        return Colors.purple;
      case 'Japan':
        return Colors.pink;
      default:
        return ColorConstants.primaryBlue;
    }
  }


  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to close the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Close dialog
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              SystemNavigator.pop(); // Exit app
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}
