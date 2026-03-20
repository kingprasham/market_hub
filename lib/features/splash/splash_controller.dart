import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../core/storage/local_storage.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    debugPrint('SplashController: onInit called');
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    debugPrint('SplashController: Starting navigation delay');
    
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 3));
    
    debugPrint('SplashController: Delay complete, checking auth state');
    
    try {
      // Check if user is logged in (has stored user data in Hive)
      // Hive is a reliable local database that persists across app restarts.
      // We do NOT gate on the auth token from secure storage because:
      // 1) Secure storage can fail when device is locked
      // 2) AdminApiService.init() can clear the token on transient 401 errors
      // 3) The user already authenticated with their PIN previously
      final user = LocalStorage.getUser();
      
      if (user != null) {
        debugPrint('SplashController: User found in local storage (${user.email}), going to main');
        Get.offAllNamed(AppRoutes.main);
      } else {
        debugPrint('SplashController: No user found, going to login');
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      debugPrint('SplashController: Navigation error: $e');
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
