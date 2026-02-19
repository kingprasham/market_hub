import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/admin_api_service.dart';
import '../../../../core/utils/helpers.dart';

class PriceAlertsController extends GetxController {
  late final AdminApiService _api;

  final RxList<Map<String, dynamic>> alerts = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  // Form Controllers
  final metalController = Rx<String?>(null);
  final conditionController = Rx<String?>(null);
  final targetPriceController = TextEditingController();

  // Available Metals (In a real app, this should come from SpotPriceController or API)
  final List<String> availableMetals = [
    'Copper Wire Bar',
    'Copper Armature',
    'Aluminium Ingot',
    'Aluminium Utensil',
    'Brass Sheet',
    'Brass Honey',
    'Zinc HG',
    'Zinc Dross',
    'Lead Ingot',
    'Lead Batteries',
    'Tin Ingot',
    'Nickel Cathode',
  ];

  @override
  void onInit() {
    super.onInit();
    _api = Get.find<AdminApiService>();
    fetchAlerts();
  }

  @override
  void onClose() {
    targetPriceController.dispose();
    super.onClose();
  }

  Future<void> fetchAlerts() async {
    isLoading.value = true;
    try {
      // Check if user is logged in
      if (!_api.isLoggedIn.value) {
        debugPrint('User not logged in, cannot fetch alerts');
        Helpers.showError('Please login to view alerts');
        return;
      }

      final result = await _api.getPriceAlerts();
      alerts.assignAll(result);
      debugPrint('Fetched ${result.length} price alerts');
    } catch (e) {
      debugPrint('Error fetching price alerts: $e');
      Helpers.showError('Failed to load price alerts');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createAlert() async {
    if (metalController.value == null ||
        conditionController.value == null ||
        targetPriceController.text.isEmpty) {
      Helpers.showError('Please fill all fields');
      return;
    }

    final price = double.tryParse(targetPriceController.text);
    if (price == null) {
      Helpers.showError('Invalid price');
      return;
    }

    isLoading.value = true;
    try {
      final result = await _api.addPriceAlert(
        metal: metalController.value!,
        location: 'All', // Default for now
        targetPrice: price,
        conditionType: conditionController.value!,
      );

      if (result['success'] == true) { // Check for explicit success flag or existence of 'alert'
         Helpers.showSuccess('Price alert created');
         // Reset form
         metalController.value = null;
         conditionController.value = null;
         targetPriceController.clear();
         Get.back(); // Close dialog
         fetchAlerts(); // Refresh list
      } else {
         Helpers.showError(result['error'] ?? 'Failed to create alert');
      }

    } catch (e) {
      Helpers.showError('Error creating alert: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAlert(int id) async {
    try {
      // Optimistic update
      final index = alerts.indexWhere((element) => element['id'] == id);
      if (index != -1) {
        final removed = alerts.removeAt(index);
        
        final result = await _api.deletePriceAlert(id);
        if (result['success'] != true) {
          // Revert if failed
          alerts.insert(index, removed);
          Helpers.showError(result['error'] ?? 'Failed to delete alert');
        } else {
           Get.snackbar('Deleted', 'Alert removed', snackPosition: SnackPosition.BOTTOM);
        }
      }
    } catch (e) {
      Helpers.showError('Error deleting alert: $e');
      fetchAlerts(); // Re-sync on error
    }
  }
}
