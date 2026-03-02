import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../controller/pending_approval_controller.dart';

class PendingApprovalScreen extends GetView<PendingApprovalController> {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              // Waiting Animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: ColorConstants.warningColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top,
                  size: 60,
                  color: ColorConstants.warningColor,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Account Under Verification',
                style: TextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'Your account is being reviewed by our team. You will be notified once approved.',
                style: TextStyles.bodyMedium.copyWith(
                  color: ColorConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildStatusRow('Registration', true),
                    const Divider(height: 24),
                    _buildStatusRow('Email Verification', true),
                    const Divider(height: 24),
                    _buildStatusRow('PIN Setup', true),
                    const Divider(height: 24),
                    _buildStatusRow('Plan Selection', true),
                    const Divider(height: 24),
                    _buildStatusRow('Admin Approval', false, isPending: true),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Retry Button
              Obx(() => PrimaryButton(
                text: 'Check Status',
                isLoading: controller.isLoading.value,
                onPressed: controller.checkStatus,
                icon: Icons.refresh,
              )),
              const SizedBox(height: 16),

              // Contact Support
              TextButton.icon(
                onPressed: controller.contactSupport,
                icon: const Icon(
                  Icons.headset_mic_outlined,
                  color: ColorConstants.primaryBlue,
                ),
                label: Text(
                  'Contact Support',
                  style: TextStyles.buttonTextSecondary.copyWith(
                    color: ColorConstants.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String title, bool completed, {bool isPending = false}) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: completed
                ? ColorConstants.positiveGreen
                : isPending
                    ? ColorConstants.warningColor
                    : ColorConstants.borderColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            completed
                ? Icons.check
                : isPending
                    ? Icons.hourglass_empty
                    : Icons.circle_outlined,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyles.bodyMedium.copyWith(
              color: completed ? ColorConstants.textPrimary : ColorConstants.textSecondary,
            ),
          ),
        ),
        Text(
          completed ? 'Done' : isPending ? 'Pending' : '',
          style: TextStyles.bodySmall.copyWith(
            color: completed
                ? ColorConstants.positiveGreen
                : ColorConstants.warningColor,
          ),
        ),
      ],
    );
  }
}
