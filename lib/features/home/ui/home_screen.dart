import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/loaders/shimmer_loader.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/home_controller.dart';
import '../data/ad_data.dart';
import '../data/market_update_data.dart';
import 'widgets/side_menu.dart';
import 'widgets/market_report_dialog.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      drawer: const SideMenu(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ColorConstants.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Market Hub',
              style: TextStyles.h4.copyWith(
                color: ColorConstants.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.search),
            icon: const Icon(
              Icons.search,
              color: ColorConstants.textPrimary,
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () => Get.toNamed(AppRoutes.notifications),
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: ColorConstants.textPrimary,
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: ColorConstants.negativeRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.profile),
            icon: const Icon(
              Icons.person_outline,
              color: ColorConstants.textPrimary,
            ),
          ),
        ],
      ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const ShimmerListLoader();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshUpdates,
          color: ColorConstants.primaryBlue,
          child: CustomScrollView(
            slivers: [
              // Welcome Header
              SliverToBoxAdapter(
                child: _buildWelcomeHeader(),
              ),
              
              // Ad Carousel
              SliverToBoxAdapter(
                child: _buildAdCarousel(),
              ),

              // Starred Watchlist Section (below ads)
              SliverToBoxAdapter(
                child: Obx(() {
                  if (controller.starredItems.isEmpty) return const SizedBox.shrink();
                  return _buildStarredWatchlistSection();
                }),
              ),

              // Updates Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Latest Updates',
                        style: TextStyles.h5,
                      ),
                      TextButton(
                        onPressed: () {
                          Get.toNamed(AppRoutes.allUpdates);
                        },
                        child: Text(
                          'View All',
                          style: TextStyles.bodySmall.copyWith(
                            color: ColorConstants.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Updates List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: controller.updates.isEmpty
                    ? SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 48,
                                color: ColorConstants.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No updates available',
                                style: TextStyles.bodyMedium.copyWith(
                                  color: ColorConstants.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pull down to refresh',
                                style: TextStyles.caption.copyWith(
                                  color: ColorConstants.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final update = controller.updates[index];
                            return _buildUpdateCard(update);
                          },
                          childCount: controller.updates.length > 3 ? 3 : controller.updates.length,
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

  Widget _buildWelcomeHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ColorConstants.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Text(
            'Welcome back, ${controller.user.value?.fullName ?? 'Trader'}!',
            style: TextStyles.h5.copyWith(color: Colors.white),
          )),
          const SizedBox(height: 8),
          Text(
            'Stay updated with real-time market insights',
            style: TextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHeaderAction(
                  icon: Icons.notifications_active_outlined,
                  label: 'Set Alert',
                  onTap: () => Get.toNamed(AppRoutes.priceAlerts),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeaderAction(
                  icon: Icons.bookmark_border,
                  label: 'Saved Items',
                  onTap: () => Get.toNamed(AppRoutes.savedItems),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: allAds.length,
            controller: controller.adPageController,
            onPageChanged: (index) {
              controller.currentAdPage.value = index;
            },
            itemBuilder: (context, index) {
              final ad = allAds[index];
              return Container(
                margin: EdgeInsets.only(right: 12, left: index == 0 ? 16 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image — each ad uses its own image
                      Image.asset(
                        ad.imagePath,
                        fit: BoxFit.cover,
                      ),

                      // Dark gradient overlay for readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.15),
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'AD',
                                style: TextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ad.carouselTitle,
                              style: TextStyles.h5.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ad.carouselSubtitle,
                              style: TextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => Get.toNamed(
                                AppRoutes.adDetail,
                                arguments: ad,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Learn More',
                                  style: TextStyles.bodySmall.copyWith(
                                    color: ColorConstants.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dot indicators
        Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(allAds.length, (index) {
            final isActive = controller.currentAdPage.value == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isActive
                    ? ColorConstants.primaryBlue
                    : ColorConstants.primaryBlue.withOpacity(0.3),
              ),
            );
          }),
        )),
      ],
    );
  }





  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyles.h5.copyWith(fontSize: 18),
            ),
            if (onTap != null)
              const Icon(Icons.arrow_forward_ios, size: 16, color: ColorConstants.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateCard(dynamic update) {
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
          // Check if this is the special Copper Report
          if (update.title == copperReport.title) {
            Get.dialog(MarketReportDialog(report: copperReport));
            return;
          }

          Get.dialog(
            AlertDialog(
              title: Text(update.title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Category', update.category),
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
                  color: _getCategoryColor(update.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  update.category,
                  style: TextStyles.caption.copyWith(
                    color: _getCategoryColor(update.category),
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
  Widget _buildHeaderAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarredWatchlistSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFC107), size: 18),
                    const SizedBox(width: 6),
                    Text('My Watchlist', style: TextStyles.h5),
                  ],
                ),
                TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.watchlist),
                  child: Text(
                    'View All',
                    style: TextStyles.bodySmall.copyWith(
                      color: ColorConstants.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal scrollable cards
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: controller.starredItems.length,
              itemBuilder: (context, index) {
                return Obx(() {
                  // Obx re-evaluates when starredItems changes, giving live updates
                  if (index >= controller.starredItems.length) return const SizedBox.shrink();
                  final item = controller.starredItems[index];
                  return _buildStarredItemCard(item);
                });
              },
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStarredItemCard(dynamic item) {
    final isPositive = (item.change ?? 0) >= 0;
    final changeColor = isPositive ? const Color(0xFF1E8449) : const Color(0xFFC0392B);
    final bgColor = isPositive
        ? const Color(0xFFF0FFF4)
        : const Color(0xFFFFF5F5);

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.watchlist),
      child: Container(
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: ColorConstants.borderColor.withOpacity(0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Name + type badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.symbol,
                    style: TextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (item.itemType ?? item.type ?? '').toUpperCase().isNotEmpty
                        ? (item.itemType ?? item.type ?? '').substring(0, ((item.itemType ?? item.type ?? '').length < 4 ? (item.itemType ?? item.type ?? '').length : 4))
                        : '--',
                    style: TextStyles.caption.copyWith(
                      color: ColorConstants.primaryBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),

            // Price
            Text(
              item.price != null
                  ? '${item.currency == 'INR' ? '₹' : '\$'}${Formatters.formatCompactNumber(item.price!)}'
                  : '--',
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: ColorConstants.textPrimary,
              ),
            ),

            // Change
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: changeColor,
                    size: 14,
                  ),
                  Text(
                    item.changePercent != null
                        ? '${item.changePercent!.abs().toStringAsFixed(2)}%'
                        : '0.00%',
                    style: TextStyles.caption.copyWith(
                      color: changeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
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
}
