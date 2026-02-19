import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/services/admin_api_service.dart';
import '../../../../data/models/user/user_model.dart';

class RegistrationController extends GetxController {
  // Create a fresh GlobalKey for each controller instance to avoid conflicts
  late final GlobalKey<FormState> formKey;

  final nameController = TextEditingController();
  final whatsappController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final pincodeController = TextEditingController();

  final whatsappCountryCode = '+91'.obs;
  final phoneCountryCode = '+91'.obs;
  final visitingCardPath = Rxn<String>();
  final visitingCardError = Rxn<String>();
  final termsAccepted = false.obs;
  final isLoading = false.obs;

  final _imagePicker = ImagePicker();
  File? _visitingCardFile;

  @override
  void onInit() {
    super.onInit();
    formKey = GlobalKey<FormState>();
  }

  @override
  void onClose() {
    nameController.dispose();
    whatsappController.dispose();
    phoneController.dispose();
    emailController.dispose();
    pincodeController.dispose();
    super.onClose();
  }

  String? validateName(String? value) => Validators.validateName(value);
  String? validatePhone(String? value) => Validators.validatePhone(value);
  String? validateEmail(String? value) => Validators.validateEmail(value);
  String? validatePincode(String? value) => Validators.validatePincode(value);

  void selectCountryCode(bool isWhatsapp) {
    // Show country code picker
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Country Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...[ '+91', '+1', '+44', '+971', '+65'].map((code) => ListTile(
              title: Text(code),
              onTap: () {
                if (isWhatsapp) {
                  whatsappCountryCode.value = code;
                } else {
                  phoneCountryCode.value = code;
                }
                Get.back();
              },
            )),
          ],
        ),
      ),
    );
  }

  Future<void> pickVisitingCard() async {
    try {
      final source = await Get.bottomSheet<ImageSource>(
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => Get.back(result: ImageSource.camera),
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => Get.back(result: ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );

      if (source != null) {
        final pickedFile = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          _visitingCardFile = File(pickedFile.path);
          visitingCardPath.value = pickedFile.path;
          visitingCardError.value = null;
        }
      }
    } catch (e) {
      Helpers.showError('Failed to pick image');
    }
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey[700]),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void removeVisitingCard() {
    _visitingCardFile = null;
    visitingCardPath.value = null;
  }

  void openTerms() {
    Get.toNamed(AppRoutes.terms);
  }

  void openPrivacyPolicy() {
    // Open privacy policy
  }

  void goToLogin() {
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> register() async {
    // Validate form
    if (!formKey.currentState!.validate()) return;

    // Validate terms
    if (!termsAccepted.value) {
      Helpers.showError('Please accept terms and conditions');
      return;
    }

    isLoading.value = true;

    try {
      // Use AdminApiService for registration
      final adminApi = Get.find<AdminApiService>();

      final response = await adminApi.register(
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: '${phoneCountryCode.value}${phoneController.text.trim()}',
        whatsapp: whatsappController.text.isNotEmpty
            ? '${whatsappCountryCode.value}${whatsappController.text.trim()}'
            : null,
        visitingCardPath: _visitingCardFile?.path,
      );

      if (response['success'] == true) {
        // Save user ID for email verification
        final userId = response['user_id'];
        final user = UserModel(
          id: userId.toString(),
          fullName: nameController.text.trim(),
          email: emailController.text.trim(),
          phoneNumber: phoneController.text.trim(),
          countryCode: phoneCountryCode.value,
          whatsappNumber: whatsappController.text.trim(),
          whatsappCountryCode: whatsappCountryCode.value,
          pincode: pincodeController.text.trim(),
          isEmailVerified: false,
          isApproved: false,
          createdAt: DateTime.now(),
        );
        await LocalStorage.saveUser(user);

        // Show OTP for testing (remove in production!)
        final debugOtp = response['debug_otp'];
        if (debugOtp != null) {
          Get.snackbar('Success', 'Your OTP: $debugOtp', 
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 8),
          );
        } else {
          Helpers.showSuccess(response['message'] ?? 'OTP sent to your email');
        }

        // Navigate to email verification
        Get.offAllNamed(AppRoutes.emailVerification);
      } else {
        Helpers.showError(response['error'] ?? 'Registration failed');
      }
    } catch (e) {
      debugPrint('Registration failed: $e');
      Helpers.showError('Registration failed. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
}
