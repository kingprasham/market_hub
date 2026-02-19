import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  int currentStep = 0;

  final List<Map<String, dynamic>> tutorials = [
    {
      'title': 'View Live Prices',
      'description': 'Access real-time spot and futures prices for all major metals. Prices are updated every 30 seconds during market hours.',
      'icon': Icons.show_chart,
      'color': Colors.blue,
    },
    {
      'title': 'Create Watchlist',
      'description': 'Tap the star icon on any price to add it to your watchlist. Access your watchlist from the bottom navigation for quick monitoring.',
      'icon': Icons.star,
      'color': Colors.amber,
    },
    {
      'title': 'Set Price Alerts',
      'description': 'Create alerts to get notified when prices reach your target. Set conditions like "Above" or "Below" a specific price.',
      'icon': Icons.notifications_active,
      'color': Colors.green,
    },
    {
      'title': 'Stay Updated',
      'description': 'Read the latest market news, circulars, and economic calendar events. All content is available in both English and Hindi.',
      'icon': Icons.article,
      'color': Colors.orange,
    },
    {
      'title': 'Filter & Search',
      'description': 'Use filters to view prices by location, metal type, or exchange. Search for specific items across the entire app.',
      'icon': Icons.filter_list,
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: ColorConstants.textPrimary),
        ),
        title: Text(
          'Tutorial',
          style: TextStyles.h5.copyWith(color: ColorConstants.textPrimary),
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(
                tutorials.length,
                (index) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index <= currentStep
                          ? ColorConstants.primaryBlue
                          : ColorConstants.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Tutorial Content
          Expanded(
            child: PageView.builder(
              onPageChanged: (index) {
                setState(() {
                  currentStep = index;
                });
              },
              itemCount: tutorials.length,
              itemBuilder: (context, index) {
                final tutorial = tutorials[index];
                return _buildTutorialStep(tutorial);
              },
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                if (currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          currentStep--;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (currentStep < tutorials.length - 1) {
                        setState(() {
                          currentStep++;
                        });
                      } else {
                        Get.back();
                        Get.snackbar(
                          'Tutorial Complete',
                          'You\'re all set to use Market Hub!',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      currentStep < tutorials.length - 1 ? 'Next' : 'Get Started',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialStep(Map<String, dynamic> tutorial) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: (tutorial['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tutorial['icon'] as IconData,
              size: 60,
              color: tutorial['color'] as Color,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            tutorial['title'] as String,
            style: TextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            tutorial['description'] as String,
            style: TextStyles.bodyMedium.copyWith(
              color: ColorConstants.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
