import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/user/user_model.dart';
import '../constants/app_constants.dart';

class LocalStorage {
  static late Box<UserModel> _userBox;
  static late Box<dynamic> _cacheBox;
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    // Register Hive adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }

    // Open boxes
    _userBox = await Hive.openBox<UserModel>('user');
    _cacheBox = await Hive.openBox('cache');

    _isInitialized = true;
  }

  // User operations
  static Future<void> saveUser(UserModel user) async {
    await _userBox.put(AppConstants.userKey, user);
  }

  static UserModel? getUser() {
    return _userBox.get(AppConstants.userKey);
  }

  static Future<void> deleteUser() async {
    await _userBox.delete(AppConstants.userKey);
  }

  static Future<void> updateUser(UserModel Function(UserModel) updater) async {
    final user = getUser();
    if (user != null) {
      final updatedUser = updater(user);
      await saveUser(updatedUser);
    }
  }

  // Secure PIN storage
  static Future<void> savePin(String pin) async {
    await _secureStorage.write(key: AppConstants.pinKey, value: pin);
  }

  static Future<String?> getPin() async {
    return await _secureStorage.read(key: AppConstants.pinKey);
  }

  static Future<void> deletePin() async {
    await _secureStorage.delete(key: AppConstants.pinKey);
  }

  static Future<bool> verifyPin(String enteredPin) async {
    final storedPin = await getPin();
    return storedPin != null && storedPin == enteredPin;
  }

  // Device token for single device login
  static Future<void> saveDeviceToken(String token) async {
    await _secureStorage.write(key: AppConstants.deviceTokenKey, value: token);
  }

  static Future<String?> getDeviceToken() async {
    return await _secureStorage.read(key: AppConstants.deviceTokenKey);
  }

  static Future<void> deleteDeviceToken() async {
    await _secureStorage.delete(key: AppConstants.deviceTokenKey);
  }

  // Auth Token
  static Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
  }

  static Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: AppConstants.tokenKey);
  }

  static Future<void> deleteAuthToken() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
  }

  // First launch check
  static Future<bool> isFirstLaunch() async {
    final value = _cacheBox.get(AppConstants.isFirstLaunchKey);
    return value == null || value == true;
  }

  static Future<void> setFirstLaunchComplete() async {
    await _cacheBox.put(AppConstants.isFirstLaunchKey, false);
  }

  // Cache operations
  static Future<void> cacheData(String key, dynamic data) async {
    await _cacheBox.put(key, data);
  }

  static dynamic getCachedData(String key) {
    return _cacheBox.get(key);
  }

  static Future<void> deleteCachedData(String key) async {
    await _cacheBox.delete(key);
  }

  // Market data cache
  static Future<void> cacheMarketData(String channel, Map<String, dynamic> data) async {
    await _cacheBox.put('market_$channel', data);
  }

  static Map<String, dynamic>? getCachedMarketData(String channel) {
    final data = _cacheBox.get('market_$channel');
    if (data != null && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  // Login rate limiting
  static Future<void> saveFailedAttempts(int attempts) async {
    await _cacheBox.put('failed_login_attempts', attempts);
  }

  static Future<int> getFailedAttempts() async {
    return _cacheBox.get('failed_login_attempts') ?? 0;
  }

  static Future<void> saveLockoutEndTime(DateTime endTime) async {
    await _cacheBox.put('lockout_end_time', endTime.toIso8601String());
  }

  static Future<DateTime?> getLockoutEndTime() async {
    final value = _cacheBox.get('lockout_end_time');
    if (value != null && value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static Future<void> clearLockout() async {
    await _cacheBox.delete('failed_login_attempts');
    await _cacheBox.delete('lockout_end_time');
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _userBox.clear();
    await _cacheBox.clear();
    await _secureStorage.deleteAll();
  }

  // Logout - clear sensitive data only
  static Future<void> logout() async {
    await deleteAuthToken();
    await deletePin();
    await deleteDeviceToken();
    await _userBox.clear();
  }
  
  /// Alias for logout (backward compatibility)
  static Future<void> clear() async {
    await logout();
  }

  // Notification storage
  static const String _notificationsKey = 'stored_notifications';

  /// Save a notification to local storage
  static Future<void> addNotification(Map<String, dynamic> notification) async {
    final notifications = getNotifications();
    notifications.insert(0, notification);
    // Keep only last 100 notifications
    if (notifications.length > 100) {
      notifications.removeRange(100, notifications.length);
    }
    await _cacheBox.put(_notificationsKey, notifications);
  }

  /// Get all stored notifications
  static List<Map<String, dynamic>> getNotifications() {
    final data = _cacheBox.get(_notificationsKey);
    if (data != null && data is List) {
      return List<Map<String, dynamic>>.from(
        data.map((item) => Map<String, dynamic>.from(item as Map)),
      );
    }
    return [];
  }

  /// Mark notification as read
  static Future<void> markNotificationRead(String id) async {
    final notifications = getNotifications();
    final index = notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      notifications[index]['isRead'] = true;
      await _cacheBox.put(_notificationsKey, notifications);
    }
  }

  /// Clear all notifications
  static Future<void> clearNotifications() async {
    await _cacheBox.delete(_notificationsKey);
  }

  // Saved News storage
  static const String _savedNewsKey = 'saved_news';

  /// Save a news article to local storage
  static Future<void> saveNews(Map<String, dynamic> news) async {
    final savedNews = getSavedNews();
    // Check if already saved
    if (savedNews.any((n) => n['id'] == news['id'])) return;
    savedNews.insert(0, news);
    await _cacheBox.put(_savedNewsKey, savedNews);
  }

  /// Remove a news article from saved
  static Future<void> unsaveNews(String newsId) async {
    final savedNews = getSavedNews();
    savedNews.removeWhere((n) => n['id'] == newsId);
    await _cacheBox.put(_savedNewsKey, savedNews);
  }

  /// Get all saved news articles
  static List<Map<String, dynamic>> getSavedNews() {
    final data = _cacheBox.get(_savedNewsKey);
    if (data != null && data is List) {
      return List<Map<String, dynamic>>.from(
        data.map((item) => Map<String, dynamic>.from(item as Map)),
      );
    }
    return [];
  }

  /// Check if a news article is saved
  static bool isNewsSaved(String newsId) {
    final savedNews = getSavedNews();
    return savedNews.any((n) => n['id'] == newsId);
  }
}
