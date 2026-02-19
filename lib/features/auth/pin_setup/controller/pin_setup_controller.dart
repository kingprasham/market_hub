import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/services/admin_api_service.dart';
import '../../../../core/utils/helpers.dart';

class PinSetupController extends GetxController {
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();
  final pinFocusNode = FocusNode();
  final confirmPinFocusNode = FocusNode();

  final isConfirming = false.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onClose() {
    pinController.dispose();
    confirmPinController.dispose();
    pinFocusNode.dispose();
    confirmPinFocusNode.dispose();
    super.onClose();
  }

  void reset() {
    pinController.clear();
    confirmPinController.clear();
    isConfirming.value = false;
    errorMessage.value = '';
    pinFocusNode.requestFocus();
  }

  Future<void> setPin() async {
    if (pinController.text.length != 4) {
      errorMessage.value = 'Please enter 4-digit PIN';
      return;
    }

    if (confirmPinController.text.length != 4) {
      errorMessage.value = 'Please confirm your PIN';
      return;
    }

    if (pinController.text != confirmPinController.text) {
      errorMessage.value = 'PINs do not match';
      confirmPinController.clear();
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

      // Call Admin API to set PIN
      final adminApi = Get.find<AdminApiService>();
      final response = await adminApi.setPin(
        userId: int.parse(user.id),
        pin: pinController.text,
      );

      if (response['success'] == true) {
        // Save PIN locally
        await LocalStorage.savePin(pinController.text);

        Helpers.showSuccess(response['message'] ?? 'PIN set successfully!');

        // Navigate to pending approval
        Get.offAllNamed(AppRoutes.pendingApproval);
      } else {
        errorMessage.value = response['error'] ?? 'Failed to set PIN';
      }
    } catch (e) {
      errorMessage.value = 'Failed to set PIN. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }
}
