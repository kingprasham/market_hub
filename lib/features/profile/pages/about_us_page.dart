import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back,
            color: ColorConstants.textPrimary,
          ),
        ),
        title: Text(
          'About Us',
          style: TextStyles.h4.copyWith(color: ColorConstants.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: ColorConstants.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  'MH',
                  style: TextStyles.h1.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Market Hub',
              style: TextStyles.h3,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Your Real-Time Market Companion',
              style: TextStyles.bodyMedium.copyWith(
                color: ColorConstants.textSecondary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // About Card
            _buildInfoCard(
              title: 'Our Mission',
              content: 'Market Hub provides real-time commodity and metal market data to traders, investors, and industry professionals. We deliver accurate, timely information to help you make informed decisions.',
              icon: Icons.flag_outlined,
            ),
            
            const SizedBox(height: 16),
            
            _buildInfoCard(
              title: 'What We Offer',
              content: '• Real-time LME, SHFE, COMEX futures data\n• Live spot prices for base metals\n• FX rates and reference rates\n• Breaking market news and circulars\n• Economic calendar events\n• Customizable watchlists',
              icon: Icons.star_outline,
            ),
            
            const SizedBox(height: 16),
            
            _buildInfoCard(
              title: 'Our Vision',
              content: 'To become the leading platform for commodity market intelligence, empowering users with comprehensive data and insights for successful trading.',
              icon: Icons.visibility_outlined,
            ),
            
            const SizedBox(height: 32),
            
            // Version Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'App Version',
                    style: TextStyles.bodyMedium.copyWith(
                      color: ColorConstants.textSecondary,
                    ),
                  ),
                  Text(
                    '1.0.0',
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              '© 2024 Market Hub India. All rights reserved.',
              style: TextStyles.caption.copyWith(
                color: ColorConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ColorConstants.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: ColorConstants.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyles.bodyMedium.copyWith(
              color: ColorConstants.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
