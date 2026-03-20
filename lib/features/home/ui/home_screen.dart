import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/market/price_change_model.dart';
import '../../../shared/widgets/loaders/shimmer_loader.dart';
import '../controller/home_controller.dart';
import '../data/ad_data.dart';
import 'widgets/side_menu.dart';
import 'package:market_hub_new/shared/widgets/common/app_logo.dart';

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
            const AppLogo(size: 36, iconSize: 24, borderRadius: 10),
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


              // ─── Live Prices Section ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildLivePricesSection(),
              ),

              // ─── Home Updates Section ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildHomeUpdatesSection(),
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
    return Obx(() {
      final adsList = controller.dynamicAds;
      if (adsList.isEmpty) return const SizedBox.shrink();

      return Column(
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              itemCount: adsList.length,
              controller: controller.adPageController,
              onPageChanged: (index) {
                controller.currentAdPage.value = index;
              },
              itemBuilder: (context, index) {
                final ad = adsList[index];
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
                      ad.imagePath.startsWith('http')
                          ? Image.network(
                              ad.imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/1.jpeg',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
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
          children: List.generate(adsList.length, (index) {
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
  });
}

  // ─── Live Prices Section (shows only changed prices) ──────────────────────


  Widget _buildLivePricesSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Gradient header ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorConstants.primaryBlue.withOpacity(0.08),
                  ColorConstants.primaryOrange.withOpacity(0.06),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ColorConstants.blueGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Non-Ferrous Updates', style: TextStyles.h5),
                      Text(
                        'Metals with changed prices today',
                        style: TextStyles.caption.copyWith(
                          color: ColorConstants.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Get.toNamed(AppRoutes.nonFerrousUpdates),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'View All',
                      style: TextStyles.bodySmall.copyWith(
                        color: ColorConstants.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildPulseDot(),
              ],
            ),
          ),

          const Divider(height: 1, color: ColorConstants.dividerColor),

          // ─── Changed price rows (Non-Ferrous Only) ──────────────────
          Obx(() {
            final changes = controller.priceChanges
                    .where((c) => c.category == 'Non-Ferrous')
                    .toList();

            if (changes.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 36,
                        color: ColorConstants.textHint.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No price changes yet',
                        style: TextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.textHint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Non-Ferrous prices will appear here',
                        style: TextStyles.caption.copyWith(
                          color: ColorConstants.textHint,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                ...changes.take(4).map((c) => _buildChangeRow(c)),
              ],
            );
          }),

          // ─── View All CTA ─────────────────────────────────────────────
          InkWell(
            onTap: () => Get.toNamed(AppRoutes.nonFerrousUpdates),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: ColorConstants.primaryBlue.withOpacity(0.04),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View All Changes',
                    style: TextStyles.bodySmall.copyWith(
                      color: ColorConstants.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: ColorConstants.primaryBlue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Row for a single price change — shows old → new, city badge, category.
  Widget _buildChangeRow(PriceChange change) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ColorConstants.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _categoryColor(change.category).withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _categoryIcon(change.category),
              size: 16,
              color: _categoryColor(change.category),
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
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (change.city.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
                  fontSize: 13,
                ),
              ),
              Text(
                change.oldPrice,
                style: TextStyles.labelSmall.copyWith(
                  color: ColorConstants.textHint,
                  fontSize: 9,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tiny animated green dot indicating live data.
  Widget _buildPulseDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      builder: (context, opac, child) {
        return Opacity(
          opacity: opac,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: ColorConstants.positiveGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.positiveGreen.withOpacity(0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Ferrous': return ColorConstants.primaryBlue;
      case 'Non-Ferrous': return ColorConstants.primaryOrange;
      case 'Minor Metals': return Colors.teal;
      case 'Bullion': return Colors.amber.shade700;
      default: return ColorConstants.textSecondary;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Ferrous': return Icons.factory_outlined;
      case 'Non-Ferrous': return Icons.diamond_outlined;
      case 'Minor Metals': return Icons.science_outlined;
      case 'Bullion': return Icons.monetization_on_outlined;
      default: return Icons.bar_chart_rounded;
    }
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

  Widget _buildHomeUpdatesSection() {
    return Obx(() {
      final updates = controller.homeUpdates;
      // If we are loading and have no updates yet, show nothing or a subtle loader
      if (controller.isLoading.value && updates.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Market Hub Updates',
                          style: TextStyles.h3.copyWith(
                            color: ColorConstants.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Latest insights & announcements',
                          style: TextStyles.caption.copyWith(
                            color: ColorConstants.textHint,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: ColorConstants.dividerColor),

            // ─── Update List (Top 3) ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: updates.take(3).length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: ColorConstants.dividerColor,
                ),
                itemBuilder: (context, index) {
                  final update = updates[index];
                  return InkWell(
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
                    child: Padding(
                      padding: const EdgeInsets.all(20),
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
                                        child: Text(
                                          'NEW',
                                          style: TextStyles.labelSmall.copyWith(
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
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  update.description,
                                  style: TextStyles.bodySmall.copyWith(
                                    color: ColorConstants.textSecondary,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 12,
                                      color: ColorConstants.textHint.withValues(alpha: 0.8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      Formatters.formatRelativeTime(update.createdAt),
                                      style: TextStyles.labelSmall.copyWith(
                                        color: ColorConstants.textHint,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (update.hasPdf) ...[
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.picture_as_pdf_outlined,
                                        size: 14,
                                        color: Colors.red.withValues(alpha: 0.7),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'PDF Attached',
                                        style: TextStyles.labelSmall.copyWith(
                                          color: Colors.red.withValues(alpha: 0.7),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                                width: 70,
                                height: 70,
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
                  );
                },
              ),
            ),

            // ─── View All CTA ─────────────────────────────────────────────
            if (updates.length > 3)
              InkWell(
                onTap: () {
                  Get.toNamed(AppRoutes.allUpdates);
                },
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryOrange.withValues(alpha: 0.04),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View All Updates',
                        style: TextStyles.bodySmall.copyWith(
                          color: ColorConstants.primaryOrange,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.keyboard_arrow_right_rounded,
                        size: 18,
                        color: ColorConstants.primaryOrange,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildUpdatePlaceholder(String? category) {
    return Container(
      width: 70,
      height: 70,
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
        child: Image.asset(
          'assets/images/logo.png',
          width: 35,
          height: 35,
          fit: BoxFit.contain,
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
