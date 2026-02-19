import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../data/models/plan/plan_model.dart';
import '../controller/plan_selection_controller.dart';

class PlanSelectionScreen extends GetView<PlanSelectionController> {
  const PlanSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Header
            Text(
              'Choose Your Plan',
              style: TextStyles.h2.copyWith(
                color: ColorConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select a plan that suits your needs',
                style: TextStyles.bodyMedium.copyWith(
                  color: ColorConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            // Plan Cards
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ColorConstants.primaryColor,
                    ),
                  );
                }

                return CarouselSlider.builder(
                  itemCount: controller.plans.length,
                  options: CarouselOptions(
                    height: 400,
                    enlargeCenterPage: true,
                    viewportFraction: 0.8,
                    onPageChanged: (index, reason) {
                      controller.selectedPlanIndex.value = index;
                    },
                  ),
                  itemBuilder: (context, index, realIndex) {
                    final plan = controller.plans[index];
                    return _buildPlanCard(plan, index);
                  },
                );
              }),
            ),

            // Page indicators
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                controller.plans.length,
                (index) => Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: controller.selectedPlanIndex.value == index
                        ? ColorConstants.primaryColor
                        : ColorConstants.borderColor,
                  ),
                ),
              ),
            )),
            const SizedBox(height: 24),

            // Select Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Obx(() => PrimaryButton(
                text: 'Select Plan',
                isLoading: controller.isSubmitting.value,
                onPressed: controller.selectPlan,
              )),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(PlanModel plan, int index) {
    return Obx(() {
      final isSelected = controller.selectedPlanIndex.value == index;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? ColorConstants.primaryColor
                : ColorConstants.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? ColorConstants.primaryColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? ColorConstants.primaryGradient
                    : const LinearGradient(
                        colors: [Color(0xFFEEEEEE), Color(0xFFE0E0E0)],
                      ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Column(
                children: [
                  if (plan.isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'POPULAR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  Text(
                    plan.name,
                    style: TextStyles.h4.copyWith(
                      color: isSelected ? Colors.white : ColorConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.formattedPrice,
                    style: TextStyles.priceLarge.copyWith(
                      color: isSelected ? Colors.white : ColorConstants.textPrimary,
                    ),
                  ),
                  Text(
                    plan.durationLabel,
                    style: TextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : ColorConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Features
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ListView.builder(
                  itemCount: plan.features.length,
                  itemBuilder: (context, idx) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 20,
                            color: ColorConstants.positiveGreen,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              plan.features[idx],
                              style: TextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
