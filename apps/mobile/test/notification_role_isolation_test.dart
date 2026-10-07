import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paridhan_mobile/core/constants/app_constants.dart';
import 'package:paridhan_mobile/core/notifications/data/notification_repository.dart';
import 'package:paridhan_mobile/core/notifications/domain/app_notification_model.dart';
import 'package:paridhan_mobile/core/notifications/presentation/role_notification_controller.dart';
import 'package:paridhan_mobile/core/notifications/presentation/role_notifications_sheet.dart';
import 'package:paridhan_mobile/core/notifications/presentation/role_notification_badge.dart';
import 'package:paridhan_mobile/features/auth/domain/user_profile.dart';
import 'package:paridhan_mobile/features/auth/presentation/auth_state.dart';
import 'package:paridhan_mobile/features/consumer/presentation/wishlist_controller.dart';
import 'package:paridhan_mobile/features/consumer/presentation/cart_controller.dart';
import 'package:paridhan_mobile/features/seller/domain/product_model.dart';
import 'package:paridhan_mobile/features/seller/domain/variant_model.dart';
import 'test_utils.dart';

class _MockAuthNotifier extends AuthNotifier {
  final UserProfile? mockUser;
  _MockAuthNotifier([this.mockUser]);

  @override
  AuthState build() {
    return AuthState(
      isLoading: false,
      isGuest: false,
      user: mockUser,
    );
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  setUp(() {
    NotificationRepository.resetInMemoryStorage();
  });

  tearDown(() {
    NotificationRepository.resetInMemoryStorage();
  });

  group('PARIDHAN Role Notification Isolation Tests', () {
    const testUser = UserProfile(
      id: 'test-user-001',
      fullName: 'Aarav Sharma',
      email: 'aarav@paridhan.app',
      phone: '+919876543210',
      role: UserRole.consumer,
    );

    test('Customer Wishlist and Cart actions generate notifications ONLY in Customer state', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(testUser)),
        ],
      );

      final dummyProduct = ProductModel(
        id: 'prod-saree-01',
        shopId: 'shop-amravati-01',
        categoryId: 'ethnic',
        title: 'Chanderi Silk Saree',
        description: 'Authentic handcrafted silk saree',
        basePrice: 2499.0,
        minBargainPrice: 1999.0,
        variants: [
          const VariantModel(
            id: 'var-01',
            productId: 'prod-saree-01',
            size: 'Free Size',
            color: 'Royal Blue',
            stockQty: 5,
            sku: 'SKU-01',
          ),
        ],
      );

      final dummyVariant = dummyProduct.variants.first;

      // 1. Perform Wishlist Action
      await container.read(wishlistProvider.notifier).toggleWishlist(
            product: dummyProduct,
            variant: dummyVariant,
          );

      // 2. Perform Cart Action
      await container.read(cartProvider.notifier).addItem(
            product: dummyProduct,
            variant: dummyVariant,
            quantity: 1,
          );

      // Verify Customer state has both notifications
      final customerState = container.read(roleNotificationProvider(UserRole.consumer));
      expect(customerState.notifications.length, greaterThanOrEqualTo(2));
      expect(customerState.notifications.any((n) => n.category == NotificationCategory.wishlist), isTrue);
      expect(customerState.notifications.any((n) => n.category == NotificationCategory.cart), isTrue);

      // STRICT ISOLATION ASSERTIONS:
      // Seller state must have ZERO customer notifications
      final sellerState = container.read(roleNotificationProvider(UserRole.seller));
      expect(sellerState.notifications.where((n) => n.category == NotificationCategory.wishlist), isEmpty);
      expect(sellerState.notifications.where((n) => n.category == NotificationCategory.cart), isEmpty);

      // Delivery state must have ZERO customer notifications
      final deliveryState = container.read(roleNotificationProvider(UserRole.delivery));
      expect(deliveryState.notifications.where((n) => n.category == NotificationCategory.wishlist), isEmpty);
      expect(deliveryState.notifications.where((n) => n.category == NotificationCategory.cart), isEmpty);

      // Admin state must have ZERO customer notifications
      final adminState = container.read(roleNotificationProvider(UserRole.admin));
      expect(adminState.notifications.where((n) => n.category == NotificationCategory.wishlist), isEmpty);
      expect(adminState.notifications.where((n) => n.category == NotificationCategory.cart), isEmpty);
    });

    test('Seller notifications appear ONLY in Seller platform state', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(testUser)),
        ],
      );

      // Generate Seller Notification
      await container.read(roleNotificationProvider(UserRole.seller).notifier).postNotification(
            title: 'New Order Received',
            body: 'Customer placed an order for 2 silk kurtas.',
            category: NotificationCategory.order,
          );

      await container.read(roleNotificationProvider(UserRole.seller).notifier).postNotification(
            title: 'Low Inventory Alert',
            body: 'Stock for Royal Blue Anarkali is below 2 units.',
            category: NotificationCategory.inventory,
          );

      // Verify Seller state
      final sellerState = container.read(roleNotificationProvider(UserRole.seller));
      expect(sellerState.notifications.length, 2);
      expect(sellerState.notifications.every((n) => n.role == UserRole.seller), isTrue);

      // Verify Customer state has NO seller notifications
      final customerState = container.read(roleNotificationProvider(UserRole.consumer));
      expect(customerState.notifications.where((n) => n.title == 'Low Inventory Alert'), isEmpty);

      // Verify Delivery state has NO seller notifications
      final deliveryState = container.read(roleNotificationProvider(UserRole.delivery));
      expect(deliveryState.notifications.where((n) => n.title == 'Low Inventory Alert'), isEmpty);

      // Verify Admin state has NO seller notifications
      final adminState = container.read(roleNotificationProvider(UserRole.admin));
      expect(adminState.notifications.where((n) => n.title == 'Low Inventory Alert'), isEmpty);
    });

    test('Admin notifications appear ONLY in Admin platform state', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(testUser)),
        ],
      );

      // Generate Admin Notification
      await container.read(roleNotificationProvider(UserRole.admin).notifier).postNotification(
            title: 'KYC Document Verification Required',
            body: 'Boutique #shop-102 submitted GST and PAN for review.',
            category: NotificationCategory.kyc,
          );

      // Verify Admin state
      final adminState = container.read(roleNotificationProvider(UserRole.admin));
      expect(adminState.notifications.length, 1);
      expect(adminState.notifications.first.title, 'KYC Document Verification Required');

      // Verify Customer, Seller, Delivery do NOT receive it
      expect(container.read(roleNotificationProvider(UserRole.consumer)).notifications, isEmpty);
      expect(container.read(roleNotificationProvider(UserRole.seller)).notifications, isEmpty);
      expect(container.read(roleNotificationProvider(UserRole.delivery)).notifications, isEmpty);
    });

    test('Delivery notifications appear ONLY in Delivery platform state', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(testUser)),
        ],
      );

      // Generate Delivery Notification
      await container.read(roleNotificationProvider(UserRole.delivery).notifier).postNotification(
            title: 'New Hyperlocal Delivery Assignment',
            body: 'Pickup ready at Jawahar Gate Boutique (1.4 km).',
            category: NotificationCategory.assignment,
          );

      // Verify Delivery state
      final deliveryState = container.read(roleNotificationProvider(UserRole.delivery));
      expect(deliveryState.notifications.length, 1);
      expect(deliveryState.notifications.first.category, NotificationCategory.assignment);

      // Verify Customer, Seller, Admin do NOT receive it
      expect(container.read(roleNotificationProvider(UserRole.consumer)).notifications, isEmpty);
      expect(container.read(roleNotificationProvider(UserRole.seller)).notifications, isEmpty);
      expect(container.read(roleNotificationProvider(UserRole.admin)).notifications, isEmpty);
    });

    test('Category validation strictly prevents invalid cross-role category bleed', () {
      final customerCategories = AppNotificationModel.allowedCategoriesFor(UserRole.consumer);
      final sellerCategories = AppNotificationModel.allowedCategoriesFor(UserRole.seller);
      final deliveryCategories = AppNotificationModel.allowedCategoriesFor(UserRole.delivery);
      final adminCategories = AppNotificationModel.allowedCategoriesFor(UserRole.admin);

      // Customer checks
      expect(customerCategories.contains(NotificationCategory.wishlist), isTrue);
      expect(customerCategories.contains(NotificationCategory.cart), isTrue);
      expect(customerCategories.contains(NotificationCategory.inventory), isFalse);
      expect(customerCategories.contains(NotificationCategory.assignment), isFalse);

      // Seller checks
      expect(sellerCategories.contains(NotificationCategory.inventory), isTrue);
      expect(sellerCategories.contains(NotificationCategory.campaign), isTrue);
      expect(sellerCategories.contains(NotificationCategory.wishlist), isFalse);
      expect(sellerCategories.contains(NotificationCategory.cart), isFalse);

      // Delivery checks
      expect(deliveryCategories.contains(NotificationCategory.assignment), isTrue);
      expect(deliveryCategories.contains(NotificationCategory.trip), isTrue);
      expect(deliveryCategories.contains(NotificationCategory.wishlist), isFalse);
      expect(deliveryCategories.contains(NotificationCategory.kyc), isFalse);

      // Admin checks
      expect(adminCategories.contains(NotificationCategory.platform), isTrue);
      expect(adminCategories.contains(NotificationCategory.dispute), isTrue);
      expect(adminCategories.contains(NotificationCategory.wishlist), isFalse);
      expect(adminCategories.contains(NotificationCategory.cart), isFalse);
    });

    testWidgets('RoleNotificationsSheet displays role-isolated content correctly', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(testUser)),
        ],
      );

      // Post 1 Customer notification and 1 Seller notification
      await container.read(roleNotificationProvider(UserRole.consumer).notifier).postNotification(
            title: 'Wishlist Special Offer',
            body: '20% off on your wishlisted lehenga.',
            category: NotificationCategory.wishlist,
          );

      await container.read(roleNotificationProvider(UserRole.seller).notifier).postNotification(
            title: 'Seller Order #999',
            body: 'Pack garment for delivery.',
            category: NotificationCategory.order,
          );

      // Render Customer notification sheet
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: RoleNotificationsSheet(role: UserRole.consumer),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show Customer notification
      expect(find.text('Customer Notifications'), findsOneWidget);
      expect(find.text('Wishlist Special Offer'), findsOneWidget);
      // Must NOT show Seller notification
      expect(find.text('Seller Order #999'), findsNothing);

      // Render Seller notification sheet
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: RoleNotificationsSheet(role: UserRole.seller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show Seller notification
      expect(find.text('Seller Studio Notifications'), findsOneWidget);
      expect(find.text('Seller Order #999'), findsOneWidget);
      // Must NOT show Customer notification
      expect(find.text('Wishlist Special Offer'), findsNothing);
    });

    testWidgets('RoleNotificationBadge reflects unread count for isolated role', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(testUser)),
        ],
      );

      // Add 2 customer notifications
      await container.read(roleNotificationProvider(UserRole.consumer).notifier).postNotification(
            title: 'Cart item reserved',
            body: 'Complete checkout within 15 minutes.',
            category: NotificationCategory.cart,
          );
      await container.read(roleNotificationProvider(UserRole.consumer).notifier).postNotification(
            title: 'Price Drop Alert',
            body: 'Item in wishlist is now ₹1999.',
            category: NotificationCategory.offer,
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  RoleNotificationBadge(role: UserRole.consumer),
                  RoleNotificationBadge(role: UserRole.seller),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Customer badge should show '2'
      expect(find.text('2'), findsOneWidget);

      // Seller badge should not show '2' (seller has 0 unread)
      final sellerState = container.read(roleNotificationProvider(UserRole.seller));
      expect(sellerState.unreadCount, 0);
    });
  });
}
