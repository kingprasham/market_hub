import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../controller/profile_controller.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

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
          'Profile',
          style: TextStyles.h4.copyWith(color: ColorConstants.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),

            const SizedBox(height: 16),

            // Account Section
            _buildSectionHeader('Account'),
            _buildAccountSection(),

            const SizedBox(height: 16),

            // Notifications Section
            _buildSectionHeader('Notifications'),
            _buildNotificationsSection(),

            const SizedBox(height: 16),

            // Security Section
            _buildSectionHeader('Security'),
            _buildSecuritySection(),

            const SizedBox(height: 16),

            // Support Section
            _buildSectionHeader('Support'),
            _buildSupportSection(),

            const SizedBox(height: 16),

            // Logout Section
            _buildLogoutSection(),

            const SizedBox(height: 32),

            // App Version
            Text(
              'Version 1.0.0',
              style: TextStyles.caption.copyWith(
                color: ColorConstants.textSecondary,
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Obx(() => Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: ColorConstants.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getInitials(controller.user.value?.fullName ?? 'U'),
                    style: TextStyles.h2.copyWith(color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            controller.user.value?.fullName ?? 'User',
            style: TextStyles.h4,
          ),
          const SizedBox(height: 4),
          Text(
            controller.user.value?.email ?? '',
            style: TextStyles.bodyMedium.copyWith(
              color: ColorConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: ColorConstants.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              controller.user.value?.planName ?? 'Basic Plan',
              style: TextStyles.caption.copyWith(
                color: ColorConstants.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyles.bodyMedium.copyWith(
            color: ColorConstants.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.business_outlined,
            title: 'Company Details',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.credit_card_outlined,
            title: 'Subscription',
            subtitle: 'Professional Plan',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.history,
            title: 'Billing History',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Obx(() => _buildSwitchItem(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            value: controller.notificationsEnabled.value,
            onChanged: controller.toggleNotifications,
          )),
          _buildDivider(),
          Obx(() => _buildSwitchItem(
            icon: Icons.show_chart,
            title: 'Price Alerts',
            value: controller.priceAlertsEnabled.value,
            onChanged: controller.togglePriceAlerts,
            enabled: controller.notificationsEnabled.value,
          )),
          _buildDivider(),
          Obx(() => _buildSwitchItem(
            icon: Icons.article_outlined,
            title: 'News Alerts',
            value: controller.newsAlertsEnabled.value,
            onChanged: controller.toggleNewsAlerts,
            enabled: controller.notificationsEnabled.value,
          )),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: 'Change PIN',
            onTap: controller.changePIN,
          ),
          _buildDivider(),
          Obx(() => _buildSwitchItem(
            icon: Icons.fingerprint,
            title: 'Biometric Login',
            value: controller.biometricEnabled.value,
            onChanged: controller.toggleBiometric,
          )),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.devices,
            title: 'Active Sessions',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'About Us',
            onTap: () => Get.toNamed(AppRoutes.aboutUs),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.headset_mic_outlined,
            title: 'Contact Us',
            onTap: () => Get.toNamed(AppRoutes.contactUs),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.feedback_outlined,
            title: 'Feedback',
            onTap: () => Get.toNamed(AppRoutes.feedback),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () => Get.toNamed(AppRoutes.terms),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            iconColor: ColorConstants.negativeRed,
            textColor: ColorConstants.negativeRed,
            showArrow: false,
            onTap: _showLogoutDialog,
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.delete_outline,
            title: 'Delete Account',
            iconColor: ColorConstants.negativeRed,
            textColor: ColorConstants.negativeRed,
            showArrow: false,
            onTap: controller.deleteAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? textColor,
    bool showArrow = true,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? ColorConstants.primaryBlue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? ColorConstants.primaryBlue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyles.bodyMedium.copyWith(
          color: textColor ?? ColorConstants.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyles.caption.copyWith(
                color: ColorConstants.textSecondary,
              ),
            )
          : null,
      trailing: showArrow
          ? const Icon(
              Icons.chevron_right,
              color: ColorConstants.textSecondary,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: ColorConstants.primaryBlue.withOpacity(enabled ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: enabled
              ? ColorConstants.primaryBlue
              : ColorConstants.textSecondary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyles.bodyMedium.copyWith(
          color: enabled
              ? ColorConstants.textPrimary
              : ColorConstants.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: ColorConstants.primaryBlue,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: ColorConstants.negativeRed),
            ),
          ),
        ],
      ),
    );
  }
}
