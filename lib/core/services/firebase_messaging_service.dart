import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import '../storage/local_storage.dart';
import '../../features/navigation/controller/navigation_controller.dart';
import '../../features/alerts/controller/alerts_controller.dart';
import '../../features/spot_price/controller/spot_price_controller.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM Background Message: ${message.messageId}');
  
  // Store background notification for later display
  final notification = message.notification;
  if (notification != null) {
    final data = message.data;
    final notificationData = {
      'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': notification.title ?? 'Market Hub',
      'message': notification.body ?? '',
      'type': _getNotificationType(data['type']),
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
      'data': data,
    };
    
    // Note: We can't access LocalStorage directly in background handler
    // The notifications will be handled when app opens
  }
}

/// Helper to map FCM type to NotificationType
String _getNotificationType(String? type) {
  switch (type) {
    case 'news':
    case 'hindi_news':
      return 'newsUpdate';
    case 'circular':
    case 'home_update':
      return 'system';
    case 'price_alert':
      return 'priceAlert';
    case 'approval':
      return 'account';
    default:
      return 'system';
  }
}

/// FirebaseMessagingService handles push notifications
/// Integrates with Market Hub admin dashboard
class FirebaseMessagingService extends GetxService {
  static FirebaseMessagingService get to => Get.find();

  final _fcmToken = Rxn<String>();
  final _notificationsEnabled = true.obs;

  String? get fcmToken => _fcmToken.value;
  bool get notificationsEnabled => _notificationsEnabled.value;

  /// Initialize Firebase Messaging
  /// Call this after Firebase.initializeApp()
  Future<FirebaseMessagingService> init() async {
    try {
      // Request notification permissions
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _notificationsEnabled.value = true;
        debugPrint('FCM: Notifications authorized');

        // Get FCM token
        _fcmToken.value = await FirebaseMessaging.instance.getToken();
        debugPrint('FCM Token: ${_fcmToken.value}');

        // Listen for token refresh
        FirebaseMessaging.instance.onTokenRefresh.listen((token) {
          _fcmToken.value = token;
          debugPrint('FCM Token Refreshed: $token');
          // Token will be sent to server during login/profile update
        });

        // Configure foreground notification handling
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // Listen for foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle notification tap when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        // Check for initial message (app opened from notification)
        final initialMessage =
            await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }
      } else {
        debugPrint('FCM: Notifications not authorized');
        _notificationsEnabled.value = false;
      }
    } catch (e) {
      debugPrint('Firebase Messaging initialization error: $e');
    }

    return this;
  }

  /// Subscribe to a topic (e.g., plan-based notifications)
  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint('FCM: Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    debugPrint('FCM: Unsubscribed from topic: $topic');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Store notification for the Notifications tab
    final notification = message.notification;
    if (notification != null) {
      final data = message.data;
      final typeStr = _getNotificationType(data['type']);

      // Build navigationArgs for price alerts so Notifications tab tap works
      Map<String, dynamic>? navigationArgs;
      if (data['type'] == 'price_alert') {
        navigationArgs = {
          'tab': 2, // Spot tab
          'category': data['category'] ?? 'Non-Ferrous',
          'city': data['city'] ?? '',
        };
      }

      final notificationData = {
        'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': notification.title ?? 'Market Hub',
        'message': notification.body ?? '',
        'type': typeStr,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'data': data,
        if (navigationArgs != null) 'navigationArgs': navigationArgs,
      };
      
      // Store in local storage for persistence
      LocalStorage.addNotification(notificationData);
      debugPrint('FCM: Stored notification: ${notification.title}');
      
      // Show snackbar
      Get.snackbar(
        notification.title ?? 'Market Hub',
        notification.body ?? '',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        onTap: (_) => _handleNotificationTap(message),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navigate based on notification data
    final data = message.data;
    final type = data['type'];

    debugPrint('FCM: Handling notification tap - type: $type');

    switch (type) {
      case 'news':
        // Navigate to Alerts tab (index 3) -> News sub-tab (index 0)
        debugPrint('FCM: Opening news from notification');
        Get.offAllNamed('/main');
        // Small delay to ensure controllers are ready
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            final navController = Get.find<NavigationController>();
            navController.changePage(3); // Alerts Tab
            
            final alertsController = Get.find<AlertsController>();
            alertsController.changeTab(0); // News Sub-tab (was 1, now 0 after Live Feed removed)
          } catch (e) {
            debugPrint('FCM Navigation Error: $e');
          }
        });
        break;

      case 'hindi_news':
        // Navigate to Alerts tab (index 3) -> Hindi News sub-tab (index 1)
        debugPrint('FCM: Opening hindi news from notification');
        Get.offAllNamed('/main');
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            final navController = Get.find<NavigationController>();
            navController.changePage(3); // Alerts Tab
            
            final alertsController = Get.find<AlertsController>();
            alertsController.changeTab(1); // Hindi News Sub-tab (was 2, now 1 after Live Feed removed)
          } catch (e) {
            debugPrint('FCM Navigation Error: $e');
          }
        });
        break;

      case 'circular':
        // Navigate to Alerts tab (index 3) -> Circular sub-tab (index 2)
        debugPrint('FCM: Opening circulars from notification');
        Get.offAllNamed('/main');
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            final navController = Get.find<NavigationController>();
            navController.changePage(3); // Alerts Tab
            
            final alertsController = Get.find<AlertsController>();
            alertsController.changeTab(2); // Circular Sub-tab (was 3, now 2 after Live Feed removed)
          } catch (e) {
            debugPrint('FCM Navigation Error: $e');
          }
        });
        break;

      case 'home_update':
        // Navigate to Home tab (index 0)
        debugPrint('FCM: Opening home updates from notification');
        Get.offAllNamed('/main');
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            final navController = Get.find<NavigationController>();
            navController.changePage(0); // Home Tab
          } catch (e) {
            debugPrint('FCM Navigation Error: $e');
          }
        });
        break;

      case 'price_alert':
        // Navigate to Spot tab (index 2) with correct category/city
        debugPrint('FCM: Opening spot prices from price alert notification');
        Get.offAllNamed('/main');
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            final navController = Get.find<NavigationController>();
            navController.changePage(2); // Spot Tab (index 2)

            // Pre-select category and city if provided
            if (Get.isRegistered<SpotPriceController>()) {
              final spotController = Get.find<SpotPriceController>();
              final category = data['category'] ?? 'Non-Ferrous';
              final city = data['city'] ?? '';

              spotController.selectedCategory.value = category;
              if (city.isNotEmpty && category == 'Non-Ferrous') {
                spotController.selectedNonFerrousCity.value = city.toUpperCase();
              }
            }
          } catch (e) {
            debugPrint('FCM Navigation Error: $e');
          }
        });
        break;

      case 'approval':
        // Account approved notification - show message and go to login
        debugPrint('FCM: Account status update notification');
        Get.snackbar(
          'Account Approved!',
          'Your account has been approved. Please login to continue.',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 5),
          backgroundColor: const Color(0xFF4CAF50),
          colorText: const Color(0xFFFFFFFF),
        );
        Get.offAllNamed('/login');
        break;

      case 'forex_update':
        // Navigate to Spot tab (index 2) with Forex category
        debugPrint('FCM: Opening forex from notification');
        Get.offAllNamed('/main');
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            final navController = Get.find<NavigationController>();
            navController.changePage(2); // Spot Tab
            if (Get.isRegistered<SpotPriceController>()) {
              final spotController = Get.find<SpotPriceController>();
              spotController.selectedCategory.value = 'Forex';
            }
          } catch (e) {
            debugPrint('FCM Navigation Error: $e');
          }
        });
        break;

      case 'futures_update':
      case 'settlement_update':
        // Navigate to Futures tab (index 1)
        debugPrint('FCM: Opening futures from notification');
        Get.offAllNamed('/main');
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            final navController = Get.find<NavigationController>();
            navController.changePage(1); // Futures Tab
          } catch (e) {
            debugPrint('FCM Navigation Error: $e');
          }
        });
        break;

      default:
        // For any other notification type, navigate to notifications page
        debugPrint('FCM: Opening notifications page for type: $type');
        Get.toNamed('/notifications');
    }
  }

  /// Toggle notifications
  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled.value = enabled;

    if (!enabled) {
      // Delete token to stop receiving notifications
      await FirebaseMessaging.instance.deleteToken();
      _fcmToken.value = null;
      debugPrint('FCM: Token deleted, notifications disabled');
    } else {
      // Re-request token
      _fcmToken.value = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM: Notifications re-enabled, new token: ${_fcmToken.value}');
    }
  }
}
