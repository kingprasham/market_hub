import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
          'Privacy Policy',
          style: TextStyles.h5.copyWith(color: ColorConstants.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorConstants.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: ColorConstants.primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Last updated: December 2024',
                      style: TextStyles.bodySmall.copyWith(
                        color: ColorConstants.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              'Introduction',
              'Welcome to Market Hub. We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
            ),

            _buildSection(
              'Information We Collect',
              '''We collect information that you provide directly to us, including:
              
• Account Information: Name, email address, phone number, company details
• Profile Information: Business type, preferences, watchlist items
• Usage Data: App interactions, feature usage, price alerts
• Device Information: Device ID, operating system, app version
• Location Data: General location for regional pricing (with your consent)''',
            ),

            _buildSection(
              'How We Use Your Information',
              '''We use the collected information to:
              
• Provide and maintain our services
• Personalize your experience with relevant content
• Send price alerts and notifications you've set up
• Improve our app functionality and user experience
• Communicate updates, offers, and support
• Ensure security and prevent fraud''',
            ),

            _buildSection(
              'Data Sharing',
              '''We may share your information with:
              
• Service Providers: Third-party vendors who assist in app operations
• Business Partners: With your consent for joint offerings
• Legal Requirements: When required by law or to protect rights
              
We do NOT sell your personal information to third parties.''',
            ),

            _buildSection(
              'Data Security',
              'We implement industry-standard security measures to protect your data, including encryption, secure servers, and regular security audits. However, no method of transmission over the Internet is 100% secure.',
            ),

            _buildSection(
              'Your Rights',
              '''You have the right to:
              
• Access your personal data
• Correct inaccurate information
• Delete your account and data
• Opt-out of marketing communications
• Export your data
• Restrict certain data processing''',
            ),

            _buildSection(
              'Cookies & Tracking',
              'We use cookies and similar tracking technologies to improve your experience, analyze usage patterns, and personalize content. You can manage cookie preferences in your device settings.',
            ),

            _buildSection(
              'Children\'s Privacy',
              'Our service is not intended for users under 18 years of age. We do not knowingly collect information from children under 18.',
            ),

            _buildSection(
              'Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of significant changes through the app or via email. Continued use of the app after changes constitutes acceptance.',
            ),

            _buildSection(
              'Contact Us',
              '''If you have questions about this Privacy Policy, please contact us:
              
Email: privacy@markethub.com
Phone: +91 1800-XXX-XXXX
Address: Mumbai, India''',
            ),

            const SizedBox(height: 32),

            // Accept Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('I Understand'),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
            style: TextStyles.h6.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyles.bodySmall.copyWith(
              color: ColorConstants.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
