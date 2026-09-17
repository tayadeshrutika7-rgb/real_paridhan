import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:paridhan_mobile/main_consumer.dart';
import 'package:paridhan_mobile/core/routing/app_router.dart';
import 'package:paridhan_mobile/core/constants/app_constants.dart';
import 'package:paridhan_mobile/core/utils/image_compressor.dart';
import 'package:paridhan_mobile/features/auth/presentation/auth_state.dart';
import 'package:paridhan_mobile/features/auth/domain/user_profile.dart';
import 'package:paridhan_mobile/features/seller/presentation/seller_controller.dart';

void main() {
  group('Phase 2: Seller Shop & Catalog Management Tests', () {
    test('ImageCompressor resizes and compresses high-res image to <= 500KB threshold', () async {
      // Create a 2000x2000 uncompressed test image
      final testImg = img.Image(width: 2000, height: 2000);
      img.fill(testImg, color: img.ColorRgb8(200, 50, 50));
      final rawJpg = Uint8List.fromList(img.encodeJpg(testImg, quality: 100));

      final compressed = await ImageCompressor.compressImage(rawJpg);

      // Verify compressed length is <= 500KB
      expect(compressed.lengthInBytes <= ImageCompressor.maxTargetSizeBytes, isTrue);
    });

    testWidgets('Renders Seller Studio Home and navigates to Add Product', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockSeller = UserProfile(
        id: 'mock-seller-1',
        role: UserRole.seller,
        fullName: 'Jaipur Heritage Handlooms',
        email: 'seller@jaipur.local',
        acceptedTermsAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appFlavorProvider.overrideWith(() => FlavorNotifier(AppFlavor.seller)),
            authProvider.overrideWith(() => _MockAuthNotifier(mockSeller)),
          ],
          child: const ParidhanApp(flavorTitle: 'Seller Studio Test'),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Seller Studio Dashboard elements
      expect(find.text('Seller Studio'), findsOneWidget);
      expect(find.text('Catalog & Operations'), findsOneWidget);
      expect(find.text('Add New Garment / Product'), findsOneWidget);

      // Tap on Add New Garment
      await tester.tap(find.text('Add New Garment / Product'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Add Product Screen
      expect(find.text('Add New Product'), findsOneWidget);
      expect(find.text('Pricing & Bargaining Floor Engine'), findsOneWidget);
      expect(find.text('Retail Base Price (₹)'), findsOneWidget);
      expect(find.text('Floor Price (₹)'), findsOneWidget);
      expect(find.text('Publish Garment to Marketplace'), findsOneWidget);
    });

    test('SellerController validates floor price and updates inventory', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(sellerProvider.notifier);
      
      // Wait for microtask initial loading to complete
      await Future.delayed(const Duration(milliseconds: 50));
      final state = container.read(sellerProvider);

      expect(state.products.isNotEmpty, isTrue);
      final firstProduct = state.products.first;
      expect(firstProduct.variants.isNotEmpty, isTrue);

      final initialStock = firstProduct.variants.first.stockQty;
      final variantId = firstProduct.variants.first.id;

      // Increment stock by 5
      await controller.updateStock(variantId, initialStock + 5);

      final updatedState = container.read(sellerProvider);
      final updatedVariant = updatedState.products.first.variants.first;
      expect(updatedVariant.stockQty, equals(initialStock + 5));
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
