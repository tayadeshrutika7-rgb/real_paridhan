import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_theme.dart';
import '../../../features/auth/presentation/auth_state.dart';
import '../domain/app_notification_model.dart';
import 'role_notification_controller.dart';

/// Global overlay banner that displays real-time in-app alerts (e.g. bargain acceptance/rejection)
/// at the top of the app with rich action buttons.
class InAppNotificationBannerOverlay extends ConsumerStatefulWidget {
  const InAppNotificationBannerOverlay({super.key});

  @override
  ConsumerState<InAppNotificationBannerOverlay> createState() =>
      _InAppNotificationBannerOverlayState();
}

class _InAppNotificationBannerOverlayState
    extends ConsumerState<InAppNotificationBannerOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _dismissTimer;
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  String? _lastDisplayedBannerId;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _scheduleAutoDismiss(UserRole role) {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) {
        _animController.reverse().then((_) {
          if (mounted) {
            ref.read(roleNotificationProvider(role).notifier).dismissBanner();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userRole = authState.user?.role ?? UserRole.consumer;
    final notifState = ref.watch(roleNotificationProvider(userRole));
    final banner = notifState.activeBanner;

    if (banner != null) {
      if (_lastDisplayedBannerId != banner.id) {
        _lastDisplayedBannerId = banner.id;
        _animController.forward(from: 0);
        _scheduleAutoDismiss(userRole);
      }
    } else {
      if (_animController.isCompleted || _animController.isAnimating) {
        _animController.reverse();
      }
      _lastDisplayedBannerId = null;
    }

    if (banner == null && _animController.isDismissed) {
      return const SizedBox.shrink();
    }

    final isAccept = banner?.title.contains('Accepted') == true ||
        banner?.body.contains('accepted') == true;
    final isReject = banner?.title.contains('Declined') == true ||
        banner?.title.contains('Rejected') == true ||
        banner?.body.contains('declined') == true;

    final primaryColor = isAccept
        ? Colors.green.shade700
        : isReject
            ? Colors.red.shade700
            : AppTheme.primaryColor;

    final bgColor = isAccept
        ? const Color(0xFFF0FDF4)
        : isReject
            ? const Color(0xFFFEF2F2)
            : Colors.white;

    final borderColor = isAccept
        ? Colors.green.shade300
        : isReject
            ? Colors.red.shade300
            : Colors.grey.shade300;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnim,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (banner != null) {
                    ref
                        .read(roleNotificationProvider(userRole).notifier)
                        .markAsRead(banner.id);
                    ref
                        .read(roleNotificationProvider(userRole).notifier)
                        .dismissBanner();
                    if (banner.deepLink != null &&
                        banner.deepLink!.isNotEmpty) {
                      context.push(banner.deepLink!);
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAccept
                              ? Icons.check_circle
                              : isReject
                                  ? Icons.cancel
                                  : Icons.notifications_active,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              banner?.title ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              banner?.body ?? '',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textPrimary,
                                height: 1.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (banner?.deepLink != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    banner!.deepLink!.contains('/cart')
                                        ? 'View in Shopping Bag ➔'
                                        : 'View Deal Details ➔',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        onPressed: () {
                          _animController.reverse().then((_) {
                            if (mounted) {
                              ref
                                  .read(roleNotificationProvider(userRole).notifier)
                                  .dismissBanner();
                            }
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
