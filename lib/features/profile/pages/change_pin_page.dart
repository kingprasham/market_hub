import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/services/admin_api_service.dart';

class ChangePinController extends GetxController {
  final currentPin = ''.obs;
  final newPin = ''.obs;
  final confirmPin = ''.obs;
  final isLoading = false.obs;
  final step = 1.obs; // 1 = Current PIN, 2 = New PIN, 3 = Confirm PIN

  String get currentPinValue => step.value == 1
      ? currentPin.value
      : step.value == 2
          ? newPin.value
          : confirmPin.value;

  void onNumberPressed(String number) {
    if (step.value == 1 && currentPin.value.length < 4) {
      currentPin.value += number;
    } else if (step.value == 2 && newPin.value.length < 4) {
      newPin.value += number;
    } else if (step.value == 3 && confirmPin.value.length < 4) {
      confirmPin.value += number;
    }
  }

  void onBackspacePressed() {
    if (step.value == 1 && currentPin.value.isNotEmpty) {
      currentPin.value = currentPin.value.substring(0, currentPin.value.length - 1);
    } else if (step.value == 2 && newPin.value.isNotEmpty) {
      newPin.value = newPin.value.substring(0, newPin.value.length - 1);
    } else if (step.value == 3 && confirmPin.value.isNotEmpty) {
      confirmPin.value = confirmPin.value.substring(0, confirmPin.value.length - 1);
    }
  }

  Future<void> verifyCurrentPin() async {
    if (currentPin.value.length != 4) {
      Get.snackbar(
        'Error',
        'Please enter your current 4-digit PIN',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.negativeRed,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    
    try {
      // Verify current PIN via server API (using login endpoint)
      final user = LocalStorage.getUser();
      if (user == null) {
        Get.snackbar(
          'Error',
          'User not found. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorConstants.negativeRed,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return;
      }

      final adminApi = Get.find<AdminApiService>();
      final response = await adminApi.login(
        email: user.email,
        pin: currentPin.value,
      );

      isLoading.value = false;

      if (response['success'] == true) {
        step.value = 2;
      } else {
        Get.snackbar(
          'Error',
          'Current PIN is incorrect',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorConstants.negativeRed,
          colorText: Colors.white,
        );
        currentPin.value = '';
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to verify PIN. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.negativeRed,
        colorText: Colors.white,
      );
      currentPin.value = '';
    }
  }

  Future<void> setNewPin() async {
    if (newPin.value.length != 4) {
      Get.snackbar(
        'Error',
        'Please enter a 4-digit PIN',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.negativeRed,
        colorText: Colors.white,
      );
      return;
    }

    step.value = 3;
  }

  Future<void> confirmNewPin() async {
    if (confirmPin.value != newPin.value) {
      Get.snackbar(
        'Error',
        'PINs do not match',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.negativeRed,
        colorText: Colors.white,
      );
      confirmPin.value = '';
      return;
    }

    isLoading.value = true;
    
    try {
      // Get user and update PIN on server
      final user = LocalStorage.getUser();
      
      if (user == null) {
        isLoading.value = false;
        Get.snackbar(
          'Error',
          'User not found. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorConstants.negativeRed,
          colorText: Colors.white,
        );
        return;
      }

      debugPrint('ChangePIN: User ID = ${user.id}');
      
      final adminApi = Get.find<AdminApiService>();
      final response = await adminApi.setPin(
        userId: int.tryParse(user.id) ?? 0,
        pin: newPin.value,
      );

      debugPrint('ChangePIN: setPin response = $response');

      // Check for explicit success
      if (response['success'] == true) {
        // Save new PIN locally as well
        await LocalStorage.savePin(newPin.value);
        
        isLoading.value = false;
        
        // Show success toast with longer duration
        Get.snackbar(
          'Success',
          response['message'] ?? 'PIN changed successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorConstants.positiveGreen,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        
        // Wait a moment then navigate to homepage
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Navigate to main/homepage
        Get.offAllNamed('/main');
      } else {
        isLoading.value = false;
        Get.snackbar(
          'Error',
          response['error'] ?? response['message'] ?? 'Failed to update PIN',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorConstants.negativeRed,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('ChangePIN: Error = $e');
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to change PIN: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.negativeRed,
        colorText: Colors.white,
      );
    }
  }

  void goBack() {
    if (step.value > 1) {
      step.value--;
      if (step.value == 1) {
        currentPin.value = '';
      } else if (step.value == 2) {
        newPin.value = '';
      }
    } else {
      Get.back();
    }
  }

  void onContinue() {
    switch (step.value) {
      case 1:
        verifyCurrentPin();
        break;
      case 2:
        setNewPin();
        break;
      case 3:
        confirmNewPin();
        break;
    }
  }
}

class ChangePinPage extends StatelessWidget {
  const ChangePinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChangePinController());
    
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: controller.goBack,
          icon: const Icon(
            Icons.arrow_back,
            color: ColorConstants.textPrimary,
          ),
        ),
        title: Text(
          'Change PIN',
          style: TextStyles.h4.copyWith(color: ColorConstants.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            
            // Lock Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ColorConstants.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 40,
                color: ColorConstants.primaryBlue,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Obx(() => Text(
              _getTitle(controller.step.value),
              style: TextStyles.h4,
              textAlign: TextAlign.center,
            )),
            
            const SizedBox(height: 8),
            
            Obx(() => Text(
              _getSubtitle(controller.step.value),
              style: TextStyles.bodyMedium.copyWith(
                color: ColorConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            )),
            
            const SizedBox(height: 32),
            
            // PIN Display
            Obx(() => _buildPinDisplay(controller.currentPinValue)),
            
            const Spacer(),
            
            // Number Pad
            _buildNumberPad(controller),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getTitle(int step) {
    switch (step) {
      case 1:
        return 'Enter Current PIN';
      case 2:
        return 'Create New PIN';
      case 3:
        return 'Confirm New PIN';
      default:
        return '';
    }
  }

  String _getSubtitle(int step) {
    switch (step) {
      case 1:
        return 'Enter your current 4-digit PIN';
      case 2:
        return 'Create a new 4-digit PIN';
      case 3:
        return 'Re-enter your new PIN to confirm';
      default:
        return '';
    }
  }

  Widget _buildPinDisplay(String pin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < pin.length;
        return Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFilled
                  ? ColorConstants.primaryBlue
                  : ColorConstants.borderColor,
              width: 2,
            ),
          ),
          child: Center(
            child: isFilled
                ? Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: ColorConstants.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildNumberPad(ChangePinController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Row 1: 1, 2, 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('1', controller),
              _buildNumberButton('2', controller),
              _buildNumberButton('3', controller),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: 4, 5, 6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('4', controller),
              _buildNumberButton('5', controller),
              _buildNumberButton('6', controller),
            ],
          ),
          const SizedBox(height: 16),
          // Row 3: 7, 8, 9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('7', controller),
              _buildNumberButton('8', controller),
              _buildNumberButton('9', controller),
            ],
          ),
          const SizedBox(height: 16),
          // Row 4: Empty, 0, Backspace/Continue
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Backspace
              _buildActionButton(
                icon: Icons.backspace_outlined,
                onTap: controller.onBackspacePressed,
              ),
              _buildNumberButton('0', controller),
              // Continue
              Obx(() => _buildContinueButton(controller)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String number, ChangePinController controller) {
    return GestureDetector(
      onTap: () => controller.onNumberPressed(number),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            number,
            style: TextStyles.h3.copyWith(
              color: ColorConstants.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(36),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 28,
            color: ColorConstants.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(ChangePinController controller) {
    final pinLength = controller.currentPinValue.length;
    final isActive = pinLength == 4 && !controller.isLoading.value;
    
    return GestureDetector(
      onTap: isActive ? controller.onContinue : null,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isActive ? ColorConstants.primaryBlue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(36),
        ),
        child: Center(
          child: controller.isLoading.value
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  Icons.arrow_forward,
                  size: 28,
                  color: isActive ? Colors.white : ColorConstants.textSecondary,
                ),
        ),
      ),
    );
  }
}
