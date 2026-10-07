import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_constants.dart';
import '../../../features/auth/presentation/auth_state.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification_model.dart';

class RoleNotificationState {
  final UserRole role;
  final String? userId;
  final List<AppNotificationModel> notifications;
  final AppNotificationModel? activeBanner;
  final bool isLoading;
  final String? errorMessage;

  const RoleNotificationState({
    required this.role,
    this.userId,
    this.notifications = const [],
    this.activeBanner,
    this.isLoading = false,
    this.errorMessage,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  RoleNotificationState copyWith({
    UserRole? role,
    String? userId,
    List<AppNotificationModel>? notifications,
    AppNotificationModel? activeBanner,
    bool clearActiveBanner = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RoleNotificationState(
      role: role ?? this.role,
      userId: userId ?? this.userId,
      notifications: notifications ?? this.notifications,
      activeBanner: clearActiveBanner ? null : (activeBanner ?? this.activeBanner),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

abstract class RoleNotificationBaseNotifier extends Notifier<RoleNotificationState> {
  static int _idCounter = 0;
  final NotificationRepository _repository = NotificationRepository();
  UserRole get role;

  @override
  RoleNotificationState build() {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    if (user == null) {
      return RoleNotificationState(role: role, userId: null, notifications: []);
    }

    final userId = user.id;
    final cached = _repository.getCachedNotifications(userId: userId, role: role);

    // Asynchronously refresh notifications for this specific role and user
    Future.microtask(() => loadNotifications(userId: userId));

    return RoleNotificationState(
      role: role,
      userId: userId,
      isLoading: cached.isEmpty,
      notifications: cached,
    );
  }

  Future<void> loadNotifications({String? userId}) async {
    final effectiveUserId = userId ?? state.userId;

    if (effectiveUserId == null) {
      state = state.copyWith(isLoading: false, notifications: []);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repository.getNotifications(
        userId: effectiveUserId,
        role: role,
      );
      state = state.copyWith(
        isLoading: false,
        notifications: items,
        userId: effectiveUserId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notifications: $e',
      );
    }
  }

  Future<AppNotificationModel?> postNotification({
    required String title,
    required String body,
    required NotificationCategory category,
    String? deepLink,
    Map<String, dynamic>? payload,
    String? customId,
  }) async {
    final userId = state.userId ?? 'system_user';
    final notification = AppNotificationModel(
      id: customId ?? 'notif-${DateTime.now().microsecondsSinceEpoch}-${++_idCounter}',
      userId: userId,
      role: role,
      category: category,
      title: title,
      body: body,
      type: category.name,
      deepLink: deepLink,
      isRead: false,
      createdAt: DateTime.now(),
      payload: payload ?? {},
    );

    // Save to repository
    final saved = await _repository.insertNotification(notification);

    // Update state
    final currentList = state.notifications;
    state = state.copyWith(
      notifications: [saved, ...currentList.where((n) => n.id != saved.id)],
      activeBanner: saved,
    );

    return saved;
  }

  void dismissBanner() {
    state = state.copyWith(clearActiveBanner: true);
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = state.userId;
    if (userId == null) return;

    await _repository.markAsRead(
      userId: userId,
      role: role,
      notificationId: notificationId,
    );

    state = state.copyWith(
      notifications: state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList(),
    );
  }

  Future<void> markAllAsRead() async {
    final userId = state.userId;
    if (userId == null) return;

    await _repository.markAllAsRead(userId: userId, role: role);
    state = state.copyWith(
      notifications: state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }

  Future<void> clearAll() async {
    final userId = state.userId;
    if (userId != null) {
      await _repository.clearNotificationsForRole(userId: userId, role: role);
    }
    state = state.copyWith(notifications: [], clearActiveBanner: true);
  }
}

class ConsumerNotificationNotifier extends RoleNotificationBaseNotifier {
  @override
  UserRole get role => UserRole.consumer;
}

class SellerNotificationNotifier extends RoleNotificationBaseNotifier {
  @override
  UserRole get role => UserRole.seller;
}

class DeliveryNotificationNotifier extends RoleNotificationBaseNotifier {
  @override
  UserRole get role => UserRole.delivery;
}

class AdminNotificationNotifier extends RoleNotificationBaseNotifier {
  @override
  UserRole get role => UserRole.admin;
}

// Role-specific isolated state providers
final customerNotificationProvider =
    NotifierProvider<RoleNotificationBaseNotifier, RoleNotificationState>(() {
  return ConsumerNotificationNotifier();
});

final sellerNotificationProvider =
    NotifierProvider<RoleNotificationBaseNotifier, RoleNotificationState>(() {
  return SellerNotificationNotifier();
});

final deliveryNotificationProvider =
    NotifierProvider<RoleNotificationBaseNotifier, RoleNotificationState>(() {
  return DeliveryNotificationNotifier();
});

final adminNotificationProvider =
    NotifierProvider<RoleNotificationBaseNotifier, RoleNotificationState>(() {
  return AdminNotificationNotifier();
});

/// Resolves provider based on UserRole
NotifierProvider<RoleNotificationBaseNotifier, RoleNotificationState> roleNotificationProvider(UserRole role) {
  switch (role) {
    case UserRole.consumer:
      return customerNotificationProvider;
    case UserRole.seller:
      return sellerNotificationProvider;
    case UserRole.delivery:
      return deliveryNotificationProvider;
    case UserRole.admin:
      return adminNotificationProvider;
  }
}
