import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/inputs/custom_text_field.dart';
import '../controller/registration_controller.dart';

class RegistrationScreen extends GetView<RegistrationController> {
  const RegistrationScreen({super.key});

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
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text('Hello there,', style: TextStyles.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  'Register Account',
                  style: TextStyles.h2.copyWith(
                    color: ColorConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name
                CustomTextField(
                  controller: controller.nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: controller.validateName,
                ),
                const SizedBox(height: 20),

                // WhatsApp Number
                Obx(() => PhoneTextField(
                  controller: controller.whatsappController,
                  label: 'WhatsApp Number',
                  hint: 'Enter WhatsApp number',
                  countryCode: controller.whatsappCountryCode.value,
                  onCountryCodeTap: () => controller.selectCountryCode(true),
                  validator: controller.validatePhone,
                )),
                const SizedBox(height: 20),

                // Phone Number
                Obx(() => PhoneTextField(
                  controller: controller.phoneController,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  countryCode: controller.phoneCountryCode.value,
                  onCountryCodeTap: () => controller.selectCountryCode(false),
                  validator: controller.validatePhone,
                )),
                const SizedBox(height: 20),

                // Email
                CustomTextField(
                  controller: controller.emailController,
                  label: 'Email Address',
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: controller.validateEmail,
                ),
                const SizedBox(height: 20),

                // Set PIN
                CustomTextField(
                  controller: controller.pincodeController,
                  label: 'Set Custom 4-Digit PIN',
                  hint: 'Enter 4-digit PIN for login',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.password_outlined),
                  validator: controller.validatePincode,
                ),
                const SizedBox(height: 20),

                // Confirm PIN
                CustomTextField(
                  controller: controller.confirmPincodeController,
                  label: 'Confirm 4-Digit PIN',
                  hint: 'Re-enter 4-digit PIN',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.password_outlined),
                  validator: controller.validateConfirmPincode,
                ),
                const SizedBox(height: 20),

                // Visiting Card
                Text(
                  'Visiting Card',
                  style: TextStyles.labelMedium.copyWith(
                    color: ColorConstants.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => InkWell(
                  onTap: controller.pickVisitingCard,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: ColorConstants.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: controller.visitingCardError.value != null
                            ? ColorConstants.errorColor
                            : ColorConstants.inputBorder,
                      ),
                    ),
                    child: controller.visitingCardPath.value != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  controller.visitingCardPath.value!,
                                  width: double.infinity,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.image, size: 40),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: controller.removeVisitingCard,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.upload_file,
                                size: 40,
                                color: ColorConstants.textSecondary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to upload visiting card',
                                style: TextStyles.bodySmall,
                              ),
                            ],
                          ),
                  ),
                )),
                Obx(() => controller.visitingCardError.value != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8, left: 12),
                        child: Text(
                          controller.visitingCardError.value!,
                          style: TextStyles.bodySmall.copyWith(
                            color: ColorConstants.errorColor,
                          ),
                        ),
                      )
                    : const SizedBox.shrink()),
                const SizedBox(height: 24),

                // Terms & Conditions
                Obx(() => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: controller.termsAccepted.value,
                        onChanged: (value) =>
                            controller.termsAccepted.value = value ?? false,
                        activeColor: ColorConstants.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyles.bodySmall,
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: TextStyles.bodySmall.copyWith(
                                color: ColorConstants.primaryBlue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = controller.openTerms,
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyles.bodySmall.copyWith(
                                color: ColorConstants.primaryBlue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = controller.openPrivacyPolicy,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )),
                const SizedBox(height: 32),

                // Register Button
                Obx(() => PrimaryButton(
                  text: 'Register',
                  isLoading: controller.isLoading.value,
                  onPressed: controller.register,
                )),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyles.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Login Link
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyles.bodyMedium,
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Login',
                          style: TextStyles.bodyMedium.copyWith(
                            color: ColorConstants.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = controller.goToLogin,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
