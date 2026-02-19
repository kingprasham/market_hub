import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/text_styles.dart';

class FeedbackController extends GetxController {
  final feedbackText = ''.obs;
  final selectedRating = 0.obs;
  final isSubmitting = false.obs;
  final selectedCategory = 'General'.obs;

  final categories = [
    'General',
    'Bug Report',
    'Feature Request',
    'Data Accuracy',
    'Performance',
    'Other',
  ];

  Future<void> submitFeedback() async {
    if (feedbackText.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your feedback',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstants.negativeRed,
        colorText: Colors.white,
      );
      return;
    }

    isSubmitting.value = true;
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    isSubmitting.value = false;
    
    Get.snackbar(
      'Thank You!',
      'Your feedback has been submitted successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: ColorConstants.positiveGreen,
      colorText: Colors.white,
    );
    
    Get.back();
  }
}

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FeedbackController());
    return _FeedbackPageContent(controller: controller);
  }
}

class _FeedbackPageContent extends StatelessWidget {
  final FeedbackController controller;

  const _FeedbackPageContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _buildScaffold();
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back,
            color: ColorConstants.textPrimary,
          ),
        ),
        title: Text(
          'Feedback',
          style: TextStyles.h4.copyWith(color: ColorConstants.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.rate_review_outlined,
                      size: 36,
                      color: ColorConstants.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We Value Your Feedback',
                    style: TextStyles.h4,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help us improve Market Hub',
                    style: TextStyles.bodyMedium.copyWith(
                      color: ColorConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Rating
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How would you rate your experience?',
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => controller.selectedRating.value = index + 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              index < controller.selectedRating.value
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 40,
                              color: index < controller.selectedRating.value
                                  ? Colors.amber
                                  : ColorConstants.textSecondary,
                            ),
                          ),
                        );
                      }),
                    )),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Category
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(() => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.categories.map((category) {
                      final isSelected = controller.selectedCategory.value == category;
                      return InkWell(
                        onTap: () => controller.selectedCategory.value = category,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ColorConstants.primaryBlue
                                : ColorConstants.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyles.bodySmall.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : ColorConstants.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Feedback Text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Feedback',
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    maxLines: 5,
                    onChanged: (value) => controller.feedbackText.value = value,
                    decoration: InputDecoration(
                      hintText: 'Tell us what you think...',
                      hintStyle: TextStyles.bodyMedium.copyWith(
                        color: ColorConstants.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: ColorConstants.borderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: ColorConstants.borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: ColorConstants.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Submit Button
            Obx(() => SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : controller.submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: controller.isSubmitting.value
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Submit Feedback',
                        style: TextStyles.buttonText.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
            )),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
