import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../controller/settings_controller.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

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
          'Settings',
          style: TextStyles.h4.copyWith(color: ColorConstants.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Notifications Section
            _buildSectionHeader('Notifications'),
            _buildNotificationsSection(),

            const SizedBox(height: 16),

            // Security Section
            _buildSectionHeader('Security'),
            _buildSecuritySection(),

            const SizedBox(height: 16),

            // Preferences Section
            _buildSectionHeader('Preferences'),
            _buildPreferencesSection(),

            const SizedBox(height: 16),

            // Support Section
            _buildSectionHeader('Help & Support'),
            _buildSupportSection(),

            const SizedBox(height: 100),
          ],
        ),
      ),
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
            subtitle: 'Receive app notifications',
            value: controller.notificationsEnabled.value,
            onChanged: controller.toggleNotifications,
          )),
          _buildDivider(),
          Obx(() => _buildSwitchItem(
            icon: Icons.show_chart,
            title: 'Price Alerts',
            subtitle: 'Get notified on price changes',
            value: controller.priceAlertsEnabled.value,
            onChanged: controller.togglePriceAlerts,
            enabled: controller.notificationsEnabled.value,
          )),
          _buildDivider(),
          Obx(() => _buildSwitchItem(
            icon: Icons.article_outlined,
            title: 'News Alerts',
            subtitle: 'Breaking news and updates',
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
            subtitle: 'Update your app PIN',
            onTap: () => Get.toNamed(AppRoutes.changePin),
          ),
          _buildDivider(),
          Obx(() => _buildSwitchItem(
            icon: Icons.fingerprint,
            title: 'Biometric Login',
            subtitle: 'Use fingerprint or face ID',
            value: controller.biometricEnabled.value,
            onChanged: controller.toggleBiometric,
          )),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.devices,
            title: 'Active Sessions',
            subtitle: 'Manage your devices',
            onTap: () {
              Get.snackbar(
                'Active Session',
                'You are logged in on this device only',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: ColorConstants.primaryBlue,
                colorText: Colors.white,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Obx(() => _buildMenuItem(
            icon: Icons.language,
            title: 'Language',
            subtitle: controller.selectedLanguage.value,
            onTap: _showLanguageDialog,
          )),
          _buildDivider(),
          Obx(() => _buildMenuItem(
            icon: Icons.currency_rupee,
            title: 'Currency Display',
            subtitle: controller.selectedCurrency.value,
            onTap: _showCurrencyDialog,
          )),
          _buildDivider(),
          Obx(() => _buildSwitchItem(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Switch to dark theme',
            value: controller.darkModeEnabled.value,
            onChanged: controller.toggleDarkMode,
          )),
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
            subtitle: 'Learn more about Market Hub',
            onTap: () => Get.toNamed(AppRoutes.aboutUs),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.headset_mic_outlined,
            title: 'Contact Us',
            subtitle: 'Get in touch with support',
            onTap: () => Get.toNamed(AppRoutes.contactUs),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help & FAQ',
            subtitle: 'Frequently asked questions',
            onTap: () => Get.toNamed(AppRoutes.helpFaq),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.play_circle_outline,
            title: 'Tutorial',
            subtitle: 'Learn how to use the app',
            onTap: () => Get.toNamed(AppRoutes.tutorial),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.feedback_outlined,
            title: 'Feedback',
            subtitle: 'Share your thoughts',
            onTap: () => Get.toNamed(AppRoutes.feedback),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            subtitle: 'Read our policies',
            onTap: () => Get.toNamed(AppRoutes.terms),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we protect your data',
            onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
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
      title: Text(
        title,
        style: TextStyles.bodyMedium.copyWith(
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
      trailing: const Icon(
        Icons.chevron_right,
        color: ColorConstants.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    String? subtitle,
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
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyles.caption.copyWith(
                color: ColorConstants.textSecondary,
              ),
            )
          : null,
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

  void _showLanguageDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: controller.selectedLanguage.value,
              onChanged: (value) {
                controller.selectedLanguage.value = value!;
                Get.back();
              },
            ),
            RadioListTile<String>(
              title: const Text('Hindi'),
              value: 'Hindi',
              groupValue: controller.selectedLanguage.value,
              onChanged: (value) {
                controller.selectedLanguage.value = value!;
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('INR (₹)'),
              value: 'INR (₹)',
              groupValue: controller.selectedCurrency.value,
              onChanged: (value) {
                controller.selectedCurrency.value = value!;
                Get.back();
              },
            ),
            RadioListTile<String>(
              title: const Text('USD (\$)'),
              value: 'USD (\$)',
              groupValue: controller.selectedCurrency.value,
              onChanged: (value) {
                controller.selectedCurrency.value = value!;
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}
