import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_theme.dart';
import '../domain/app_notification_model.dart';
import 'role_notification_controller.dart';

class RoleNotificationsSheet extends ConsumerWidget {
  final UserRole role;

  const RoleNotificationsSheet({super.key, required this.role});

  static void show(BuildContext context, UserRole role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RoleNotificationsSheet(role: role),
    );
  }

  String _roleTitle() {
    switch (role) {
      case UserRole.consumer:
        return 'Customer Notifications';
      case UserRole.seller:
        return 'Seller Studio Notifications';
      case UserRole.delivery:
        return 'Delivery Fleet Alerts';
      case UserRole.admin:
        return 'Admin Operations Alerts';
    }
  }

  IconData _categoryIcon(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.wishlist:
        return Icons.favorite_border;
      case NotificationCategory.cart:
        return Icons.shopping_cart_outlined;
      case NotificationCategory.order:
        return Icons.local_mall_outlined;
      case NotificationCategory.offer:
        return Icons.local_offer_outlined;
      case NotificationCategory.inventory:
        return Icons.inventory_2_outlined;
      case NotificationCategory.kyc:
        return Icons.verified_user_outlined;
      case NotificationCategory.campaign:
        return Icons.campaign_outlined;
      case NotificationCategory.assignment:
      case NotificationCategory.trip:
        return Icons.directions_bike_outlined;
      case NotificationCategory.dispute:
        return Icons.gavel_outlined;
      case NotificationCategory.platform:
        return Icons.security_outlined;
      case NotificationCategory.message:
        return Icons.chat_bubble_outline;
      case NotificationCategory.system:
        return Icons.notifications_none_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roleNotificationProvider(role));
    final notifier = ref.read(roleNotificationProvider(role).notifier);

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            // Drag handle
            Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _roleTitle(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${state.notifications.length} notifications (${state.unreadCount} unread)',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (state.notifications.isNotEmpty) ...[
                  TextButton.icon(
                    onPressed: () => notifier.markAllAsRead(),
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Read All', style: TextStyle(fontSize: 12)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                    onPressed: () => notifier.clearAll(),
                    tooltip: 'Clear notifications',
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List or Empty
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No ${role.name.toUpperCase()} notifications',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'You will receive isolated notifications here.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.notifications.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, indent: 64),
                        itemBuilder: (ctx, index) {
                          final notif = state.notifications[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: notif.isRead
                                  ? Colors.grey.shade100
                                  : AppTheme.primaryColor.withValues(alpha: 0.12),
                              child: Icon(
                                _categoryIcon(notif.category),
                                size: 20,
                                color: notif.isRead ? Colors.grey : AppTheme.primaryColor,
                              ),
                            ),
                            title: Text(
                              notif.title,
                              style: TextStyle(
                                fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 14,
                                color: notif.isRead ? AppTheme.textSecondary : AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  notif.body,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: notif.isRead ? AppTheme.textMuted : AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _timeAgo(notif.createdAt),
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                            trailing: !notif.isRead
                                ? Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                            onTap: () {
                              notifier.markAsRead(notif.id);
                              if (notif.deepLink != null && notif.deepLink!.isNotEmpty) {
                                Navigator.pop(ctx);
                                context.push(notif.deepLink!);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    ),
  );
}

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
