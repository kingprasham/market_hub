import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../controller/forgot_pin_controller.dart';

class ForgotPinScreen extends GetView<ForgotPinController> {
  const ForgotPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Forgot PIN'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: controller.goBack,
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          switch (controller.step.value) {
            case 1:
              return _buildEmailStep();
            case 2:
              return _buildOtpStep();
            case 3:
              return _buildNewPinStep();
            default:
              return _buildEmailStep();
          }
        }),
      ),
    );
  }

  Widget _buildEmailStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_reset,
            size: 64,
            color: ColorConstants.primaryBlue,
          ),
          const SizedBox(height: 24),
          Text(
            'Reset Your PIN',
            style: TextStyles.h2.copyWith(
              color: ColorConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enter your registered email address to receive a reset code.',
            style: TextStyles.bodyMedium.copyWith(
              color: ColorConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Email Address',
            style: TextStyles.labelLarge.copyWith(
              color: ColorConstants.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: ColorConstants.inputBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorConstants.inputBorder),
            ),
            child: TextField(
              controller: controller.emailController,
              focusNode: controller.emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              style: TextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: TextStyles.bodyMedium.copyWith(
                  color: ColorConstants.textSecondary,
                ),
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: ColorConstants.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onSubmitted: (_) => controller.requestResetCode(),
            ),
          ),
          const SizedBox(height: 32),
          Obx(() => PrimaryButton(
                text: 'Send Reset Code',
                isLoading: controller.isLoading.value,
                onPressed: controller.requestResetCode,
              )),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.mark_email_read,
            size: 64,
            color: ColorConstants.primaryBlue,
          ),
          const SizedBox(height: 24),
          Text(
            'Enter Reset Code',
            style: TextStyles.h2.copyWith(
              color: ColorConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We sent a 6-digit code to:',
            style: TextStyles.bodyMedium.copyWith(
              color: ColorConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            controller.emailController.text,
            style: TextStyles.bodyMedium.copyWith(
              color: ColorConstants.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Pinput(
              length: 6,
              controller: controller.otpController,
              focusNode: controller.otpFocusNode,
              defaultPinTheme: PinTheme(
                width: 50,
                height: 56,
                textStyle: TextStyles.h4,
                decoration: BoxDecoration(
                  color: ColorConstants.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColorConstants.inputBorder),
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 50,
                height: 56,
                textStyle: TextStyles.h4,
                decoration: BoxDecoration(
                  color: ColorConstants.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorConstants.primaryColor,
                    width: 2,
                  ),
                ),
              ),
              onCompleted: (_) => controller.verifyOtp(),
            ),
          ),
          const SizedBox(height: 24),
          Obx(() => Center(
                child: controller.canResendOtp.value
                    ? TextButton(
                        onPressed: controller.resendOtp,
                        child: const Text('Resend Code'),
                      )
                    : Text(
                        'Resend code in ${controller.countdown.value}s',
                        style: TextStyles.bodySmall.copyWith(
                          color: ColorConstants.textSecondary,
                        ),
                      ),
              )),
          const SizedBox(height: 32),
          Obx(() => PrimaryButton(
                text: 'Verify Code',
                isLoading: controller.isLoading.value,
                onPressed: controller.verifyOtp,
              )),
        ],
      ),
    );
  }

  Widget _buildNewPinStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 64,
            color: ColorConstants.primaryBlue,
          ),
          const SizedBox(height: 24),
          Text(
            'Create New PIN',
            style: TextStyles.h2.copyWith(
              color: ColorConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enter your new 4-digit PIN',
            style: TextStyles.bodyMedium.copyWith(
              color: ColorConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'New PIN',
            style: TextStyles.labelLarge.copyWith(
              color: ColorConstants.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Pinput(
              length: 4,
              controller: controller.newPinController,
              focusNode: controller.newPinFocusNode,
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
              onCompleted: (_) => controller.confirmPinFocusNode.requestFocus(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Confirm PIN',
            style: TextStyles.labelLarge.copyWith(
              color: ColorConstants.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Pinput(
              length: 4,
              controller: controller.confirmPinController,
              focusNode: controller.confirmPinFocusNode,
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
              onCompleted: (_) => controller.resetPin(),
            ),
          ),
          const SizedBox(height: 32),
          Obx(() => PrimaryButton(
                text: 'Reset PIN',
                isLoading: controller.isLoading.value,
                onPressed: controller.resetPin,
              )),
        ],
      ),
    );
  }
}
