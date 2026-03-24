enum NotificationType {
  priceAlert,
  newsUpdate,
  system,
  account,
  subscription,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? navigationRoute;
  final Map<String, dynamic>? navigationArgs;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.navigationRoute,
    this.navigationArgs,
  });

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? navigationRoute,
    Map<String, dynamic>? navigationArgs,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      navigationRoute: navigationRoute ?? this.navigationRoute,
      navigationArgs: navigationArgs ?? this.navigationArgs,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      navigationRoute: json['navigationRoute'] as String?,
      navigationArgs: json['navigationArgs'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'navigationRoute': navigationRoute,
      'navigationArgs': navigationArgs,
    };
  }
}
