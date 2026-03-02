import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../data/models/notification/notification_model.dart';
import '../../../core/services/admin_api_service.dart';
import '../../../core/storage/local_storage.dart';

class NotificationsController extends GetxController {
  final RxList<NotificationModel> _notifications = <NotificationModel>[].obs;
  final RxList<NotificationType> _selectedFilters = <NotificationType>[].obs;
  final RxBool _isLoading = false.obs;

  List<NotificationModel> get notifications => _notifications;
  List<NotificationType> get selectedFilters => _selectedFilters;
  bool get isLoading => _isLoading.value;

  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  @override
  void onInit() {
    super.onInit();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    _isLoading.value = true;

    try {
      // Load persisted read and deleted IDs
      final readIds = LocalStorage.getReadNotificationIds();
      final deletedIds = LocalStorage.getDeletedNotificationIds();
      final Set<String> seenIds = {};
      final List<NotificationModel> allNotifications = [];
      
      // 1. Load push notifications from local storage first (most recent)
      final storedNotifications = LocalStorage.getNotifications();
      for (final json in storedNotifications) {
        final id = json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
        
        // Skip if deleted
        if (deletedIds.contains(id)) continue;

        final notification = NotificationModel(
          id: id,
          title: json['title'] ?? '',
          message: json['message'] ?? '',
          type: _getTypeFromString(json['type']),
          timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
          isRead: json['isRead'] ?? readIds.contains(id),
        );
        if (!seenIds.contains(notification.id)) {
          seenIds.add(notification.id);
          allNotifications.add(notification);
        }
      }
      debugPrint('Loaded ${storedNotifications.length} notifications from local storage');

      // 2. Fetch latest updates from Admin API
      final adminApi = Get.find<AdminApiService>();
      final updates = await adminApi.getLatestUpdates(limit: 50);

      if (updates.isNotEmpty) {
        for (final json in updates) {
          // Determine notification type based on contentType
          NotificationType type;
          switch (json['contentType']) {
            case 'news':
            case 'hindi_news':
              type = NotificationType.newsUpdate;
              break;
            case 'circular':
              type = NotificationType.system;
              break;
            case 'home_update':
              type = NotificationType.system;
              break;
            default:
              type = NotificationType.system;
          }

          final id = json['id']?.toString() ?? '';
          
          // Skip if deleted
          if (deletedIds.contains(id)) continue;

          if (!seenIds.contains(id)) {
            seenIds.add(id);
            allNotifications.add(NotificationModel(
              id: id,
              title: json['title'] ?? '',
              message: json['description'] ?? '',
              type: type,
              timestamp: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
              isRead: readIds.contains(id),
            ));
          }
        }
        debugPrint('Loaded ${updates.length} notifications from admin API');
      }
      
      // Sort by timestamp descending (newest first)
      allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      _notifications.assignAll(allNotifications);
      debugPrint('Total notifications: ${allNotifications.length}');
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }

    _isLoading.value = false;
  }
  
  NotificationType _getTypeFromString(String? typeStr) {
    switch (typeStr) {
      case 'priceAlert':
        return NotificationType.priceAlert;
      case 'newsUpdate':
        return NotificationType.newsUpdate;
      case 'account':
        return NotificationType.account;
      default:
        return NotificationType.system;
    }
  }

  Map<String, List<NotificationModel>> get groupedNotifications {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeek = today.subtract(const Duration(days: 7));

    final filtered = _selectedFilters.isEmpty
        ? _notifications
        : _notifications
            .where((n) => _selectedFilters.contains(n.type))
            .toList();

    final Map<String, List<NotificationModel>> grouped = {
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'Earlier': [],
    };

    for (var notification in filtered) {
      final notificationDate = DateTime(
        notification.timestamp.year,
        notification.timestamp.month,
        notification.timestamp.day,
      );

      if (notificationDate == today) {
        grouped['Today']!.add(notification);
      } else if (notificationDate == yesterday) {
        grouped['Yesterday']!.add(notification);
      } else if (notificationDate.isAfter(thisWeek)) {
        grouped['This Week']!.add(notification);
      } else {
        grouped['Earlier']!.add(notification);
      }
    }

    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);

    return grouped;
  }

  void toggleFilter(NotificationType type) {
    if (_selectedFilters.contains(type)) {
      _selectedFilters.remove(type);
    } else {
      _selectedFilters.add(type);
    }
  }

  void clearFilters() {
    _selectedFilters.clear();
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notifications.refresh();
      
      // Persist read status
      LocalStorage.addReadNotificationId(notificationId);
      LocalStorage.markNotificationRead(notificationId); // Update stored push notification if any
    }
  }

  void markAllAsRead() {
    for (var notification in _notifications) {
      if (!notification.isRead) {
        LocalStorage.addReadNotificationId(notification.id);
        LocalStorage.markNotificationRead(notification.id);
      }
    }
    _notifications.value = _notifications
        .map((notification) => notification.copyWith(isRead: true))
        .toList();
  }

  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    LocalStorage.addDeletedNotificationId(notificationId);
    LocalStorage.removeNotification(notificationId);
  }

  void clearAll() {
    Get.defaultDialog(
      title: 'Clear All Notifications',
      middleText: 'Are you sure you want to clear all notifications?',
      textConfirm: 'Clear',
      textCancel: 'Cancel',
      confirmTextColor: Get.theme.colorScheme.onPrimary,
      onConfirm: () {
        // Persist deleted status for all current notifications
        for (var notification in _notifications) {
          LocalStorage.addDeletedNotificationId(notification.id);
        }
        
        _notifications.clear();
        LocalStorage.clearNotifications();
        
        Get.back();
        Get.snackbar(
          'Success',
          'All notifications cleared',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }

  void onNotificationTap(NotificationModel notification) {
    // Mark as read
    markAsRead(notification.id);

    // Navigate if route is provided
    if (notification.navigationRoute != null) {
      Get.toNamed(
        notification.navigationRoute!,
        arguments: notification.navigationArgs,
      );
    }
  }

  void refreshNotifications() {
    _loadNotifications();
  }
}
