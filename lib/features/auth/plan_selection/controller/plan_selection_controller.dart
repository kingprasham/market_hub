import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../data/models/plan/plan_model.dart';

class PlanSelectionController extends GetxController {
  final plans = <PlanModel>[].obs;
  final selectedPlanIndex = 0.obs;
  final isLoading = true.obs;
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    isLoading.value = true;

    try {
      final response = await ApiClient().get(ApiConstants.plans);

      if (response.data != null && response.data['success'] == true) {
        final planList = (response.data['data'] as List)
            .map((json) => PlanModel.fromJson(json))
            .toList();
        plans.assignAll(planList);
      }
    } catch (e) {
      // Load demo plans
      plans.assignAll(_getDemoPlans());
    } finally {
      isLoading.value = false;
    }
  }

  List<PlanModel> _getDemoPlans() {
    return [
      PlanModel(
        id: '1',
        name: 'Basic',
        description: 'Perfect for beginners',
        features: [
          'Real-time LME prices',
          'Basic spot prices',
          'Daily news updates',
          'Email support',
        ],
        price: 999,
        duration: 'monthly',
        durationDays: 30,
      ),
      PlanModel(
        id: '2',
        name: 'Professional',
        description: 'Best for traders',
        features: [
          'All Basic features',
          'All exchange prices',
          'FX rates',
          'Economic calendar',
          'Priority support',
          'Watchlist feature',
        ],
        price: 2499,
        duration: 'monthly',
        durationDays: 30,
        isPopular: true,
      ),
      PlanModel(
        id: '3',
        name: 'Enterprise',
        description: 'Complete access',
        features: [
          'All Professional features',
          'Hindi news',
          'Circulars & documents',
          'Reference rates',
          'Dedicated support',
          'Custom alerts',
        ],
        price: 4999,
        duration: 'monthly',
        durationDays: 30,
      ),
    ];
  }

  Future<void> selectPlan() async {
    if (plans.isEmpty) return;

    final selectedPlan = plans[selectedPlanIndex.value];
    isSubmitting.value = true;

    try {
      final response = await ApiClient().post(
        ApiConstants.selectPlan,
        data: {'planId': selectedPlan.id},
      );

      if (response.data != null && response.data['success'] == true) {
        // Update user with selected plan
        await LocalStorage.updateUser((user) => user.copyWith(
          planId: selectedPlan.id,
          planName: selectedPlan.name,
        ));

        Get.offAllNamed(AppRoutes.pendingApproval);
      } else {
        Helpers.showError(response.data['message'] ?? 'Failed to select plan');
      }
    } catch (e) {
      // For demo, proceed
      await LocalStorage.updateUser((user) => user.copyWith(
        planId: selectedPlan.id,
        planName: selectedPlan.name,
      ));
      Get.offAllNamed(AppRoutes.pendingApproval);
    } finally {
      isSubmitting.value = false;
    }
  }
}
