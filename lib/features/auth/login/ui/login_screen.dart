import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../controller/login_controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: ColorConstants.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: ColorConstants.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.show_chart,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // Welcome Text
                Obx(() {
                  if (controller.showEmailField.value) {
                     return Column(
                       children: [
                         Text(
                           'Welcome',
                           style: TextStyles.h2.copyWith(color: ColorConstants.textPrimary),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           'Sign in to continue',
                           style: TextStyles.bodyMedium.copyWith(color: ColorConstants.textSecondary),
                         ),
                       ],
                     );
                  } else {
                     return Column(
                       children: [
                         Text(
                           'Welcome Back',
                           style: TextStyles.h2.copyWith(color: ColorConstants.textPrimary),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           'Hello, ${controller.userName.value}',
                           style: TextStyles.bodyMedium.copyWith(color: ColorConstants.textSecondary),
                         ),
                         const SizedBox(height: 8),
                         TextButton(
                           onPressed: controller.switchAccount, 
                           style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                           ),
                           child: Text(
                             'Switch Account',
                             style: TextStyles.bodySmall.copyWith(color: ColorConstants.primaryBlue),
                           ),
                         ),
                       ],
                     );
                  }
                }),
                const SizedBox(height: 32),

                // Lockout warning
                Obx(() => controller.isLocked.value
                    ? Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ColorConstants.negativeRedLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ColorConstants.negativeRed),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_clock,
                              color: ColorConstants.negativeRed,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Account Locked',
                                    style: TextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: ColorConstants.negativeRed,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Obx(() => Text(
                                    'Try again in ${controller.lockoutTimeDisplay}',
                                    style: TextStyles.bodySmall.copyWith(
                                      color: ColorConstants.negativeRed,
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink()),

                // Email Input (Visible if not returning user)
                Obx(() => controller.showEmailField.value 
                  ? Column(
                      children: [
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
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    )
                  : const SizedBox.shrink()
                ),

                // PIN Input Label
                Text(
                  'Enter your 4 Digit PIN',
                  style: TextStyles.labelLarge.copyWith(
                    color: ColorConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // PIN Input
                Obx(() => AbsorbPointer(
                  absorbing: controller.isLocked.value,
                  child: Opacity(
                    opacity: controller.isLocked.value ? 0.5 : 1.0,
                    child: Pinput(
                      length: 4,
                      controller: controller.pinController,
                      focusNode: controller.pinFocusNode,
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
                      errorPinTheme: PinTheme(
                        width: 60,
                        height: 60,
                        textStyle: TextStyles.h3,
                        decoration: BoxDecoration(
                          color: ColorConstants.negativeRedLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ColorConstants.negativeRed),
                        ),
                      ),
                      onCompleted: (pin) => controller.login(),
                    ),
                  ),
                )),

                // Attempts remaining
                Obx(() => controller.failedAttempts.value > 0 && !controller.isLocked.value
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          '${5 - controller.failedAttempts.value} attempts remaining',
                          style: TextStyles.bodySmall.copyWith(
                            color: ColorConstants.textSecondary,
                          ),
                        ),
                      )
                    : const SizedBox.shrink()),

                // Error Message
                Obx(() => controller.errorMessage.value.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          controller.errorMessage.value,
                          style: TextStyles.bodySmall.copyWith(
                            color: ColorConstants.errorColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox.shrink()),
                const SizedBox(height: 32),

                // Login Button
                Obx(() => PrimaryButton(
                  text: 'Login',
                  isLoading: controller.isLoading.value,
                  onPressed: controller.isLocked.value ? null : controller.login,
                )),
                const SizedBox(height: 24),

                // Forgot PIN
                TextButton(
                  onPressed: controller.forgotPin,
                  child: Text(
                    'Forgot PIN?',
                    style: TextStyles.buttonTextSecondary.copyWith(
                      color: ColorConstants.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // New User Link
                RichText(
                  text: TextSpan(
                    style: TextStyles.bodyMedium,
                    children: [
                      const TextSpan(text: 'New User? '),
                      TextSpan(
                        text: 'Register Now',
                        style: TextStyles.bodyMedium.copyWith(
                          color: ColorConstants.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = controller.goToRegistration,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
