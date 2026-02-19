import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../data/ad_data.dart';

class AdDetailScreen extends StatelessWidget {
  const AdDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve the ad data passed as argument
    final AdData ad = Get.arguments as AdData? ?? allAds.first;

    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Standard AppBar
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black26,
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              ad.companyName,
              style: TextStyles.h6.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          // Image as first item in body (full width, no crop)
          SliverToBoxAdapter(
            child: Image.asset(
              ad.imagePath,
              fit: BoxFit.fitWidth,
              width: double.infinity,
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: ColorConstants.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ad.companyName,
                      style: TextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Heading
                  Text(
                    ad.heading,
                    style: TextStyles.h4.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info cards
                  ...ad.infoItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildInfoCard(
                      icon: _getIcon(item.iconName),
                      title: item.title,
                      description: item.description,
                    ),
                  )),

                  const SizedBox(height: 20),

                  // Disclaimer if present
                  if (ad.disclaimer != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange.shade700, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ad.disclaimer!,
                              style: TextStyles.caption.copyWith(
                                color: Colors.orange.shade800,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Divider
                  const Divider(),
                  const SizedBox(height: 16),

                  // Contact section
                  Text(
                    'Contact Us',
                    style: TextStyles.h5.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contact tiles
                  ...ad.contacts.map((contact) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildContactTile(
                      icon: _getContactIcon(contact.type),
                      label: contact.label,
                      color: _getContactColor(contact.type),
                      onTap: () async {
                        final uri = Uri.parse(contact.uri);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  )),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'factory':
        return Icons.precision_manufacturing_outlined;
      case 'verified':
        return Icons.verified_outlined;
      case 'search':
        return Icons.search_outlined;
      case 'location':
        return Icons.location_on_outlined;
      case 'document':
        return Icons.description_outlined;
      default:
        return Icons.info_outlined;
    }
  }

  IconData _getContactIcon(String type) {
    switch (type) {
      case 'phone':
        return Icons.phone_outlined;
      case 'email':
        return Icons.email_outlined;
      case 'website':
        return Icons.language_outlined;
      case 'whatsapp':
        return Icons.chat_outlined;
      default:
        return Icons.contact_mail_outlined;
    }
  }

  Color _getContactColor(String type) {
    switch (type) {
      case 'phone':
        return Colors.green;
      case 'email':
        return Colors.blueAccent;
      case 'website':
        return Colors.deepPurple;
      case 'whatsapp':
        return const Color(0xFF25D366);
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ColorConstants.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: ColorConstants.primaryBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.bodySmall.copyWith(
                    color: ColorConstants.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyles.bodyMedium.copyWith(
                    color: ColorConstants.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String label,
    required Color color,
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
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyles.bodyMedium.copyWith(
                  color: ColorConstants.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
