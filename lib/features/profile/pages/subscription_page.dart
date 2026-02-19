import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../app/routes/app_routes.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Current Plan Card
            _buildCurrentPlanCard(),
            const SizedBox(height: 24),

            // Available Plans
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Available Plans',
                  style: TextStyles.h6.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),

            _buildPlanCard(
              name: 'Basic',
              price: '₹0',
              period: '/month',
              features: [
                'Daily spot prices',
                'Basic news updates',
                'Limited market data',
              ],
              isCurrentPlan: false,
              color: Colors.grey,
            ),

            _buildPlanCard(
              name: 'Professional',
              price: '₹999',
              period: '/month',
              features: [
                'Real-time spot prices',
                'All news & circulars',
                'Price alerts',
                'Economic calendar',
                'Watchlist (50 items)',
              ],
              isCurrentPlan: true,
              color: ColorConstants.primaryBlue,
              isPopular: true,
            ),

            _buildPlanCard(
              name: 'Enterprise',
              price: '₹2,499',
              period: '/month',
              features: [
                'Everything in Professional',
                'API access',
                'Unlimited watchlist',
                'Priority support',
                'Custom alerts',
                'Export data',
              ],
              isCurrentPlan: false,
              color: ColorConstants.primaryOrange,
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard() {
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
                  color: ColorConstants.positiveGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ACTIVE',
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
            'Professional Plan',
            style: TextStyles.h4.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '₹999/month',
            style: TextStyles.h5.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                'Renews on: Jan 15, 2025',
                style: TextStyles.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String name,
    required String price,
    required String period,
    required List<String> features,
    required bool isCurrentPlan,
    required Color color,
    bool isPopular = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentPlan
            ? Border.all(color: color, width: 2)
            : Border.all(color: ColorConstants.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  'POPULAR',
                  style: TextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyles.h5.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyles.h3.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      period,
                      style: TextStyles.bodySmall.copyWith(
                        color: ColorConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: color, size: 18),
                          const SizedBox(width: 8),
                          Text(feature, style: TextStyles.bodySmall),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan ? null : () {
                      Get.toNamed(AppRoutes.contactUs);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan ? Colors.grey[300] : color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isCurrentPlan ? 'Current Plan' : 'Upgrade',
                      style: TextStyles.bodyMedium.copyWith(
                        color: isCurrentPlan ? ColorConstants.textSecondary : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
