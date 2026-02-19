import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';

class HelpFaqPage extends StatelessWidget {
  const HelpFaqPage({super.key});

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
          'Help & FAQ',
          style: TextStyles.h5.copyWith(color: ColorConstants.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for help...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Quick Help Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Quick Help',
                style: TextStyles.h6.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildQuickHelpCard(Icons.phone_outlined, 'Contact Us', Colors.blue),
                  _buildQuickHelpCard(Icons.email_outlined, 'Email Support', Colors.green),
                  _buildQuickHelpCard(Icons.chat_outlined, 'Live Chat', Colors.orange),
                  _buildQuickHelpCard(Icons.video_library_outlined, 'Video Guides', Colors.purple),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // FAQ Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Frequently Asked Questions',
                style: TextStyles.h6.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),

            _buildFaqItem(
              'How do I update my subscription?',
              'Go to Profile > Subscription to view and manage your current plan. You can upgrade or downgrade your subscription at any time. Changes will take effect from your next billing cycle.',
            ),
            _buildFaqItem(
              'How are prices updated?',
              'Our prices are updated in real-time from various exchanges and market sources. Spot prices are updated every 30 seconds during market hours, while futures prices follow exchange timings.',
            ),
            _buildFaqItem(
              'How do I set up price alerts?',
              'Navigate to Price Alerts from the home screen or profile. Tap "New Alert" to create an alert for any metal. Set your target price and condition (above/below), and you\'ll receive notifications when prices match.',
            ),
            _buildFaqItem(
              'Can I export data?',
              'Data export is available for Enterprise plan subscribers. Go to Settings > Export Data to download price history, watchlist data, and more in CSV or Excel formats.',
            ),
            _buildFaqItem(
              'How do I add items to my watchlist?',
              'Tap the star icon on any price card to add it to your watchlist. You can access your watchlist from the bottom navigation bar or from the home screen quick access.',
            ),
            _buildFaqItem(
              'What payment methods are accepted?',
              'We accept all major credit/debit cards, UPI, net banking, and popular wallets. For Enterprise plans, we also support bank transfers and invoicing.',
            ),

            const SizedBox(height: 24),

            // Contact Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: ColorConstants.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent, size: 48, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Still need help?',
                    style: TextStyles.h5.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our support team is available 24/7',
                    style: TextStyles.bodySmall.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Get.snackbar('Contact Support', 'Support request initiated',
                          snackPosition: SnackPosition.BOTTOM);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: ColorConstants.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Contact Support'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickHelpCard(IconData icon, String label, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyles.caption.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyles.bodySmall.copyWith(
                color: ColorConstants.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
