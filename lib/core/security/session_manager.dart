import 'package:get/get.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../storage/local_storage.dart';
import '../../app/routes/app_routes.dart';

/// SessionManager handles single device login enforcement
/// When a user logs in on a new device, the old device is automatically logged out
class SessionManager extends GetxService {
  static SessionManager get to => Get.find();
  
  final _deviceInfoPlugin = DeviceInfoPlugin();
  final _uuid = const Uuid();
  
  String? _currentDeviceToken;
  
  /// Initialize session manager and generate device token
  Future<SessionManager> init() async {
    _currentDeviceToken = await _generateDeviceToken();
    return this;
  }
  
  /// Generate a unique device token based on device info
  Future<String> _generateDeviceToken() async {
    String deviceId = '';
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? _uuid.v4();
      } else {
        deviceId = _uuid.v4();
      }
    } catch (e) {
      deviceId = _uuid.v4();
    }
    
    // Combine device ID with a UUID for extra uniqueness
    return '${deviceId}_${_uuid.v4()}';
  }
  
  /// Get the current device token
  String? get currentDeviceToken => _currentDeviceToken;
  
  /// Save device token when user logs in
  Future<void> registerSession() async {
    if (_currentDeviceToken != null) {
      await LocalStorage.saveDeviceToken(_currentDeviceToken!);
    }
  }
  
  /// Validate if this device is still authorized
  /// Returns true if session is valid, false if logged out from another device
  Future<bool> validateSession(String? serverDeviceToken) async {
    if (serverDeviceToken == null) return true;
    
    final localToken = await LocalStorage.getDeviceToken();
    
    if (localToken == null) {
      // No local token, session invalid
      return false;
    }
    
    if (serverDeviceToken != localToken) {
      // Another device has logged in, force logout
      await forceLogout('You have been logged out because another device logged into your account.');
      return false;
    }
    
    return true;
  }
  
  /// Force logout and redirect to login screen
  Future<void> forceLogout(String message) async {
    await LocalStorage.logout();
    Get.offAllNamed(AppRoutes.login);
    Get.snackbar(
      'Session Expired',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }
  
  /// Clear session on logout
  Future<void> clearSession() async {
    await LocalStorage.deleteDeviceToken();
    _currentDeviceToken = await _generateDeviceToken();
  }
  
  /// Check if user has an active session
  Future<bool> hasActiveSession() async {
    final token = await LocalStorage.getDeviceToken();
    return token != null;
  }
}
