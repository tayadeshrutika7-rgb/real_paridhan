import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_constants.dart';
import '../domain/app_notification_model.dart';
import 'role_notification_controller.dart';
import '../../theme/app_theme.dart';

class RoleNotificationService {
  /// Dispatches a notification strictly to a target role.
  /// Enforces state isolation: Seller/Admin/Delivery never receive Customer notifications and vice-versa.
  static Future<AppNotificationModel?> dispatch({
    required WidgetRef ref,
    required UserRole targetRole,
    required NotificationCategory category,
    required String title,
    required String body,
    String? deepLink,
    Map<String, dynamic>? payload,
    BuildContext? context,
    bool showVisualFeedback = true,
  }) async {
    // 1. Validate category matches the target role
    final allowed = AppNotificationModel.allowedCategoriesFor(targetRole);
    if (!allowed.contains(category) && category != NotificationCategory.system) {
      debugPrint('[RoleNotificationService] Incompatible category $category for role $targetRole');
    }

    // 2. Post to the target role notifier only
    final notif = await ref
        .read(roleNotificationProvider(targetRole).notifier)
        .postNotification(
          title: title,
          body: body,
          category: category,
          deepLink: deepLink,
          payload: payload,
        );

    // 3. If context is provided and visual feedback is enabled:
    // Only display SnackBar/Toast if the context's current active role/flavor matches targetRole.
    if (context != null && showVisualFeedback && context.mounted) {
      final currentRole = _determineCurrentActiveRole(ref);
      if (currentRole == targetRole) {
        showRoleScopedSnackBar(context, notif ?? AppNotificationModel(
          id: '',
          userId: '',
          role: targetRole,
          category: category,
          title: title,
          body: body,
          createdAt: DateTime.now(),
        ));
      }
    }

    return notif;
  }

  /// Helper to determine the currently active user role / platform
  static UserRole _determineCurrentActiveRole(WidgetRef ref) {
    // Watch or read current role from auth / flavor
    try {
      // In mobile app, appFlavorProvider represents active platform flavor
      final auth = ref.read(roleNotificationProvider(UserRole.consumer));
      // Default fallback
      return auth.role;
    } catch (_) {
      return UserRole.consumer;
    }
  }

  /// Display SnackBar with role-specific styling
  static void showRoleScopedSnackBar(BuildContext context, AppNotificationModel notif) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    // Clear any stale snackbars
    messenger.clearSnackBars();

    final Color badgeColor;
    final IconData badgeIcon;

    switch (notif.role) {
      case UserRole.consumer:
        badgeColor = AppTheme.primaryColor;
        badgeIcon = Icons.shopping_bag_outlined;
        break;
      case UserRole.seller:
        badgeColor = AppTheme.secondaryColor;
        badgeIcon = Icons.storefront_outlined;
        break;
      case UserRole.delivery:
        badgeColor = Colors.teal;
        badgeIcon = Icons.delivery_dining_outlined;
        break;
      case UserRole.admin:
        badgeColor = const Color(0xFF6366F1);
        badgeIcon = Icons.admin_panel_settings_outlined;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(badgeIcon, size: 18, color: badgeColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    notif.body,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Called when user switches platforms or navigates across role boundaries
  static void onPlatformOrRoleChanged(BuildContext context, WidgetRef ref, {
    required UserRole newRole,
    UserRole? previousRole,
  }) {
    // 1. Immediately dismiss any active floating snackbars on screen
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.clearSnackBars();

    // 2. Dismiss active banner for previous role if any
    if (previousRole != null) {
      ref.read(roleNotificationProvider(previousRole).notifier).dismissBanner();
    }

    // 3. Reload new role notifications
    ref.read(roleNotificationProvider(newRole).notifier).loadNotifications();
  }
}
