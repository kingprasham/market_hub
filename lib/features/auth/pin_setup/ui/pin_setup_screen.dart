import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../controller/pin_setup_controller.dart';

class PinSetupScreen extends GetView<PinSetupController> {
  const PinSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: ColorConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Set Your PIN',
                style: TextStyles.h2,
              ),
              const SizedBox(height: 12),
              Text(
                'Create a 4-digit PIN for secure access',
                style: TextStyles.bodyMedium.copyWith(
                  color: ColorConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Enter PIN
              Obx(() => Column(
                children: [
                  Text(
                    controller.isConfirming.value
                        ? 'Confirm PIN'
                        : 'Enter PIN',
                    style: TextStyles.labelLarge.copyWith(
                      color: ColorConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Pinput(
                    length: 4,
                    controller: controller.isConfirming.value
                        ? controller.confirmPinController
                        : controller.pinController,
                    focusNode: controller.isConfirming.value
                        ? controller.confirmPinFocusNode
                        : controller.pinFocusNode,
                    obscureText: true,
                    obscuringCharacter: '●',
                    defaultPinTheme: PinTheme(
                      width: 60,
                      height: 60,
                      textStyle: TextStyles.h3,
                      decoration: BoxDecoration(
                        color: ColorConstants.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ColorConstants.inputBorder),
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 60,
                      height: 60,
                      textStyle: TextStyles.h3,
                      decoration: BoxDecoration(
                        color: ColorConstants.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ColorConstants.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    onCompleted: (pin) {
                      if (!controller.isConfirming.value) {
                        controller.isConfirming.value = true;
                        controller.confirmPinFocusNode.requestFocus();
                      } else {
                        controller.setPin();
                      }
                    },
                  ),
                ],
              )),

              // Error Message
              Obx(() => controller.errorMessage.value.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        controller.errorMessage.value,
                        style: TextStyles.bodySmall.copyWith(
                          color: ColorConstants.errorColor,
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),
              const SizedBox(height: 32),

              // Set PIN Button
              Obx(() => PrimaryButton(
                text: 'Set PIN & Continue',
                isLoading: controller.isLoading.value,
                onPressed: controller.setPin,
              )),

              // Reset button
              Obx(() => controller.isConfirming.value
                  ? TextButton(
                      onPressed: controller.reset,
                      child: Text(
                        'Reset',
                        style: TextStyles.buttonTextSecondary,
                      ),
                    )
                  : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}
