import '../../constants/app_constants.dart';

enum NotificationCategory {
  wishlist,
  cart,
  order,
  offer,
  inventory,
  kyc,
  campaign,
  assignment,
  trip,
  dispute,
  platform,
  message,
  system;

  static NotificationCategory fromString(String? value) {
    if (value == null) return NotificationCategory.system;
    return NotificationCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NotificationCategory.system,
    );
  }
}

class AppNotificationModel {
  final String id;
  final String userId;
  final UserRole role;
  final NotificationCategory category;
  final String title;
  final String body;
  final String type;
  final String? deepLink;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.role,
    required this.category,
    required this.title,
    required this.body,
    this.type = 'general',
    this.deepLink,
    this.isRead = false,
    required this.createdAt,
    this.payload = const {},
  });

  bool isTargetedTo(UserRole currentRole) {
    return role == currentRole;
  }

  static List<NotificationCategory> allowedCategoriesFor(UserRole role) {
    switch (role) {
      case UserRole.consumer:
        return [
          NotificationCategory.wishlist,
          NotificationCategory.cart,
          NotificationCategory.order,
          NotificationCategory.offer,
          NotificationCategory.message,
          NotificationCategory.system,
        ];
      case UserRole.seller:
        return [
          NotificationCategory.order,
          NotificationCategory.inventory,
          NotificationCategory.kyc,
          NotificationCategory.campaign,
          NotificationCategory.message,
          NotificationCategory.system,
        ];
      case UserRole.delivery:
        return [
          NotificationCategory.assignment,
          NotificationCategory.trip,
          NotificationCategory.message,
          NotificationCategory.system,
        ];
      case UserRole.admin:
        return [
          NotificationCategory.kyc,
          NotificationCategory.dispute,
          NotificationCategory.campaign,
          NotificationCategory.platform,
          NotificationCategory.system,
        ];
    }
  }

  bool isCompatibleWithRole(UserRole targetRole) {
    if (role != targetRole) return false;
    final allowed = allowedCategoriesFor(targetRole);
    return allowed.contains(category) || category == NotificationCategory.system;
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String? ?? 'consumer';
    final userRole = UserRole.values.firstWhere(
      (r) => r.name.toLowerCase() == roleStr.toLowerCase(),
      orElse: () => UserRole.consumer,
    );

    return AppNotificationModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      role: userRole,
      category: NotificationCategory.fromString(json['category'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      deepLink: json['deep_link'] as String?,
      isRead: json['read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'role': role.name,
      'category': category.name,
      'title': title,
      'body': body,
      'type': type,
      'deep_link': deepLink,
      'read': isRead,
      'created_at': createdAt.toIso8601String(),
      'payload': payload,
    };
  }

  AppNotificationModel copyWith({
    String? id,
    String? userId,
    UserRole? role,
    NotificationCategory? category,
    String? title,
    String? body,
    String? type,
    String? deepLink,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? payload,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      deepLink: deepLink ?? this.deepLink,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
    );
  }
}
