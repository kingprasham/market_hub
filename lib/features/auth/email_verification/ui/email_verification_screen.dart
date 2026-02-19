import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../controller/email_verification_controller.dart';

class EmailVerificationScreen extends GetView<EmailVerificationController> {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ColorConstants.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Email Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_outlined,
                  size: 40,
                  color: ColorConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Verify Email',
                style: TextStyles.h2,
              ),
              const SizedBox(height: 12),

              Text(
                'Enter OTP sent to:',
                style: TextStyles.bodyMedium.copyWith(
                  color: ColorConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Obx(() => Text(
                controller.email.value,
                style: TextStyles.labelLarge.copyWith(
                  color: ColorConstants.primaryColor,
                ),
              )),
              const SizedBox(height: 40),

              // OTP Input (6 digits)
              Pinput(
                length: 6,
                controller: controller.otpController,
                focusNode: controller.otpFocusNode,
                defaultPinTheme: PinTheme(
                  width: 48,
                  height: 56,
                  textStyle: TextStyles.h3,
                  decoration: BoxDecoration(
                    color: ColorConstants.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ColorConstants.inputBorder),
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 48,
                  height: 56,
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
                onCompleted: (otp) => controller.verifyOtp(),
              ),

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

              // Verify Button
              Obx(() => PrimaryButton(
                text: 'Verify OTP',
                isLoading: controller.isLoading.value,
                onPressed: controller.verifyOtp,
              )),
              const SizedBox(height: 24),

              // Resend OTP
              Obx(() => controller.canResend.value
                  ? TextButton(
                      onPressed: controller.resendOtp,
                      child: Text(
                        'Resend OTP',
                        style: TextStyles.buttonTextSecondary.copyWith(
                          color: ColorConstants.primaryBlue,
                        ),
                      ),
                    )
                  : Text(
                      'Resend OTP in ${controller.countdown.value}s',
                      style: TextStyles.bodySmall.copyWith(
                        color: ColorConstants.textSecondary,
                      ),
                    )),
              const SizedBox(height: 16),

              // Change Email
              TextButton(
                onPressed: controller.changeEmail,
                child: Text(
                  'Change Email',
                  style: TextStyles.buttonTextSecondary.copyWith(
                    color: ColorConstants.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
