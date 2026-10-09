import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_constants.dart';
import '../../network/supabase_client.dart';
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
    String? targetUserId,
  }) async {
    final effectiveUserId = targetUserId ?? state.userId ?? 'system_user';
    final notification = AppNotificationModel(
      id: customId ?? 'notif-${DateTime.now().microsecondsSinceEpoch}-${++_idCounter}',
      userId: effectiveUserId,
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

    // Save to repository (in-memory partition and Supabase)
    final saved = await _repository.insertNotification(notification);

    // Update state so the notification and active banner immediately appear for the active user
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
  RealtimeChannel? _bargainsChannel;

  @override
  Future<void> loadNotifications({String? userId}) async {
    await super.loadNotifications(userId: userId);
    final effectiveUserId = userId ?? state.userId;
    if (effectiveUserId == null || effectiveUserId.isEmpty || effectiveUserId.startsWith('guest')) {
      return;
    }

    _subscribeToConsumerBargains(effectiveUserId);
    await _syncBargainNotifications(effectiveUserId);
  }

  void _subscribeToConsumerBargains(String consumerId) {
    final client = SupabaseService.client;
    if (client == null) return;

    _bargainsChannel?.unsubscribe();
    _bargainsChannel = client
        .channel('consumer_bargain_stream:$consumerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bargains',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'consumer_id',
            value: consumerId,
          ),
          callback: (payload) {
            final rec = payload.newRecord;
            if (rec.isEmpty) return;
            final status = rec['status'] as String?;
            final agreedPrice = rec['agreed_price'] != null
                ? (rec['agreed_price'] as num).toDouble()
                : (rec['consumer_offer'] as num?)?.toDouble() ?? 0.0;
            final bargainId = rec['id'] as String;

            if (status == 'accepted') {
              postNotification(
                title: '🎉 Seller Accepted Your Bargain (₹${agreedPrice.toStringAsFixed(0)})!',
                body: 'Great news! The shopkeeper agreed to your lower price. You can now add this cloth to your shopping bag with the new bargained price of ₹${agreedPrice.toStringAsFixed(0)}!',
                category: NotificationCategory.offer,
                deepLink: '/cart',
                customId: 'bargain-accept-$bargainId',
                targetUserId: consumerId,
              );
            } else if (status == 'countered') {
              final counter = (rec['counter_offer'] as num?)?.toDouble() ?? 0.0;
              postNotification(
                title: '💬 New Counter-Offer: ₹${counter.toStringAsFixed(0)}',
                body: 'The boutique replied with a counter-offer of ₹${counter.toStringAsFixed(0)}. Tap to review and accept!',
                category: NotificationCategory.offer,
                deepLink: '/bargain/$bargainId',
                customId: 'bargain-counter-$bargainId',
                targetUserId: consumerId,
              );
            } else if (status == 'rejected') {
              postNotification(
                title: '❌ Bargain Offer Declined',
                body: 'The boutique declined the bargain offer. You can view the chat to submit a new offer or purchase at listed price.',
                category: NotificationCategory.offer,
                deepLink: '/bargain/$bargainId',
                customId: 'bargain-reject-$bargainId',
                targetUserId: consumerId,
              );
            }
          },
        )
        .subscribe();
  }

  Future<void> _syncBargainNotifications(String consumerId) async {
    final client = SupabaseService.client;
    if (client == null) return;

    try {
      final res = await client
          .from('bargains')
          .select('*, products(title)')
          .eq('consumer_id', consumerId)
          .inFilter('status', ['accepted', 'countered', 'rejected'])
          .order('updated_at', ascending: false)
          .limit(10);

      for (final row in (res as List)) {
        final m = row as Map<String, dynamic>;
        final status = m['status'] as String?;
        final bId = m['id'] as String;
        final prod = m['products'] as Map<String, dynamic>? ?? {};
        final title = (prod['title'] as String?) ?? 'Handcrafted Garment';
        final agreed = m['agreed_price'] != null
            ? (m['agreed_price'] as num).toDouble()
            : (m['consumer_offer'] as num?)?.toDouble() ?? 0.0;
        final counter = m['counter_offer'] != null
            ? (m['counter_offer'] as num).toDouble()
            : 0.0;

        if (status == 'accepted') {
          final notifId = 'bargain-accept-$bId';
          if (!state.notifications.any((n) => n.id == notifId)) {
            await postNotification(
              customId: notifId,
              title: '🎉 Seller Accepted Your Bargain (₹${agreed.toStringAsFixed(0)})!',
              body: 'Great news! The shopkeeper agreed to your lower price for "$title". You can now add this cloth to your shopping bag with the new bargained price of ₹${agreed.toStringAsFixed(0)}!',
              category: NotificationCategory.offer,
              deepLink: '/cart',
              targetUserId: consumerId,
            );
          }
        } else if (status == 'countered') {
          final notifId = 'bargain-counter-$bId';
          if (!state.notifications.any((n) => n.id == notifId)) {
            await postNotification(
              customId: notifId,
              title: '💬 New Counter-Offer: ₹${counter.toStringAsFixed(0)}',
              body: 'The boutique replied with a counter-offer of ₹${counter.toStringAsFixed(0)} for "$title". Tap to review and accept!',
              category: NotificationCategory.offer,
              deepLink: '/bargain/$bId',
              targetUserId: consumerId,
            );
          }
        } else if (status == 'rejected') {
          final notifId = 'bargain-reject-$bId';
          if (!state.notifications.any((n) => n.id == notifId)) {
            await postNotification(
              customId: notifId,
              title: '❌ Bargain Offer Declined',
              body: 'The boutique declined the bargain offer for "$title". You can view the chat to submit a new offer.',
              category: NotificationCategory.offer,
              deepLink: '/bargain/$bId',
              targetUserId: consumerId,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[ConsumerNotificationNotifier] sync error: $e');
    }
  }
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
