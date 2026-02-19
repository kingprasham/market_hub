import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/admin_api_service.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../app/routes/app_routes.dart';

class ForgotPinController extends GetxController {
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final newPinController = TextEditingController();
  final confirmPinController = TextEditingController();

  final emailFocusNode = FocusNode();
  final otpFocusNode = FocusNode();
  final newPinFocusNode = FocusNode();
  final confirmPinFocusNode = FocusNode();

  final isLoading = false.obs;
  final step = 1.obs; // 1 = Email, 2 = OTP, 3 = New PIN
  final resetToken = ''.obs;
  final canResendOtp = false.obs;
  final countdown = 60.obs;

  Timer? _timer;

  @override
  void onClose() {
    _timer?.cancel();
    // Wrap in try-catch to prevent 'used after disposed' errors
    // when navigating away with Get.offAllNamed
    try { emailController.dispose(); } catch (_) {}
    try { otpController.dispose(); } catch (_) {}
    try { newPinController.dispose(); } catch (_) {}
    try { confirmPinController.dispose(); } catch (_) {}
    try { emailFocusNode.dispose(); } catch (_) {}
    try { otpFocusNode.dispose(); } catch (_) {}
    try { newPinFocusNode.dispose(); } catch (_) {}
    try { confirmPinFocusNode.dispose(); } catch (_) {}
    super.onClose();
  }

  void _startCountdown() {
    canResendOtp.value = false;
    countdown.value = 60;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      countdown.value--;
      if (countdown.value <= 0) {
        canResendOtp.value = true;
        timer.cancel();
      }
    });
  }

  Future<void> requestResetCode() async {
    if (emailController.text.isEmpty || !GetUtils.isEmail(emailController.text)) {
      Helpers.showError('Please enter a valid email address');
      return;
    }

    isLoading.value = true;

    try {
      final adminApi = Get.find<AdminApiService>();
      final response = await adminApi.forgotPin(email: emailController.text.trim());

      if (response['success'] == true) {
        step.value = 2;
        _startCountdown();

        Helpers.showSuccess(response['message'] ?? 'Reset code sent to your email');

        // Focus OTP field
        Future.delayed(const Duration(milliseconds: 300), () {
          otpFocusNode.requestFocus();
        });
      } else {
        Helpers.showError(response['error'] ?? 'Failed to send reset code');
      }
    } catch (e) {
      Helpers.showError('Failed to send reset code. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (!canResendOtp.value) return;
    await requestResetCode();
  }

  Future<void> verifyOtp() async {
    if (otpController.text.length != 6) {
      Helpers.showError('Please enter the 6-digit code');
      return;
    }

    isLoading.value = true;

    try {
      final adminApi = Get.find<AdminApiService>();
      final response = await adminApi.verifyResetOtp(
        email: emailController.text.trim(),
        otp: otpController.text.trim(),
      );

      if (response['success'] == true) {
        resetToken.value = response['reset_token'];
        step.value = 3;
        Helpers.showSuccess('OTP verified successfully');

        // Focus new PIN field
        Future.delayed(const Duration(milliseconds: 300), () {
          newPinFocusNode.requestFocus();
        });
      } else {
        Helpers.showError(response['error'] ?? 'Invalid code');
        otpController.clear();
      }
    } catch (e) {
      debugPrint('OTP verification error: $e');
      Helpers.showError('Verification failed: ${e.toString()}');
      otpController.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPin() async {
    if (newPinController.text.length != 4) {
      Helpers.showError('Please enter a 4-digit PIN');
      return;
    }

    if (confirmPinController.text != newPinController.text) {
      Helpers.showError('PINs do not match');
      return;
    }

    isLoading.value = true;

    try {
      final adminApi = Get.find<AdminApiService>();
      final response = await adminApi.resetPin(
        resetToken: resetToken.value,
        newPin: newPinController.text,
      );

      if (response['success'] == true) {
        // 1. Cancel any running timer first
        _timer?.cancel();

        // 2. Unfocus all text fields to stop caret animations.
        //    Do NOT call .clear() — clearing a focused controller triggers
        //    EditableTextState._scheduleShowCaretOnScreen which schedules
        //    post-frame callbacks that crash when the widget tree is torn down.
        //    The controllers will be disposed in onClose() anyway.
        FocusManager.instance.primaryFocus?.unfocus();

        isLoading.value = false;

        Helpers.showSuccess('PIN reset successfully! Please login with your new PIN.');

        // 3. Wait TWO full frames before navigating.
        //    Frame 1: Flushes any caret post-frame callbacks triggered by unfocus.
        //    Frame 2: Flushes any cascading callbacks scheduled during frame 1.
        //    Only then is it safe to call offAllNamed which detaches render objects.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed(AppRoutes.login);
          });
        });
        return; // Skip finally block
      } else {
        Helpers.showError(response['error'] ?? 'Failed to reset PIN');
      }
    } catch (e) {
      debugPrint('PIN reset error: $e');
      Helpers.showError('Failed to reset PIN: ${e.toString()}');
    } finally {
      try { isLoading.value = false; } catch (_) {}
    }
  }

  void goBack() {
    if (step.value > 1) {
      step.value--;
    } else {
      Get.back();
    }
  }
}
