import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../storage/local_storage.dart';
import '../../app/routes/app_routes.dart';

class LockdownService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final isLockdownActive = false.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToLockdownState();
  }

  void _listenToLockdownState() {
    try {
      _firestore.collection('app_control').doc('settings').snapshots().listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          final isActive = data?['lockdown_enabled'] ?? false;
          isLockdownActive.value = isActive;

          if (isActive) {
            _checkUserAndForceLogout();
          }
        }
      });
    } catch (e) {
      debugPrint('Error listening to lockdown state: $e');
    }
  }

  Future<void> _checkUserAndForceLogout() async {
    final user = LocalStorage.getUser();
    // Allow admin (hardcoded email check)
    if (user != null && user.email != 'admin@markethub.com') {
      debugPrint('Lockdown active. Forcing logout for ${user.email}');
      
      // Log out
      await LocalStorage.logout();
      Get.offAllNamed(AppRoutes.login); 
      
      Get.snackbar(
        'Maintenance Mode', 
        'The app is currently undergoing mandatory maintenance. Please try again later.',
        snackPosition: SnackPosition.BOTTOM, 
        duration: const Duration(seconds: 10),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        isDismissible: false,
      );
    }
  }

  Future<void> enableLockdown() async {
    await _firestore.collection('app_control').doc('settings').set({
      'lockdown_enabled': true,
      'updated_at': FieldValue.serverTimestamp(),
      'updated_by': 'admin@markethub.com',
    }, SetOptions(merge: true));
  }

  Future<void> disableLockdown() async {
    await _firestore.collection('app_control').doc('settings').set({
      'lockdown_enabled': false,
      'updated_at': FieldValue.serverTimestamp(),
      'updated_by': 'admin@markethub.com',
    }, SetOptions(merge: true));
  }
}
