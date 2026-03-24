import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../controller/profile_controller.dart';

class SubscriptionPage extends GetView<ProfileController> {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Refresh profile so we always show the latest subscription data
    controller.loadUser();

    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: ColorConstants.textPrimary),
        ),
        title: Text(
          'Subscription',
          style: TextStyles.h5.copyWith(color: ColorConstants.textPrimary),
        ),
      ),
      body: Obx(() {
        final user = controller.user.value;

        return SingleChildScrollView(
          child: Column(
            children: [
              // Current Plan Card
              _buildCurrentPlanCard(user),
              const SizedBox(height: 24),

              // Contact support to change plan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: ColorConstants.borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.support_agent, size: 40, color: ColorConstants.primaryBlue),
                        const SizedBox(height: 12),
                        Text(
                          'Need to change your plan?',
                          style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contact us to upgrade or modify your subscription.',
                          style: TextStyles.bodySmall.copyWith(color: ColorConstants.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Get.toNamed(AppRoutes.contactUs),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConstants.primaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Contact Us',
                              style: TextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentPlanCard(dynamic user) {
    final planName = user?.planName ?? 'No Plan';
    final expiryDate = user?.planExpiryDate;
    final isExpired = user?.isPlanExpired ?? true;

    String expiryText;
    if (expiryDate != null) {
      final day = expiryDate.day.toString().padLeft(2, '0');
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = months[expiryDate.month];
      final year = expiryDate.year;
      expiryText = isExpired
          ? 'Expired on: $day $month $year'
          : 'Renews on: $day $month $year';
    } else {
      expiryText = 'No expiry date set';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ColorConstants.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'CURRENT PLAN',
                  style: TextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isExpired
                      ? ColorConstants.negativeRed
                      : ColorConstants.positiveGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isExpired ? 'EXPIRED' : 'ACTIVE',
                  style: TextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            planName,
            style: TextStyles.h4.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                expiryText,
                style: TextStyles.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
