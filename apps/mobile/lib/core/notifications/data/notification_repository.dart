import 'package:flutter/foundation.dart';
import '../../constants/app_constants.dart';
import '../../network/supabase_client.dart';
import '../domain/app_notification_model.dart';

class NotificationRepository {
  // In-memory partitioned storage: Key is "$userId:${role.name}"
  // This guarantees strict isolation per user and per role in offline / testing mode.
  static final Map<String, List<AppNotificationModel>> _isolatedStorage = {};

  static String _storageKey(String userId, UserRole role) => '$userId:${role.name}';

  static void resetInMemoryStorage() {
    _isolatedStorage.clear();
  }

  List<AppNotificationModel> getCachedNotifications({
    required String userId,
    required UserRole role,
  }) {
    final key = _storageKey(userId, role);
    final items = _isolatedStorage[key] ?? [];
    return items.where((n) => n.role == role && n.isCompatibleWithRole(role)).toList();
  }

  Future<List<AppNotificationModel>> getNotifications({
    required String userId,
    required UserRole role,
  }) async {
    final client = SupabaseService.client;
    final key = _storageKey(userId, role);

    if (client == null) {
      final items = _isolatedStorage[key] ?? [];
      // Guarantee only notifications strictly targeted to this role are returned
      return items.where((n) => n.role == role && n.isCompatibleWithRole(role)).toList();
    }

    try {
      final response = await client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('role', role.name)
          .order('created_at', ascending: false);

      final remoteList = (response as List)
          .map((json) => AppNotificationModel.fromJson(json as Map<String, dynamic>))
          .where((n) => n.role == role && n.isCompatibleWithRole(role))
          .toList();

      // Merge with memory
      _isolatedStorage[key] = remoteList;
      return remoteList;
    } catch (e) {
      debugPrint('[NotificationRepository] Error loading notifications for $role: $e');
      final items = _isolatedStorage[key] ?? [];
      return items.where((n) => n.role == role && n.isCompatibleWithRole(role)).toList();
    }
  }

  Future<AppNotificationModel> insertNotification(AppNotificationModel notification) async {
    // Validate role compatibility before storing
    if (!notification.isCompatibleWithRole(notification.role)) {
      debugPrint('[NotificationRepository] Warning: Notification category ${notification.category} is incompatible with role ${notification.role}');
    }

    final key = _storageKey(notification.userId, notification.role);
    final currentList = _isolatedStorage[key] ?? [];
    _isolatedStorage[key] = [notification, ...currentList];

    final client = SupabaseService.client;
    if (client != null) {
      try {
        final payload = {
          'user_id': notification.userId,
          'role': notification.role.name,
          'category': notification.category.name,
          'title': notification.title,
          'body': notification.body,
          'type': notification.type,
          'deep_link': notification.deepLink,
          'read': notification.isRead,
          'payload': notification.payload,
        };
        final res = await client.from('notifications').insert(payload).select().single();
        return AppNotificationModel.fromJson(res);
      } catch (e) {
        debugPrint('[NotificationRepository] Error inserting notification to Supabase: $e');
      }
    }

    return notification;
  }

  Future<void> markAsRead({
    required String userId,
    required UserRole role,
    required String notificationId,
  }) async {
    final key = _storageKey(userId, role);
    final currentList = _isolatedStorage[key] ?? [];
    _isolatedStorage[key] = currentList.map((item) {
      if (item.id == notificationId) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();

    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client
            .from('notifications')
            .update({'read': true})
            .eq('id', notificationId)
            .eq('user_id', userId)
            .eq('role', role.name);
      } catch (e) {
        debugPrint('[NotificationRepository] Error marking notification as read: $e');
      }
    }
  }

  Future<void> markAllAsRead({
    required String userId,
    required UserRole role,
  }) async {
    final key = _storageKey(userId, role);
    final currentList = _isolatedStorage[key] ?? [];
    _isolatedStorage[key] = currentList.map((item) => item.copyWith(isRead: true)).toList();

    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client
            .from('notifications')
            .update({'read': true})
            .eq('user_id', userId)
            .eq('role', role.name);
      } catch (e) {
        debugPrint('[NotificationRepository] Error marking all as read: $e');
      }
    }
  }

  Future<void> clearNotificationsForRole({
    required String userId,
    required UserRole role,
  }) async {
    final key = _storageKey(userId, role);
    _isolatedStorage.remove(key);

    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client
            .from('notifications')
            .delete()
            .eq('user_id', userId)
            .eq('role', role.name);
      } catch (e) {
        debugPrint('[NotificationRepository] Error clearing notifications for $role: $e');
      }
    }
  }
}
