import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paridhan_mobile/core/constants/app_constants.dart';
import 'package:paridhan_mobile/features/auth/domain/user_profile.dart';
import 'package:paridhan_mobile/features/auth/presentation/auth_state.dart';
import 'package:paridhan_mobile/features/consumer/domain/wishlist_item_model.dart';
import 'package:paridhan_mobile/features/consumer/presentation/wishlist_controller.dart';
import 'package:paridhan_mobile/features/consumer/presentation/wishlist_screen.dart';
import 'package:paridhan_mobile/features/consumer/presentation/cart_controller.dart';
import 'package:paridhan_mobile/features/seller/domain/product_model.dart';
import 'package:paridhan_mobile/features/seller/domain/variant_model.dart';
import 'test_utils.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  group('Wishlist Feature Tests', () {
    test('WishlistItemModel calculates discount percentage and savings accurately', () {
      final item = WishlistItemModel(
        id: 'wish-1',
        consumerId: 'user-1',
        productId: 'prod-1',
        variantId: 'var-1',
        productTitle: 'Pure Silk Bandhani Bridal Lehenga',
        shopId: 'shop-1',
        shopName: 'Johari Royal Heritage Boutique',
        size: 'M (38)',
        color: 'Crimson Red',
        imageUrl: 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600',
        originalPrice: 16874.00,
        currentPrice: 12499.00,
        minBargainPrice: 9999.00,
        bargainEnabled: true,
        targetDiscountNote: 'Waiting for discount / price drop',
        createdAt: DateTime.now(),
        stockQty: 5,
      );

      expect(item.potentialSavings, equals(4375.00));
      expect(item.discountPercentage.round(), equals(26));
      expect(item.maxBargainDiscount, equals(2500.00));
    });

    test('WishlistController toggles wishlist state and moves item to cart', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(
                const UserProfile(
                  id: 'consumer-test-wishlist',
                  role: UserRole.consumer,
                  fullName: 'Ananya Deshmukh',
                ),
              )),
        ],
      );
      addTearDown(container.dispose);

      final wishlistController = container.read(wishlistProvider.notifier);

      const product = ProductModel(
        id: 'prod-lehenga-101',
        shopId: 'shop-amravati-01',
        categoryId: 'cat-ethnic',
        title: 'Pure Silk Bandhani Bridal Lehenga',
        basePrice: 12499.00,
        minBargainPrice: 9999.00,
        bargainEnabled: true,
        variants: [
          VariantModel(
            id: 'var-lehenga-m',
            productId: 'prod-lehenga-101',
            size: 'M (38)',
            color: 'Crimson Red',
            stockQty: 5,
            sku: 'LEH-BAN-M',
            imageUrls: ['https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600'],
          ),
        ],
      );

      final variant = product.variants.first;

      // 1. Toggle Add to Wishlist
      final added = await wishlistController.toggleWishlist(
        product: product,
        variant: variant,
        shopName: 'Johari Royal Heritage Boutique',
      );
      expect(added, isTrue);

      final isSaved = wishlistController.isWishlisted(product.id, variantId: variant.id);
      expect(isSaved, isTrue);

      final state = container.read(wishlistProvider);
      expect(state.items.any((i) => i.productId == product.id), isTrue);

      // 2. Move item to cart
      final wishItem = state.items.firstWhere((i) => i.productId == product.id);
      final movedToCart = await wishlistController.moveToCart(wishItem);
      expect(movedToCart, isTrue);

      final cartState = container.read(cartProvider);
      expect(cartState.items.any((i) => i.productId == product.id), isTrue);
    });

    testWidgets('Renders WishlistScreen with discount banner and item actions', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockItem = WishlistItemModel(
        id: 'wish-1',
        consumerId: 'consumer-test-wishlist',
        productId: 'prod-lehenga-101',
        variantId: 'var-lehenga-m',
        productTitle: 'Pure Silk Bandhani Bridal Lehenga',
        shopId: 'shop-amravati-01',
        shopName: 'Johari Royal Heritage Boutique',
        size: 'M (38)',
        color: 'Crimson Red',
        imageUrl: 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600',
        originalPrice: 16874.00,
        currentPrice: 12499.00,
        minBargainPrice: 9999.00,
        bargainEnabled: true,
        targetDiscountNote: 'Waiting for discount / price drop',
        createdAt: DateTime.now(),
        stockQty: 5,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => _MockAuthNotifier(
                  const UserProfile(
                    id: 'consumer-test-wishlist',
                    role: UserRole.consumer,
                    fullName: 'Ananya Deshmukh',
                  ),
                )),
            wishlistProvider.overrideWith(() => _MockPopulatedWishlistController([mockItem])),
          ],
          child: const MaterialApp(
            home: WishlistScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Wishlist screen UI elements
      expect(find.text('My Wishlist'), findsOneWidget);
      expect(find.text('Discount & Price Drop Tracker'), findsWidgets);
      expect(find.text('Pure Silk Bandhani Bridal Lehenga'), findsWidgets);
      expect(find.text('Move to Bag'), findsWidgets);
      expect(find.text('Bargain Price'), findsWidgets);
    });

    test('WishlistController strictly rejects guest adding or toggling items', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockGuestAuthNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final wishlistController = container.read(wishlistProvider.notifier);

      const product = ProductModel(
        id: 'prod-lehenga-101',
        shopId: 'shop-amravati-01',
        categoryId: 'cat-ethnic',
        title: 'Pure Silk Bandhani Bridal Lehenga',
        basePrice: 12499.00,
        minBargainPrice: 9999.00,
        bargainEnabled: true,
        variants: [
          VariantModel(
            id: 'var-lehenga-m',
            productId: 'prod-lehenga-101',
            size: 'M (38)',
            color: 'Crimson Red',
            stockQty: 5,
            sku: 'LEH-BAN-M',
            imageUrls: ['https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600'],
          ),
        ],
      );

      final variant = product.variants.first;

      // Attempt to toggle wishlist as guest -> must return false and not add
      final added = await wishlistController.toggleWishlist(
        product: product,
        variant: variant,
        shopName: 'Johari Royal Heritage Boutique',
      );
      expect(added, isFalse);

      final state = container.read(wishlistProvider);
      expect(state.items.isEmpty, isTrue);
      expect(wishlistController.isWishlisted(product.id), isFalse);
    });

    testWidgets('Renders Guest Locked view when guest accesses WishlistScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => _MockGuestAuthNotifier()),
          ],
          child: const MaterialApp(
            home: WishlistScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Guest Locked UI elements
      expect(find.text('Sign In to Access Wishlist'), findsOneWidget);
      expect(find.text('Sign In to Paridhan'), findsOneWidget);
    });
  });
}

class _MockAuthNotifier extends AuthNotifier {
  final UserProfile mockUser;
  _MockAuthNotifier(this.mockUser);

  @override
  AuthState build() {
    return AuthState(
      isLoading: false,
      isGuest: false,
      user: mockUser,
    );
  }
}

class _MockGuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return const AuthState(
      isLoading: false,
      isGuest: true,
      user: null,
    );
  }
}

class _MockPopulatedWishlistController extends WishlistController {
  final List<WishlistItemModel> initialItems;
  _MockPopulatedWishlistController(this.initialItems);

  @override
  WishlistState build() {
    return WishlistState(
      isLoading: false,
      items: initialItems,
    );
  }
}
