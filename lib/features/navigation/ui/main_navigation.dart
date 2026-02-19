import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../controller/navigation_controller.dart';
import '../../home/ui/home_screen.dart';
import '../../future/ui/future_screen.dart';
import '../../spot_price/ui/spot_price_screen.dart';
import '../../alerts/ui/alerts_screen.dart';
import '../../watchlist/ui/watchlist_screen.dart';

class MainNavigation extends GetView<NavigationController> {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: controller.pageController,
        onPageChanged: controller.onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          HomeScreen(),
          FutureScreen(),
          SpotPriceScreen(),
          AlertsScreen(),
          WatchlistScreen(),
        ],
      ),
      bottomNavigationBar: Obx(() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(1, Icons.show_chart_outlined, Icons.show_chart, 'Future'),
                _buildNavItem(2, Icons.currency_exchange_outlined, Icons.currency_exchange, 'Spot'),
                _buildNavItem(3, Icons.article_outlined, Icons.article, 'News'),
                _buildNavItem(4, Icons.star_outline, Icons.star, 'Watchlist'),
              ],
            ),
          ),
        ),
      )),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = controller.currentIndex.value == index;

    return GestureDetector(
      onTap: () => controller.changePage(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorConstants.primaryBlue.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? ColorConstants.primaryBlue
                  : ColorConstants.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? ColorConstants.primaryBlue
                    : ColorConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
