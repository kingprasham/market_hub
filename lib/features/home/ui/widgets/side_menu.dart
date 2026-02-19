import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/storage/local_storage.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final user = LocalStorage.getUser();
    
    return Drawer(
      child: Column(
        children: [
          // Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: ColorConstants.primaryGradient,
            ),
            accountName: Text(
              user?.fullName ?? 'User',
              style: TextStyles.h6.copyWith(color: Colors.white),
            ),
            accountEmail: Text(
              user?.email ?? '',
              style: TextStyles.caption.copyWith(color: Colors.white.withOpacity(0.8)),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user?.fullName ?? 'U').substring(0, 1).toUpperCase(),
                style: TextStyles.h4.copyWith(color: ColorConstants.primaryBlue),
              ),
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'My Profile',
                  onTap: () => Get.toNamed(AppRoutes.profile),
                ),
                _buildMenuItem(
                  icon: Icons.list_alt,
                  title: 'Watchlist',
                  onTap: () => Get.toNamed(AppRoutes.watchlist),
                ),
                _buildMenuItem(
                  icon: Icons.notifications_none,
                  title: 'Notifications',
                  onTap: () => Get.toNamed(AppRoutes.notifications),
                ),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => Get.toNamed(AppRoutes.settings),
                ),
                const Divider(),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: 'About Us',
                  onTap: () => Get.toNamed(AppRoutes.aboutUs),
                ),
                _buildMenuItem(
                  icon: Icons.contact_support_outlined,
                  title: 'Contact Support',
                  onTap: () => Get.toNamed(AppRoutes.contactUs),
                ),
                _buildMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                ),
              ],
            ),
          ),
          
          // Logout
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              onPressed: () {
                _showLogoutDialog(context);
              },
              icon: const Icon(Icons.logout, color: ColorConstants.negativeRed),
              label: const Text(
                'Logout',
                style: TextStyle(color: ColorConstants.negativeRed),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: ColorConstants.negativeRed),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: ColorConstants.textSecondary),
      title: Text(
        title,
        style: TextStyles.bodyMedium.copyWith(color: ColorConstants.textPrimary),
      ),
      trailing: const Icon(Icons.chevron_right, size: 16, color: ColorConstants.textSecondary),
      onTap: () {
        Get.back(); // Close drawer
        onTap();
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await LocalStorage.logout();
              Get.offAllNamed(AppRoutes.login);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
