import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

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
          'Contact Us',
          style: TextStyles.h4.copyWith(color: ColorConstants.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.headset_mic_outlined,
                      size: 36,
                      color: ColorConstants.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We\'re Here to Help',
                    style: TextStyles.h4,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get in touch with our support team',
                    style: TextStyles.bodyMedium.copyWith(
                      color: ColorConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Contact Options
            _buildContactOption(
              icon: Icons.phone_outlined,
              title: 'Phone',
              subtitle: '+91 98765 43210',
              onTap: () => _launchUrl('tel:+919876543210'),
            ),
            
            const SizedBox(height: 12),
            
            _buildContactOption(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: 'support@markethub.com',
              onTap: () => _launchUrl('mailto:support@markethub.com'),
            ),
            
            const SizedBox(height: 12),
            
            _buildContactOption(
              icon: Icons.chat_outlined,
              title: 'WhatsApp',
              subtitle: '+91 98765 43210',
              onTap: () => _launchUrl('https://wa.me/919876543210'),
            ),
            
            const SizedBox(height: 12),
            
            _buildContactOption(
              icon: Icons.language_outlined,
              title: 'Website',
              subtitle: 'www.markethubindia.com',
              onTap: () => _launchUrl('https://www.markethubindia.com'),
            ),
            
            const SizedBox(height: 24),
            
            // Office Address
            Container(
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
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: ColorConstants.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Office Address',
                        style: TextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Market Hub India Pvt. Ltd.\n'
                    '123, Business Tower\n'
                    'Nariman Point\n'
                    'Mumbai - 400021\n'
                    'Maharashtra, India',
                    style: TextStyles.bodyMedium.copyWith(
                      color: ColorConstants.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Business Hours
            Container(
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
                        child: const Icon(
                          Icons.access_time_outlined,
                          color: ColorConstants.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Business Hours',
                        style: TextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildHoursRow('Monday - Friday', '9:00 AM - 6:00 PM'),
                  const SizedBox(height: 8),
                  _buildHoursRow('Saturday', '10:00 AM - 2:00 PM'),
                  const SizedBox(height: 8),
                  _buildHoursRow('Sunday', 'Closed'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ColorConstants.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: ColorConstants.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyles.bodyMedium.copyWith(
                      color: ColorConstants.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: ColorConstants.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursRow(String day, String hours) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: TextStyles.bodyMedium.copyWith(
            color: ColorConstants.textSecondary,
          ),
        ),
        Text(
          hours,
          style: TextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
