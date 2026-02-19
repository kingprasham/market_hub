import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../controller/profile_controller.dart';
import '../../../app/routes/app_routes.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<ProfileController>();

  @override
  void initState() {
    super.initState();

    // Load user data if not already loaded
    if (controller.user.value == null) {
      controller.loadUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Profile',
          style: TextStyles.h5.copyWith(color: ColorConstants.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorConstants.textPrimary),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: ColorConstants.textPrimary),
            onPressed: () => controller.loadUser(),
          ),
        ],
      ),
      body: Obx(() {
        final user = controller.user.value;

        // Show loading indicator if no user data
        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Picture
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: ColorConstants.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 50,
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
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            onPressed: () {
                              Get.snackbar('Coming Soon', 'Photo upload coming soon',
                                  snackPosition: SnackPosition.BOTTOM);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Personal Information Section
                _buildSectionHeader('Personal Information'),
                const SizedBox(height: 16),
                _buildReadOnlyField(
                  label: 'Full Name',
                  value: user.fullName,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildReadOnlyField(
                  label: 'Email Address',
                  value: user.email,
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                _buildReadOnlyField(
                  label: 'Phone Number',
                  value: '${user.countryCode} ${user.phoneNumber}',
                  icon: Icons.phone_outlined,
                ),
                const SizedBox(height: 16),
                _buildReadOnlyField(
                  label: 'WhatsApp Number',
                  value: '${user.whatsappCountryCode} ${user.whatsappNumber}',
                  icon: Icons.chat_outlined,
                ),
                const SizedBox(height: 24),

                // Subscription Information Section
                _buildSectionHeader('Subscription Information'),
                const SizedBox(height: 16),
                _buildReadOnlyField(
                  label: 'Current Plan',
                  value: user.planName ?? 'No Plan',
                  icon: Icons.card_membership,
                  suffix: TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.contactUs),
                    child: Text(
                      'Upgrade',
                      style: TextStyles.bodyMedium.copyWith(
                        color: ColorConstants.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildReadOnlyField(
                  label: 'Plan Expiry Date',
                  value: user.planExpiryDate != null
                      ? '${user.planExpiryDate!.day}/${user.planExpiryDate!.month}/${user.planExpiryDate!.year}'
                      : 'N/A',
                  icon: Icons.calendar_today_outlined,
                ),
                const SizedBox(height: 24),

                // Account Information Section
                _buildSectionHeader('Account Information'),
                const SizedBox(height: 16),
                _buildReadOnlyField(
                  label: 'Registration Date',
                  value: '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                  icon: Icons.event_outlined,
                ),
              const SizedBox(height: 32),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyles.bodyLarge.copyWith(
          color: ColorConstants.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        initialValue: value,
        enabled: true, // Must be enabled for suffix icon to be clickable
        readOnly: true, // Prevent editing
        style: TextStyle(color: ColorConstants.textPrimary.withOpacity(0.7)), // Visually indicate it's read-only
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: ColorConstants.textSecondary),
          suffixIcon: suffix, // using suffixIcon for better alignment in input field
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}
