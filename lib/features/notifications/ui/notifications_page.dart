import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../../../data/models/notification/notification_model.dart';
import '../controller/notifications_controller.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/common/common_app_bar_title.dart';

class NotificationsPage extends GetView<NotificationsController> {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        title: const CommonAppBarTitle(title: 'Notifications'),
        backgroundColor: ColorConstants.surfaceColor,
        elevation: 0,
        actions: [
          Obx(() => controller.notifications.isNotEmpty
              ? PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'mark_all_read') {
                      controller.markAllAsRead();
                    } else if (value == 'clear_all') {
                      controller.clearAll();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'mark_all_read',
                      child: Row(
                        children: [
                          Icon(Icons.done_all, size: 20),
                          SizedBox(width: 8),
                          Text('Mark all as read'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, size: 20),
                          SizedBox(width: 8),
                          Text('Clear all'),
                        ],
                      ),
                    ),
                  ],
                )
              : const SizedBox()),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.notifications.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  controller.refreshNotifications();
                },
                child: _buildNotificationsList(),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: ColorConstants.surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Obx(() {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                'Price Alerts',
                NotificationType.priceAlert,
                Icons.show_chart,
                ColorConstants.primaryOrange,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'News',
                NotificationType.newsUpdate,
                Icons.article,
                ColorConstants.primaryBlue,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'System',
                NotificationType.system,
                Icons.info,
                ColorConstants.infoColor,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Account',
                NotificationType.account,
                Icons.person,
                ColorConstants.successColor,
              ),
              if (controller.selectedFilters.isNotEmpty) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: controller.clearFilters,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: ColorConstants.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFilterChip(
    String label,
    NotificationType type,
    IconData icon,
    Color color,
  ) {
    final isSelected = controller.selectedFilters.contains(type);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => controller.toggleFilter(type),
      selectedColor: color,
      checkmarkColor: Colors.white,
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : color,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }

  Widget _buildNotificationsList() {
    final grouped = controller.groupedNotifications;

    if (grouped.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final section = grouped.keys.elementAt(index);
        final notifications = grouped[section]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                section,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.textSecondary,
                ),
              ),
            ),
            ...notifications.map((notification) =>
                _buildNotificationItem(notification)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final iconData = _getNotificationIcon(notification.type);
    final iconColor = _getNotificationColor(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: ColorConstants.errorColor,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        controller.deleteNotification(notification.id);
        Get.snackbar(
          'Deleted',
          'Notification removed',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: notification.isRead
              ? ColorConstants.surfaceColor
              : ColorConstants.primaryLight.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? ColorConstants.borderColor
                : ColorConstants.primaryOrange.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.onNotificationTap(notification),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(iconData, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w600,
                                  color: ColorConstants.textPrimary,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: ColorConstants.primaryOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: const TextStyle(
                            fontSize: 13,
                            color: ColorConstants.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: ColorConstants.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: ColorConstants.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              color: ColorConstants.textHint,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.priceAlert:
        return Icons.show_chart;
      case NotificationType.newsUpdate:
        return Icons.article;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.account:
        return Icons.person;
      case NotificationType.subscription:
        return Icons.card_membership;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.priceAlert:
        return ColorConstants.primaryOrange;
      case NotificationType.newsUpdate:
        return ColorConstants.primaryBlue;
      case NotificationType.system:
        return ColorConstants.infoColor;
      case NotificationType.account:
        return ColorConstants.successColor;
      case NotificationType.subscription:
        return ColorConstants.successColor;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }
}
