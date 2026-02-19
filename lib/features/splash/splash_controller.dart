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
      // Check if first launch
      // Check if user is logged in (has stored user data)
      final user = LocalStorage.getUser();
      if (user != null) {
        debugPrint('SplashController: User found, going to login (PIN)');
        Get.offAllNamed(AppRoutes.login);
      } else {
        debugPrint('SplashController: No user found, going to login (default per user request)');
        Get.offAllNamed(AppRoutes.login);
      }
      return;


    } catch (e) {
      debugPrint('SplashController: Navigation error: $e');
      // Fallback
      Get.offAllNamed(AppRoutes.registration);
    }
  }
}

