import 'package:flutter_test/flutter_test.dart';
import 'package:paridhan_mobile/features/consumer/domain/address_model.dart';
import 'package:paridhan_mobile/features/consumer/domain/bargain_model.dart';
import 'package:paridhan_mobile/features/consumer/domain/cart_item_model.dart';
import 'package:paridhan_mobile/features/consumer/domain/order_model.dart';

void main() {
  group('Phase 4 & 5 Integration & Razorpay Route Split Tests', () {
    test('Address formatting is accurate', () {
      const addr = AddressModel(
        id: 'addr-01',
        userId: 'user-01',
        fullName: 'Aarav Sharma',
        phone: '9829012345',
        addressLine1: 'Flat 402, Royal Heritage Apts',
        addressLine2: 'C-Scheme',
        landmark: 'Statue Circle',
        city: 'Jaipur',
        state: 'Rajasthan',
        pincode: '302001',
      );

      expect(addr.formattedAddress, contains('Flat 402, Royal Heritage Apts'));
      expect(addr.formattedAddress, contains('Near Statue Circle'));
      expect(addr.formattedAddress, contains('Jaipur, Rajasthan - 302001'));
    });

    test('CartItemModel uses agreed bargaining price when available', () {
      const regularItem = CartItemModel(
        id: 'item-1',
        consumerId: 'user-1',
        variantId: 'var-1',
        productId: 'prod-1',
        productTitle: 'Handblock Kurta',
        size: 'M',
        color: 'Blue',
        quantity: 2,
        imageUrl: 'http://example.com/img.jpg',
        unitPrice: 1500.0,
        shopId: 'shop-1',
        shopName: 'Jaipur Handlooms',
      );

      expect(regularItem.hasBargainPrice, isFalse);
      expect(regularItem.effectivePrice, 1500.0);
      expect(regularItem.itemTotal, 3000.0);

      // With accepted bargain
      final bargainedItem = regularItem.copyWith(agreedPrice: 1200.0);
      expect(bargainedItem.hasBargainPrice, isTrue);
      expect(bargainedItem.effectivePrice, 1200.0);
      expect(bargainedItem.itemTotal, 2400.0);
    });

    test('Razorpay Route 90/10 split payment calculations', () {
      const subtotal = 2000.0;
      const commissionPercentage = 10.0;

      final amountInPaise = (subtotal * 100).round();
      final commissionPaise = ((amountInPaise * commissionPercentage) / 100).round();
      final sellerTransferPaise = amountInPaise - commissionPaise;

      expect(amountInPaise, 200000); // 2,00,000 paise (₹2,000)
      expect(commissionPaise, 20000); // ₹200 platform commission (10%)
      expect(sellerTransferPaise, 180000); // ₹1,800 seller payout (90%)
      expect(sellerTransferPaise + commissionPaise, amountInPaise);
    });

    test('Bargain state machine transitions', () {
      final bargain = Bargain(
        id: 'bg-1',
        consumerId: 'c-1',
        sellerId: 's-1',
        productId: 'p-1',
        variantId: 'v-1',
        status: BargainStatus.open,
        consumerOffer: 1200.0,
        basePrice: 1600.0,
        minBargainPrice: 1000.0,
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(bargain.isActive, isTrue);
      expect(bargain.isTerminal, isFalse);

      final countered = bargain.copyWith(
        status: BargainStatus.countered,
        counterOffer: 1350.0,
      );
      expect(countered.isActive, isTrue);
      expect(countered.counterOffer, 1350.0);

      final accepted = countered.copyWith(
        status: BargainStatus.accepted,
        agreedPrice: 1350.0,
      );
      expect(accepted.isActive, isFalse);
      expect(accepted.isTerminal, isTrue);
      expect(accepted.agreedPrice, 1350.0);
    });

    test('OrderModel generates 4-digit Delivery OTP and validates progress indices', () {
      final order = OrderModel(
        id: 'ord-101',
        orderNumber: 'PRD-2026-9999',
        consumerId: 'c-1',
        shopId: 's-1',
        shopName: 'Heritage Silk',
        items: [],
        subtotal: 1500.0,
        totalAmount: 1559.0,
        status: OrderStatus.outForDelivery,
        deliveryAddress: AddressModel(
          id: 'addr-1',
          userId: 'c-1',
          fullName: 'Test User',
          phone: '9876543210',
          addressLine1: 'Johari Bazaar',
          pincode: '302001',
        ),
        deliveryOtp: '5829',
        createdAt: DateTime(2026, 9, 18),
        updatedAt: DateTime(2026, 9, 18),
      );

      expect(order.deliveryOtp.length, 4);
      expect(order.statusStepIndex, 3); // Out for Delivery is step index 3
      expect(order.statusLabel, 'Out for Delivery');
    });
  });
}
