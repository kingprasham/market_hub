import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/services/admin_api_service.dart';
import '../../../data/models/user/user_model.dart';

class ProfileController extends GetxController {
  final user = Rxn<UserModel>();
  final isLoading = false.obs;

  // Settings
  final notificationsEnabled = true.obs;
  final priceAlertsEnabled = true.obs;
  final newsAlertsEnabled = true.obs;
  final darkModeEnabled = false.obs;
  final biometricEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUser();
    loadSettings();
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    String? whatsapp,
  }) async {
    isLoading.value = true;
    try {
      final api = Get.find<AdminApiService>();
      final result = await api.updateProfile(
        fullName: fullName,
        email: email,
        phone: phone,
        whatsapp: whatsapp,
      );

      if (result['success'] == true) {
        // Update stored user
        final updatedUserMap = result['user'];
        // Ensure ID is string
        if (updatedUserMap['id'] is int) {
          updatedUserMap['id'] = updatedUserMap['id'].toString();
        }
        
        final updatedUser = UserModel.fromJson(updatedUserMap);
        await LocalStorage.saveUser(updatedUser);
        
        // Update observable
        user.value = updatedUser;
        
        Helpers.showSuccess('Profile updated successfully');
        Get.back();
      } else {
        Helpers.showError(result['error'] ?? 'Failed to update profile');
      }
    } catch (e) {
      Helpers.showError('Error updating profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUser() async {
    // First load from local storage for quick display
    user.value = LocalStorage.getUser();

    // Then fetch fresh data from API
    try {
      final apiService = Get.find<AdminApiService>();

      // Check if we have user data in API service
      if (apiService.isLoggedIn.value && apiService.currentUser.value != null) {
        final apiUser = UserModel.fromJson(apiService.currentUser.value!);
        user.value = apiUser;
        await LocalStorage.saveUser(apiUser);
      } else {
        // Try to reload profile from server
        await _reloadProfileFromServer();
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  Future<void> _reloadProfileFromServer() async {
    try {
      final apiService = Get.find<AdminApiService>();
      final token = await LocalStorage.getAuthToken();

      if (token != null && token.isNotEmpty) {
        // Trigger the API service to reload profile
        await apiService.init();

        // After reload, get the user data
        if (apiService.currentUser.value != null) {
          final apiUser = UserModel.fromJson(apiService.currentUser.value!);
          user.value = apiUser;
          await LocalStorage.saveUser(apiUser);
        }
      }
    } catch (e) {
      debugPrint('Error reloading profile from server: $e');
    }
  }

  void loadSettings() {
    // Load settings from local storage
    notificationsEnabled.value = true;
    priceAlertsEnabled.value = true;
    newsAlertsEnabled.value = true;
    darkModeEnabled.value = false;
    biometricEnabled.value = false;
  }

  Future<void> toggleNotifications(bool value) async {
    notificationsEnabled.value = value;
    if (!value) {
      priceAlertsEnabled.value = false;
      newsAlertsEnabled.value = false;
    }
    await _saveSettings();
  }

  Future<void> togglePriceAlerts(bool value) async {
    if (notificationsEnabled.value) {
      priceAlertsEnabled.value = value;
      await _saveSettings();
    }
  }

  Future<void> toggleNewsAlerts(bool value) async {
    if (notificationsEnabled.value) {
      newsAlertsEnabled.value = value;
      await _saveSettings();
    }
  }

  Future<void> toggleDarkMode(bool value) async {
    darkModeEnabled.value = value;
    await _saveSettings();
    Helpers.showSnackBar(message: 'Theme will be applied on restart');
  }

  Future<void> toggleBiometric(bool value) async {
    biometricEnabled.value = value;
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    // Save settings to local storage
  }

  Future<void> changePIN() async {
    Get.toNamed(AppRoutes.changePin);
  }

  Future<void> logout() async {
    isLoading.value = true;

    try {
      await LocalStorage.clear();
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Helpers.showError('Failed to logout');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action is irreversible. All your data will be permanently deleted. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              isLoading.value = true;
              try {
                // API call to delete account would go here
                await LocalStorage.clear();
                Helpers.showSuccess('Account deleted');
                Get.offAllNamed(AppRoutes.login);
              } catch (e) {
                Helpers.showError('Failed to delete account');
              } finally {
                isLoading.value = false;
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: ColorConstants.negativeRed),
            ),
          ),
        ],
      ),
    );
  }
}

