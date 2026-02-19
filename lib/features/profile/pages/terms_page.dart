import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

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
          'Terms & Conditions',
          style: TextStyles.h4.copyWith(color: ColorConstants.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            
            Text(
              'Last Updated: December 2024',
              style: TextStyles.caption.copyWith(
                color: ColorConstants.textSecondary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildSection(
              '1. Acceptance of Terms',
              'By downloading, installing, or using the Market Hub application, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our services.',
            ),
            
            _buildSection(
              '2. Description of Service',
              'Market Hub provides real-time commodity and metal market data, including futures prices, spot prices, FX rates, and market news. The service is provided on an "as is" basis.',
            ),
            
            _buildSection(
              '3. User Registration',
              'To access certain features, you must register for an account. You agree to:\n'
              '• Provide accurate and complete information\n'
              '• Maintain the security of your PIN\n'
              '• Notify us of any unauthorized use\n'
              '• Accept responsibility for all activities under your account',
            ),
            
            _buildSection(
              '4. Subscription and Payment',
              'Certain features require a paid subscription. By subscribing, you agree to:\n'
              '• Pay all applicable fees\n'
              '• Provide valid payment information\n'
              '• Accept automatic renewal unless cancelled\n'
              '• Receive no refunds for partial subscription periods',
            ),
            
            _buildSection(
              '5. Data Accuracy',
              'While we strive to provide accurate market data, we do not guarantee:\n'
              '• Real-time accuracy of all data\n'
              '• Completeness of market information\n'
              '• Suitability for specific trading decisions\n\n'
              'Market data is sourced from third-party providers and may be subject to delays.',
            ),
            
            _buildSection(
              '6. Prohibited Uses',
              'You agree not to:\n'
              '• Share your account credentials\n'
              '• Use the app for illegal activities\n'
              '• Attempt to reverse engineer the app\n'
              '• Redistribute market data commercially\n'
              '• Take screenshots or record protected content',
            ),
            
            _buildSection(
              '7. Intellectual Property',
              'All content, features, and functionality of Market Hub are owned by Market Hub India Pvt. Ltd. and are protected by international copyright, trademark, and other intellectual property laws.',
            ),
            
            _buildSection(
              '8. Limitation of Liability',
              'Market Hub and its affiliates shall not be liable for:\n'
              '• Trading losses based on our data\n'
              '• Service interruptions\n'
              '• Data inaccuracies\n'
              '• Any indirect or consequential damages',
            ),
            
            _buildSection(
              '9. Privacy Policy',
              'Your use of Market Hub is also governed by our Privacy Policy. By using our services, you consent to the collection and use of your data as described therein.',
            ),
            
            _buildSection(
              '10. Modifications',
              'We reserve the right to modify these terms at any time. Continued use of the service after changes constitutes acceptance of the new terms.',
            ),
            
            _buildSection(
              '11. Governing Law',
              'These terms are governed by the laws of India. Any disputes shall be subject to the exclusive jurisdiction of the courts in Mumbai, Maharashtra.',
            ),
            
            _buildSection(
              '12. Contact Information',
              'For questions about these Terms, please contact us at:\n'
              'Email: legal@markethub.com\n'
              'Phone: +91 98765 43210',
            ),
            
            const SizedBox(height: 32),
            
            Center(
              child: Text(
                '© 2024 Market Hub India Pvt. Ltd.',
                style: TextStyles.caption.copyWith(
                  color: ColorConstants.textSecondary,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyles.bodyMedium.copyWith(
              color: ColorConstants.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
