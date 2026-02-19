import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/services/admin_api_service.dart';
import '../../../../core/utils/helpers.dart';
import '../../../admin/ui/admin_lockdown_page.dart';
import '../../../../core/services/lockdown_service.dart';

class LoginController extends GetxController {
  final pinController = TextEditingController();
  final emailController = TextEditingController();
  final pinFocusNode = FocusNode();
  final emailFocusNode = FocusNode();

  final userName = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final isLocked = false.obs;
  final failedAttempts = 0.obs;
  final lockEndTime = Rxn<DateTime>();
  final remainingLockoutSeconds = 0.obs;
  Timer? _lockoutTimer;
  
  final showEmailField = false.obs;
  
  // Rate limiting
  static const int maxAttempts = 5;
  static const int lockoutDurationMinutes = 3;

  String get lockoutTimeDisplay {
    if (lockEndTime.value == null) return '';
    final difference = lockEndTime.value!.difference(DateTime.now());
    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    _checkLockoutStatus();
  }

  void _loadUser() {
    final user = LocalStorage.getUser();
    if (user != null) {
      userName.value = user.fullName.split(' ').first;
      emailController.text = user.email; // Pre-fill email for API call
      showEmailField.value = false;
    } else {
      userName.value = '';
      emailController.clear();
      showEmailField.value = true;
    }
  }
  
  void switchAccount() {
    userName.value = '';
    showEmailField.value = true;
    pinController.clear();
    emailController.clear();
  }

  Future<void> _checkLockoutStatus() async {
    final lockoutEnd = await LocalStorage.getLockoutEndTime();
    if (lockoutEnd != null && lockoutEnd.isAfter(DateTime.now())) {
      isLocked.value = true;
      lockEndTime.value = lockoutEnd;
      _startLockoutTimer();
    } else {
      // Clear lockout if expired
      await LocalStorage.clearLockout();
      final attempts = await LocalStorage.getFailedAttempts();
      failedAttempts.value = attempts;
    }
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _updateRemainingTime();

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
      if (remainingLockoutSeconds.value <= 0) {
        timer.cancel();
        isLocked.value = false;
        lockEndTime.value = null;
        failedAttempts.value = 0;
        LocalStorage.clearLockout();
      }
    });
  }

  void _updateRemainingTime() {
    if (lockEndTime.value != null) {
      final diff = lockEndTime.value!.difference(DateTime.now());
      remainingLockoutSeconds.value = diff.inSeconds > 0 ? diff.inSeconds : 0;
    }
  }

  @override
  void onClose() {
    pinController.dispose();
    emailController.dispose();
    pinFocusNode.dispose();
    emailFocusNode.dispose();
    _lockoutTimer?.cancel();
    super.onClose();
  }

  Future<void> login() async {
    if (isLocked.value) return;
    
    // If showing email field, validate it
    if (showEmailField.value && emailController.text.isEmpty) {
      errorMessage.value = 'Please enter your email';
      return;
    }

    if (pinController.text.length != 4) {
      errorMessage.value = 'Please enter 4-digit PIN';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    
    // CHECK GLOBAL LOCKDOWN
    if (Get.isRegistered<LockdownService>()) {
      final lockdownService = Get.find<LockdownService>();
      if (lockdownService.isLockdownActive.value) {
        // Allow ONLY admin
        if (emailController.text.trim() != 'admin@markethub.com') {
          isLoading.value = false;
          errorMessage.value = 'Maintenance Mode Active. Login disabled.';
          Get.snackbar(
            'Maintenance Mode', 
            'The app is currently undergoing mandatory maintenance. Please try again later.',
            snackPosition: SnackPosition.BOTTOM, 
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }
    }

    // HARDCODED ADMIN CHECK
    try {
      if (emailController.text.trim() == 'admin@markethub.com' && pinController.text == '1234') {
        isLoading.value = false;
        // Initialize Lockdown Service if not initialized
        if (!Get.isRegistered<LockdownService>()) {
          Get.put(LockdownService());
        }
        
        Get.to(() => const AdminLockdownPage());
        return;
      }

      // Call Admin API for login
      final adminApi = Get.find<AdminApiService>();
      final response = await adminApi.login(
        email: emailController.text.trim(),
        pin: pinController.text,
      );

      if (response['success'] == true) {
        // Reset failed attempts on successful login
        failedAttempts.value = 0;
        await LocalStorage.clearLockout();

        // Update local user data
        final userData = response['user'];
        if (userData != null) {
          await LocalStorage.updateUser((user) => user.copyWith(
            isApproved: true,
            planId: userData['plan_id']?.toString(),
            planName: userData['plan_name'],
          ));
        }

        // Connect WebSocket if available
        try {
          final wsService = Get.find<WebSocketService>();
          final token = await LocalStorage.getAuthToken();
          if (token != null) {
            wsService.connect(token);
          }
        } catch (_) {}

        Helpers.showSuccess('Login successful!');

        // Navigate to main
        Get.offAllNamed(AppRoutes.main);
      } else {
        await _handleFailedAttempt();
        errorMessage.value = response['error'] ?? 'Login failed';
        pinController.clear();
      }
    } catch (e) {
      debugPrint('LOGIN CONTROLLER ERROR: $e');
      await _handleFailedAttempt();
      errorMessage.value = 'Login failed: $e'; // Show exact error to user for debugging
      pinController.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleFailedAttempt() async {
    failedAttempts.value++;
    await LocalStorage.saveFailedAttempts(failedAttempts.value);

    if (failedAttempts.value >= maxAttempts) {
      // Lock out the user
      final lockoutEnd = DateTime.now().add(const Duration(minutes: lockoutDurationMinutes));
      await LocalStorage.saveLockoutEndTime(lockoutEnd);

      isLocked.value = true;
      lockEndTime.value = lockoutEnd;
      _startLockoutTimer();

      errorMessage.value = 'Too many failed attempts. Locked for $lockoutDurationMinutes minutes.';
    } else {
      final remaining = maxAttempts - failedAttempts.value;
      errorMessage.value = 'Incorrect PIN. $remaining attempts remaining.';
    }
  }

  void forgotPin() {
    Get.toNamed(AppRoutes.forgotPin);
  }

  void goToRegistration() {
    Get.offAllNamed(AppRoutes.registration);
  }
}
