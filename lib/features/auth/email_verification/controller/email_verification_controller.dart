import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/services/admin_api_service.dart';

class EmailVerificationController extends GetxController {
  final otpController = TextEditingController();
  final otpFocusNode = FocusNode();

  final email = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final canResend = false.obs;
  final countdown = AppConstants.otpResendTimeout.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _loadEmail();
    _startCountdown();
  }

  void _loadEmail() {
    final user = LocalStorage.getUser();
    if (user != null) {
      email.value = user.email;
    }
  }

  void _startCountdown() {
    canResend.value = false;
    countdown.value = AppConstants.otpResendTimeout;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      countdown.value--;
      if (countdown.value <= 0) {
        canResend.value = true;
        timer.cancel();
      }
    });
  }

  @override
  void onClose() {
    otpController.dispose();
    otpFocusNode.dispose();
    _timer?.cancel();
    super.onClose();
  }

  Future<void> verifyOtp() async {
    if (otpController.text.length != 6) {
      errorMessage.value = 'Please enter 6-digit OTP';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final user = LocalStorage.getUser();
      if (user == null) {
        errorMessage.value = 'User not found. Please register again.';
        return;
      }

      final adminApi = Get.find<AdminApiService>();
      final response = await adminApi.verifyEmail(
        userId: int.parse(user.id),
        otp: otpController.text,
      );

      if (response['success'] == true) {
        // Update user's email verification status
        await LocalStorage.updateUser((u) => u.copyWith(isEmailVerified: true));

        Helpers.showSuccess(response['message'] ?? 'Email verified!');

        // Navigate to PIN setup
        Get.offAllNamed(AppRoutes.pinSetup);
      } else {
        errorMessage.value = response['error'] ?? 'Invalid OTP';
        otpController.clear();
      }
    } catch (e) {
      errorMessage.value = 'Verification failed. Please try again.';
      otpController.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (!canResend.value) return;

    try {
      Helpers.showLoading(message: 'Sending OTP...');

      // Re-register to get a new OTP (the API will send a new OTP)
      final user = LocalStorage.getUser();
      if (user != null) {
        final adminApi = Get.find<AdminApiService>();
        await adminApi.register(
          fullName: user.fullName,
          email: user.email,
          phone: '${user.countryCode}${user.phoneNumber}',
          whatsapp: user.whatsappNumber != null
              ? '${user.whatsappCountryCode}${user.whatsappNumber}'
              : null,
        );
      }

      Helpers.hideLoading();
      Helpers.showSuccess('OTP sent successfully');
      _startCountdown();
    } catch (e) {
      Helpers.hideLoading();
      Helpers.showError('Failed to resend OTP');
    }
  }

  void changeEmail() {
    Get.dialog(
      AlertDialog(
        title: const Text('Change Email'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter new email',
          ),
          onSubmitted: (newEmail) async {
            if (newEmail.isNotEmpty && GetUtils.isEmail(newEmail)) {
              Get.back();
              await _updateEmail(newEmail);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateEmail(String newEmail) async {
    try {
      Helpers.showLoading(message: 'Updating email...');

      // Re-register with new email to get a new OTP
      final user = LocalStorage.getUser();
      if (user != null) {
        final adminApi = Get.find<AdminApiService>();
        final response = await adminApi.register(
          fullName: user.fullName,
          email: newEmail,
          phone: '${user.countryCode}${user.phoneNumber}',
          whatsapp: user.whatsappNumber != null
              ? '${user.whatsappCountryCode}${user.whatsappNumber}'
              : null,
        );

        if (response['success'] == true) {
          // Update local user with new email and user_id
          await LocalStorage.updateUser((u) => u.copyWith(
            id: response['user_id'].toString(),
            email: newEmail,
          ));
          email.value = newEmail;
          Helpers.hideLoading();
          Helpers.showSuccess('Email updated. OTP sent to new email.');
          _startCountdown();
        } else {
          Helpers.hideLoading();
          Helpers.showError(response['error'] ?? 'Failed to update email');
        }
      }
    } catch (e) {
      Helpers.hideLoading();
      Helpers.showError('Failed to update email');
    }
  }
}
