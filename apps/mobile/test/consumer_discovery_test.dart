import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paridhan_mobile/main_consumer.dart';
import 'package:paridhan_mobile/core/routing/app_router.dart';
import 'package:paridhan_mobile/core/constants/app_constants.dart';
import 'package:paridhan_mobile/features/auth/presentation/auth_state.dart';
import 'package:paridhan_mobile/features/auth/domain/user_profile.dart';
import 'package:paridhan_mobile/features/consumer/data/consumer_repository.dart';
import 'package:paridhan_mobile/features/consumer/presentation/cart_controller.dart';
import 'test_utils.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  group('Phase 3: Consumer Discovery, Product Catalog & Cart Tests', () {
    test('ConsumerRepository fetches PostGIS nearby shops with formatted distance', () async {
      final repo = ConsumerRepository();
      final shops = await repo.getNearbyShops(latitude: 26.9124, longitude: 75.7873);

      expect(shops.isNotEmpty, isTrue);
      final first = shops.first;
      expect(first.formattedDistance.contains('m') || first.formattedDistance.contains('km'), isTrue);
    });

    test('ConsumerRepository search filters by query keyword and price boundaries', () async {
      final repo = ConsumerRepository();
      
      final kurtaResults = await repo.searchProducts(query: 'Kurta');
      expect(kurtaResults.any((p) => p.title.contains('Kurta')), isTrue);

      final priceFiltered = await repo.searchProducts(maxPrice: 1500);
      expect(priceFiltered.every((p) => p.basePrice <= 1500), isTrue);
    });

    testWidgets('Renders Consumer Home with PostGIS boutiques and navigates to Product Details', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appFlavorProvider.overrideWith(() => FlavorNotifier(AppFlavor.consumer)),
          ],
          child: const ParidhanApp(flavorTitle: 'Consumer Test'),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Home Discovery Elements
      expect(find.text('Nearby Boutiques (PostGIS)'), findsOneWidget);
      expect(find.text('Jaipur Heritage Handlooms'), findsWidgets);
      expect(find.text('Pure Cotton Handblock Anarkali Kurta'), findsWidgets);

      // Tap on the product
      await tester.tap(find.text('Pure Cotton Handblock Anarkali Kurta').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Product Detail screen
      expect(find.text('Bargain Enabled'), findsOneWidget);
      expect(find.text('Select Size'), findsOneWidget);
      expect(find.text('Add to Bag'), findsOneWidget);
      expect(find.text('Bargain'), findsOneWidget);
    });

    test('CartController adds item, updates quantity, and computes subtotal accurately', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(
                const UserProfile(
                  id: 'consumer-test-1',
                  role: UserRole.consumer,
                  fullName: 'Priya Sharma',
                ),
              )),
        ],
      );
      addTearDown(container.dispose);

      final repo = ConsumerRepository();
      final products = await repo.searchProducts();
      expect(products.isNotEmpty, isTrue);

      final product = products.first;
      final variant = product.variants.first;

      final cartController = container.read(cartProvider.notifier);

      // Add 2 units of the product
      final success = await cartController.addItem(
        product: product,
        variant: variant,
        quantity: 2,
      );
      expect(success, isTrue);

      final stateAfterAdd = container.read(cartProvider);
      expect(stateAfterAdd.totalItems, equals(2));
      expect(stateAfterAdd.subtotal, equals(product.basePrice * 2));

      // Update quantity to 3
      final cartItem = stateAfterAdd.items.first;
      await cartController.updateQuantity(cartItem.id, 3);

      final stateAfterUpdate = container.read(cartProvider);
      expect(stateAfterUpdate.totalItems, equals(3));
      expect(stateAfterUpdate.subtotal, equals(product.basePrice * 3));
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
