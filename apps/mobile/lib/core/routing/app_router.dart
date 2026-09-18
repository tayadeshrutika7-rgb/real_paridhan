import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/legal/presentation/legal_screen.dart';
import '../../features/consumer/presentation/consumer_home_screen.dart';
import '../../features/consumer/presentation/search_screen.dart';
import '../../features/consumer/presentation/shop_profile_screen.dart';
import '../../features/consumer/presentation/product_detail_screen.dart';
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
import '../../features/delivery/presentation/delivery_home_screen.dart';
import '../../features/delivery/presentation/active_trip_screen.dart';
import '../../features/delivery/presentation/delivery_earnings_screen.dart';

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

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final currentFlavor = ref.watch(appFlavorProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          if (authState.isGuest) {
            return const ConsumerHomeScreen();
          }

          final user = authState.user;
          final effectiveRole = user?.role ?? UserRole.consumer;
          if (effectiveRole == UserRole.seller || currentFlavor == AppFlavor.seller) {
            return const SellerHomeScreen();
          } else if (effectiveRole == UserRole.delivery || currentFlavor == AppFlavor.delivery) {
            return const DeliveryHomeScreen();
          } else {
            return const ConsumerHomeScreen();
          }
        },
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
      // Consumer Routes
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
        path: '/delivery/trip/:id',
        builder: (context, state) => ActiveTripScreen(
          orderId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/delivery/earnings',
        builder: (context, state) => const DeliveryEarningsScreen(),
      ),
    ],
  );
});
