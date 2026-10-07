import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paridhan_mobile/core/constants/app_constants.dart';
import 'package:paridhan_mobile/features/auth/domain/user_profile.dart';
import 'package:paridhan_mobile/features/auth/presentation/auth_state.dart';
import 'package:paridhan_mobile/features/seller/domain/shop_model.dart';
import 'package:paridhan_mobile/features/seller/presentation/seller_controller.dart';
import 'package:paridhan_mobile/features/seller/presentation/seller_ad_request_screen.dart';
import 'package:paridhan_mobile/features/admin/presentation/admin_advertisements_screen.dart';
import 'package:paridhan_mobile/features/advertising/domain/advertisement_model.dart';
import 'package:paridhan_mobile/features/advertising/data/advertisement_repository.dart';
import 'test_utils.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  group('Seller Promote & Advertisements Production Flow Tests', () {
    test('AdvertisementModel computes correct effectiveStatus, isLive, and CTR', () {
      final now = DateTime.now();

      // 1. Live Approved Ad
      final liveAd = AdvertisementModel(
        id: 'ad-live-1',
        sellerId: 'seller-1',
        shopId: 'shop-1',
        shopName: 'Heritage Silk',
        sellerEmail: 'silk@jaipur.in',
        sellerPhone: '+91 98290 12345',
        title: 'Festival Silk Sarees',
        subtitle: 'Handwoven pure silk',
        bannerImageUrl: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c',
        placement: 'home_hero',
        targetType: 'shop',
        targetCategory: 'Women Ethnic',
        durationDays: 15,
        budget: 1499.0,
        paymentId: 'pay_test_001',
        paymentStatus: 'paid',
        status: 'approved',
        isPaused: false,
        impressions: 1000,
        clicks: 50,
        createdAt: now.subtract(const Duration(days: 1)),
        approvedAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(days: 14)),
      );

      expect(liveAd.isLive, isTrue);
      expect(liveAd.isExpired, isFalse);
      expect(liveAd.isPausedState, isFalse);
      expect(liveAd.effectiveStatus, 'approved');
      expect(liveAd.ctr, 5.0); // 50 / 1000 * 100 = 5.0%

      // 2. Expired Ad
      final expiredAd = liveAd.copyWith(
        expiresAt: now.subtract(const Duration(days: 1)),
      );
      expect(expiredAd.isExpired, isTrue);
      expect(expiredAd.isLive, isFalse);
      expect(expiredAd.effectiveStatus, 'completed');

      // 3. Paused Ad
      final pausedAd = liveAd.copyWith(isPaused: true);
      expect(pausedAd.isLive, isFalse);
      expect(pausedAd.isPausedState, isTrue);
      expect(pausedAd.effectiveStatus, 'paused');

      // 4. Rejected Ad
      final rejectedAd = liveAd.copyWith(status: 'rejected', adminNotes: 'Low resolution');
      expect(rejectedAd.isRejected, isTrue);
      expect(rejectedAd.isLive, isFalse);
      expect(rejectedAd.effectiveStatus, 'rejected');
    });

    test('AdvertisementRepository creates ad request, tracks impressions, clicks and updates status', () async {
      final repo = AdvertisementRepository();

      // 1. Fetch active hero ads
      final heroAds = await repo.getActiveAdsByPlacement('home_hero');
      expect(heroAds.isNotEmpty, isTrue);

      // 2. Create new ad request
      final newAd = AdvertisementModel(
        id: 'ad-test-${DateTime.now().millisecondsSinceEpoch}',
        sellerId: 'test-seller',
        shopId: 'shop-jaipur-01',
        shopName: 'Jaipur Handlooms',
        sellerEmail: 'seller@jaipur.in',
        sellerPhone: '+91 99999 88888',
        title: 'New Bridal Lehengas',
        subtitle: 'Festive discounts for wedding season',
        bannerImageUrl: 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b',
        placement: 'category_header',
        targetType: 'category',
        targetCategory: 'Women Ethnic',
        durationDays: 7,
        budget: 799.0,
        paymentId: 'pay_test_9988',
        paymentStatus: 'paid',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final created = await repo.createAdRequest(newAd);
      expect(created.id, newAd.id);
      expect(created.status, 'pending');

      // 3. Admin Approves Ad
      final approved = await repo.updateAdStatus(
        adId: created.id,
        status: 'approved',
        adminNotes: 'Verified and activated',
      );
      expect(approved?.status, 'approved');
      expect(approved?.approvedAt, isNotNull);
      expect(approved?.expiresAt, isNotNull);

      // 4. Record impression and click
      await repo.recordImpression(created.id);
      await repo.recordClick(created.id);

      // 5. Toggle pause
      final paused = await repo.toggleAdPause(created.id, true);
      expect(paused?.isPaused, isTrue);

      // 6. Send SMTP confirmation
      final email = await repo.sendSmtpEmail(
        toEmail: 'seller@jaipur.in',
        toName: 'Jaipur Handlooms',
        subject: 'Campaign Approved',
        bodyText: 'Your ad is now active on the Paridhan platform.',
        templateType: 'ad_approved',
      );
      expect(email.isDelivered, isTrue);
    });

    testWidgets('Renders SellerAdRequestScreen with what to promote, duration cards, and presets', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const mockShop = ShopModel(
        id: 'shop-jaipur-01',
        sellerId: 'seller-1',
        name: 'Jaipur Heritage Handlooms',
        description: 'Authentic royal handlooms',
        address: 'Johari Bazaar, Jaipur',
        latitude: 26.9124,
        longitude: 75.7873,
        contactEmail: 'seller@boutique.com',
        contactPhone: '+91 98290 12345',
        status: 'verified',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sellerProvider.overrideWith(() => _MockSellerController(mockShop)),
            authProvider.overrideWith(() => _MockAuthNotifier(
                  const UserProfile(
                    id: 'seller-1',
                    role: UserRole.seller,
                    fullName: 'Rajesh Sharma',
                    email: 'seller@boutique.com',
                  ),
                )),
          ],
          child: const MaterialApp(
            home: SellerAdRequestScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Promote & Advertisements'), findsOneWidget);
      expect(find.text('1. What would you like to promote?'), findsOneWidget);
      expect(find.text('2. Advertisement Placement'), findsOneWidget);
      expect(find.text('3. Advertisement Banner Image'), findsOneWidget);
      expect(find.text('Live Customer Screen Preview'), findsOneWidget);
      expect(find.text('4. Campaign Text & Call to Action'), findsOneWidget);
      expect(find.text('5. Campaign Duration & Package'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('15 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('Review & Pay with Razorpay'), findsOneWidget);
    });

    testWidgets('Renders AdminAdvertisementsScreen with review actions, rejection and SMTP logs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminAdvertisementsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Seller Advertisements & Promotions'), findsOneWidget);
      expect(find.textContaining('Ad Requests'), findsOneWidget);
      expect(find.textContaining('SMTP Email Logs'), findsOneWidget);
      expect(find.text('Contact via SMTP'), findsWidgets);
    });
  });
}

class _MockSellerController extends SellerController {
  final ShopModel mockShop;
  _MockSellerController(this.mockShop);

  @override
  SellerState build() {
    return SellerState(
      isLoading: false,
      shop: mockShop,
      products: const [],
    );
  }
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
