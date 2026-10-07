import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_constants.dart';
import 'role_notification_controller.dart';
import 'role_notifications_sheet.dart';

class RoleNotificationBadge extends ConsumerWidget {
  final UserRole role;
  final Color? iconColor;
  final double size;

  const RoleNotificationBadge({
    super.key,
    required this.role,
    this.iconColor,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roleNotificationProvider(role));
    final unread = state.unreadCount;

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, size: size, color: iconColor),
          if (unread > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unread > 99 ? '99+' : unread.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () => RoleNotificationsSheet.show(context, role),
      tooltip: '${role.name.toUpperCase()} Notifications ($unread)',
    );
  }
}
