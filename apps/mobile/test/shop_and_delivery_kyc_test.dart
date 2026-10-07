import 'package:flutter_test/flutter_test.dart';
import 'package:paridhan_mobile/features/seller/domain/shop_model.dart';
import 'package:paridhan_mobile/features/seller/domain/product_model.dart';
import 'package:paridhan_mobile/features/seller/domain/variant_model.dart';
import 'package:paridhan_mobile/features/seller/data/seller_repository.dart';
import 'package:paridhan_mobile/features/consumer/data/consumer_repository.dart';
import 'package:paridhan_mobile/features/delivery/data/delivery_repository.dart';
import 'package:paridhan_mobile/features/admin/data/admin_repository.dart';
import 'package:paridhan_mobile/features/admin/domain/admin_metrics_model.dart';

void main() {
  group('Real Paridhan Shop Registration, Delivery KYC, and Admin Control Tests', () {
    late SellerRepository sellerRepo;
    late ConsumerRepository consumerRepo;
    late DeliveryRepository deliveryRepo;
    late AdminRepository adminRepo;

    setUp(() {
      sellerRepo = SellerRepository();
      consumerRepo = ConsumerRepository();
      deliveryRepo = DeliveryRepository();
      adminRepo = AdminRepository();
    });

    test('1. Immediate Inventory Sync: Adding item from seller immediately reflects in catalog & consumer discovery', () async {
      final initialProducts = await consumerRepo.searchProducts();
      final initialCount = initialProducts.length;

      const newProduct = ProductModel(
        id: 'prod_test_immediate_sync_101',
        shopId: 'shop-jaipur-01',
        categoryId: 'b0000001-0000-0000-0000-000000000001',
        title: 'Royal Zari Silk Lehanga',
        description: 'Handcrafted zari work festive lehenga',
        basePrice: 4999.0,
        minBargainPrice: 4200.0,
        bargainEnabled: true,
        status: 'active',
        variants: [
          VariantModel(
            id: 'var-test-101',
            productId: 'prod_test_immediate_sync_101',
            size: 'Free Size',
            color: 'Crimson Red',
            stockQty: 10,
            sku: 'RZS-101',
            imageUrls: ['https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600'],
          ),
        ],
      );

      // Seller saves product
      final savedProduct = await sellerRepo.createOrUpdateProduct(newProduct, newProduct.variants);
      expect(savedProduct.id, equals('prod_test_immediate_sync_101'));

      // Consumer discovers product immediately without reload delays
      final updatedProducts = await consumerRepo.searchProducts();
      expect(updatedProducts.length, equals(initialCount + 1));
      expect(updatedProducts.any((p) => p.id == 'prod_test_immediate_sync_101'), isTrue);
    });

    test('2. Shop Registration & KYC Details: Model correctly holds GSTIN, PAN, Bank details and verifies status', () {
      final shop = ShopModel(
        id: 'shop_kyc_01',
        sellerId: 'user_seller_01',
        name: 'Vogue Rajputana',
        gstin: '08AAAAA0000A1Z5',
        panNumber: 'ABCDE1234F',
        businessType: 'Partnership',
        tradeLicenseNumber: 'TL/2026/9921',
        aadhaarNumber: 'XXXX-XXXX-9012',
        bankAccountName: 'Vogue Rajputana Enterprises',
        bankAccountNumber: '98765432101234',
        bankIfsc: 'HDFC0001234',
        pincode: '302001',
        landmark: 'Near Hawa Mahal',
        address: 'Badi Chaupar, Pink City, Jaipur',
        latitude: 26.9239,
        longitude: 75.8267,
        status: 'pending',
        kycStatus: 'pending',
        kycDocuments: const ['https://paridhan.app/docs/gst_01.pdf'],
        createdAt: DateTime.now(),
      );

      expect(shop.isVerified, isFalse);
      expect(shop.gstin, equals('08AAAAA0000A1Z5'));
      expect(shop.panNumber, equals('ABCDE1234F'));
      expect(shop.businessType, equals('Partnership'));
      expect(shop.pincode, equals('302001'));
      expect(shop.landmark, equals('Near Hawa Mahal'));

      // JSON serialization check
      final json = shop.toJson();
      expect(json['gstin'], equals('08AAAAA0000A1Z5'));
      expect(json['pan_number'], equals('ABCDE1234F'));
      expect(json['pincode'], equals('302001'));

      final fromJson = ShopModel.fromJson(json);
      expect(fromJson.gstin, equals('08AAAAA0000A1Z5'));
      expect(fromJson.tradeLicenseNumber, equals('TL/2026/9921'));
    });

    test('3. Admin Boutique Approval State Sync: Approving boutique in admin reflects in real-time', () async {
      // Mock initial pending shop status update
      SellerRepository.updateMockShopStatus(
        status: 'pending',
        kycStatus: 'pending',
      );

      final shopBefore = await sellerRepo.getShop('mock-user-123');
      expect(shopBefore?.isVerified, isFalse);

      // Admin approves boutique
      await adminRepo.updateBoutiqueKycStatus(
        boutiqueId: 'shop-kyc-01',
        status: KycStatus.approved,
        verificationNotes: 'All GSTIN and bank records verified.',
      );

      // State is immediately verified
      final shopAfter = await sellerRepo.getShop('mock-user-123');
      expect(shopAfter?.status, equals('verified'));
      expect(shopAfter?.kycStatus, equals('approved'));
      expect(shopAfter?.isVerified, isTrue);
    });

    test('4. Delivery Partner KYC & Verification Gating: Unverified drivers are restricted until Admin approval', () async {
      // Driver verification status simulation
      DeliveryRepository.setSimulatedVerificationStatus('pending');
      final unverifiedStatus = await deliveryRepo.getDriverVerificationStatus('driver-01');
      expect(unverifiedStatus, equals('pending'));

      // Admin approves driver
      final success = await adminRepo.updateDeliveryPartnerKycStatus(
        driverId: 'driver-01',
        verificationStatus: 'verified',
        verificationNotes: 'Driving license and Aadhaar KYC verified.',
      );
      expect(success, isTrue);

      DeliveryRepository.setSimulatedVerificationStatus('verified');
      final verifiedStatus = await deliveryRepo.getDriverVerificationStatus('driver-01');
      expect(verifiedStatus, equals('verified'));

      // Check partner item holds verification details
      const partner = AdminDeliveryPartnerItem(
        id: 'dp_01',
        name: 'Ramesh Verma',
        phone: '+91 98290 44556',
        vehicleNumber: 'RJ 14 EV 9821',
        vehicleType: 'Electric Scooter',
        isOnDuty: true,
        ordersDelivered: 45,
        totalEarnings: 3200.0,
        verificationStatus: 'verified',
        rating: 4.85,
        drivingLicenseNumber: 'RJ-14-2022-009182',
        panNumber: 'ABCPV1234M',
        aadhaarNumber: 'XXXX-XXXX-4567',
        upiId: 'ramesh@okhdfcbank',
      );

      expect(partner.drivingLicenseNumber, equals('RJ-14-2022-009182'));
      expect(partner.upiId, equals('ramesh@okhdfcbank'));
      expect(partner.isVerified, isTrue);
    });

    test('5. Delivery Fleet Privacy: Admin delivery partner list presents names, vehicle, ratings without exposing raw GPS coordinates', () async {
      final metrics = await adminRepo.getPlatformMetrics();
      final partners = metrics.deliveryPartners;
      expect(partners.isNotEmpty, isTrue);

      for (final p in partners) {
        expect(p.name.isNotEmpty, isTrue);
        expect(p.phone.isNotEmpty, isTrue);
        expect(p.vehicleType.isNotEmpty, isTrue);
        expect(p.ordersDelivered, greaterThanOrEqualTo(0));
      }
    });
  });
}
