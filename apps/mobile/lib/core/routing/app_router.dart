import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/legal/presentation/legal_screen.dart';
import '../../features/consumer/presentation/consumer_home_screen.dart';
import '../../features/consumer/presentation/consumer_profile_screen.dart';
import '../../features/consumer/presentation/search_screen.dart';
import '../../features/consumer/presentation/shop_profile_screen.dart';
import '../../features/consumer/presentation/product_detail_screen.dart';
import '../../features/consumer/presentation/wishlist_screen.dart';
import '../../features/consumer/presentation/cart_screen.dart';
import '../../features/consumer/presentation/checkout_screen.dart';
import '../../features/consumer/presentation/order_history_screen.dart';
import '../../features/consumer/presentation/order_tracking_screen.dart';
import '../../features/consumer/presentation/bargain_chat_screen.dart';
import '../../features/consumer/presentation/bargain_inbox_screen.dart';
import '../../features/seller/presentation/seller_home_screen.dart';
import '../../features/seller/presentation/shop_registration_screen.dart';
import '../../features/seller/presentation/add_product_screen.dart';
import '../../features/seller/presentation/inventory_screen.dart';
import '../../features/seller/presentation/seller_orders_screen.dart';
import '../../features/seller/presentation/seller_ad_request_screen.dart';
import '../../features/delivery/presentation/delivery_home_screen.dart';
import '../../features/delivery/presentation/active_trip_screen.dart';
import '../../features/delivery/presentation/delivery_earnings_screen.dart';
import '../../features/delivery/presentation/delivery_profile_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_boutique_verification_screen.dart';
import '../../features/admin/presentation/admin_analytics_screen.dart';
import '../../features/admin/presentation/admin_disputes_screen.dart';
import '../../features/admin/presentation/admin_advertisements_screen.dart';

class FlavorNotifier extends Notifier<AppFlavor> {
  final AppFlavor _initial;
  FlavorNotifier([this._initial = AppFlavor.consumer]);

  @override
  AppFlavor build() => _initial;

  void setFlavor(AppFlavor flavor) => state = flavor;
}

final appFlavorProvider = NotifierProvider<FlavorNotifier, AppFlavor>(() {
  return FlavorNotifier();
});

class RoleIsolationRouteObserver extends NavigatorObserver {
  final Ref ref;
  RoleIsolationRouteObserver(this.ref);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _clearStaleNotificationOverlays();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _clearStaleNotificationOverlays();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _clearStaleNotificationOverlays();
  }

  void _clearStaleNotificationOverlays() {
    // Dismiss active transient snackbars across route transitions to guarantee clean role isolation
    try {
      final context = navigator?.context;
      if (context != null && context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
      }
    } catch (_) {}
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final currentFlavor = ref.watch(appFlavorProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    observers: [RoleIsolationRouteObserver(ref)],
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          if (authState.isGuest) {
            return const ConsumerHomeScreen();
          }

          final user = authState.user;
          final effectiveRole = user?.role ?? UserRole.consumer;
          if (effectiveRole == UserRole.admin) {
            return const AdminDashboardScreen();
          } else if (effectiveRole == UserRole.seller || currentFlavor == AppFlavor.seller) {
            return const SellerHomeScreen();
          } else if (effectiveRole == UserRole.delivery || currentFlavor == AppFlavor.delivery) {
            return const DeliveryHomeScreen();
          } else {
            return const ConsumerHomeScreen();
          }
        },
      ),
      GoRoute(
        path: '/consumer',
        builder: (context, state) => const ConsumerHomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/legal/terms',
        builder: (context, state) => const LegalScreen(type: LegalType.terms),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (context, state) => const LegalScreen(type: LegalType.privacy),
      ),
      GoRoute(
        path: '/legal/fees',
        builder: (context, state) => const LegalScreen(type: LegalType.feeDisclosure),
      ),
      GoRoute(
        path: '/legal/fee-disclosure',
        builder: (context, state) => const LegalScreen(type: LegalType.feeDisclosure),
      ),
      // Consumer Routes
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ConsumerProfileScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/shop/:id',
        builder: (context, state) => ShopProfileScreen(
          shopId: state.pathParameters['id'] ?? 'shop-jaipur-01',
        ),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id'] ?? 'prod-001',
        ),
      ),
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) => OrderTrackingScreen(
          orderId: state.pathParameters['id'] ?? '',
        ),
      ),
      // Seller Studio Routes
      GoRoute(
        path: '/seller',
        builder: (context, state) => const SellerHomeScreen(),
      ),
      GoRoute(
        path: '/seller/shop',
        builder: (context, state) => const ShopRegistrationScreen(),
      ),
      GoRoute(
        path: '/seller/add-product',
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: '/seller/inventory',
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: '/seller/orders',
        builder: (context, state) => const SellerOrdersScreen(),
      ),
      GoRoute(
        path: '/seller/advertisements',
        builder: (context, state) => const SellerAdRequestScreen(),
      ),
      // Bargaining Routes
      GoRoute(
        path: '/bargains',
        builder: (context, state) {
          final isSellerView =
              state.uri.queryParameters['seller'] == 'true';
          return BargainInboxScreen(isSellerView: isSellerView);
        },
      ),
      GoRoute(
        path: '/bargain/:id',
        builder: (context, state) {
          final bargainId = state.pathParameters['id'] ?? '';
          final isSellerView =
              state.uri.queryParameters['seller'] == 'true';
          return BargainChatScreen(
            bargainId: bargainId,
            isSellerView: isSellerView,
          );
        },
      ),
      // Delivery Fleet Routes
      GoRoute(
        path: '/delivery',
        builder: (context, state) => const DeliveryHomeScreen(),
      ),
      GoRoute(
        path: '/delivery/trip/:id',
        builder: (context, state) => ActiveTripScreen(
          orderId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/delivery/earnings',
        builder: (context, state) => const DeliveryEarningsScreen(),
      ),
      GoRoute(
        path: '/delivery/profile',
        builder: (context, state) => const DeliveryProfileScreen(),
      ),
      // Super Admin Operations Routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/boutiques',
        builder: (context, state) => const AdminBoutiqueVerificationScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
      GoRoute(
        path: '/admin/disputes',
        builder: (context, state) => const AdminDisputesScreen(),
      ),
      GoRoute(
        path: '/admin/advertisements',
        builder: (context, state) => const AdminAdvertisementsScreen(),
      ),
    ],
  );
});
