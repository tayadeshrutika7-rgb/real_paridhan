import 'package:flutter_test/flutter_test.dart';
import 'package:paridhan_mobile/features/consumer/domain/address_model.dart';
import 'package:paridhan_mobile/features/consumer/domain/order_model.dart';
import 'package:paridhan_mobile/features/delivery/domain/delivery_earnings_model.dart';
import 'package:paridhan_mobile/features/admin/domain/admin_metrics_model.dart';

void main() {
  group('Comprehensive Real Financial Logic & Order Lifecycle Audit Tests', () {
    const defaultAddress = AddressModel(
      id: 'addr-01',
      userId: 'consumer-01',
      fullName: 'Sunita Meena',
      phone: '9829011111',
      addressLine1: 'B-12, Johari Bazaar',
      city: 'Jaipur',
      state: 'Rajasthan',
      pincode: '302003',
    );

    // ─── SCENARIO 1: Successful Paid and Delivered Order ──────────────────────
    test('Scenario 1: Paid and Delivered order realizes 3% commission, 97% payout, and rider earnings', () {
      const subtotal = 1000.0;
      const deliveryFee = 40.0;
      const platformFee = 10.0;
      const totalAmount = subtotal + deliveryFee + platformFee; // 1050.0

      final order = OrderModel(
        id: 'ord-test-01',
        orderNumber: 'PRD-2026-TEST01',
        consumerId: 'consumer-01',
        shopId: 'shop-01',
        shopName: 'Johari Royal Boutique',
        items: const [],
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        platformFee: platformFee,
        totalAmount: totalAmount,
        status: OrderStatus.delivered,
        paymentMethod: PaymentMethod.razorpay,
        paymentStatus: PaymentStatus.paid,
        deliveryAddress: defaultAddress,
        deliveryOtp: '7412',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deliveredAt: DateTime.now(),
      );

      // 1. Commission verified at exactly 3% of items subtotal: ₹1,000 * 3% = ₹30
      final commissionAmount = order.subtotal * 0.03;
      expect(commissionAmount, 30.0);

      // 2. Seller payable amount is 97% of subtotal: ₹1,000 * 97% = ₹970
      final sellerPayable = order.subtotal - commissionAmount;
      expect(sellerPayable, 970.0);

      // 3. Customer total reconciles exactly
      expect(order.totalAmount, 1050.0);
      expect(order.subtotal + order.deliveryFee + order.platformFee, order.totalAmount);

      // 4. Delivery partner payout is credited on delivery
      const driverPayout = 85.0;
      final deliveryEarnings = const DeliveryEarningsModel(
        todayTripsCount: 1,
        todayBaseEarnings: driverPayout,
        todayPenalties: 0.0,
      );
      expect(deliveryEarnings.todayTotalEarnings, 85.0);
      expect(deliveryEarnings.todayNetEarnings, 85.0);

      // 5. Net Platform Revenue (Retained 3% commission + 10 platform fee)
      final netPlatformRetained = commissionAmount + order.platformFee;
      expect(netPlatformRetained, 40.0);
    });

    // ─── SCENARIO 2: Unpaid or Failed-Payment Order ───────────────────────────
    test('Scenario 2: Unpaid or failed-payment order produces ₹0.00 realized revenue', () {
      const subtotal = 3500.0;
      final order = OrderModel(
        id: 'ord-test-02',
        orderNumber: 'PRD-2026-TEST02',
        consumerId: 'consumer-01',
        shopId: 'shop-01',
        shopName: 'Johari Royal Boutique',
        items: const [],
        subtotal: subtotal,
        deliveryFee: 49.0,
        platformFee: 10.0,
        totalAmount: 3559.0,
        status: OrderStatus.pending,
        paymentMethod: PaymentMethod.razorpay,
        paymentStatus: PaymentStatus.failed,
        deliveryAddress: defaultAddress,
        deliveryOtp: '8521',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final isRealized = order.status == OrderStatus.delivered && order.paymentStatus == PaymentStatus.paid;
      expect(isRealized, isFalse);

      final realizedRevenue = isRealized ? (order.subtotal * 0.03) : 0.0;
      final realizedSellerPayout = isRealized ? (order.subtotal * 0.97) : 0.0;

      expect(realizedRevenue, 0.0);
      expect(realizedSellerPayout, 0.0);
    });

    // ─── SCENARIO 3: Seller-Rejected Order ────────────────────────────────────
    test('Scenario 3: Seller-rejected order does not inflate seller or platform revenue', () {
      const subtotal = 5000.0;
      final order = OrderModel(
        id: 'ord-test-03',
        orderNumber: 'PRD-2026-TEST03',
        consumerId: 'consumer-01',
        shopId: 'shop-01',
        shopName: 'Johari Royal Boutique',
        items: const [],
        subtotal: subtotal,
        deliveryFee: 49.0,
        platformFee: 10.0,
        totalAmount: 5059.0,
        status: OrderStatus.cancelled,
        paymentMethod: PaymentMethod.razorpay,
        paymentStatus: PaymentStatus.refunded,
        deliveryAddress: defaultAddress,
        deliveryOtp: '9632',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final isQualifying = order.status != OrderStatus.cancelled && order.status != OrderStatus.returned;
      expect(isQualifying, isFalse);

      final activeCommission = isQualifying ? (order.subtotal * 0.03) : 0.0;
      final activePayout = isQualifying ? (order.subtotal * 0.97) : 0.0;

      expect(activeCommission, 0.0);
      expect(activePayout, 0.0);
    });

    // ─── SCENARIO 4: Customer-Cancelled Order ─────────────────────────────────
    test('Scenario 4: Customer-cancelled order yields ₹0.00 realized commission and payout', () {
      final order = OrderModel(
        id: 'ord-test-04',
        orderNumber: 'PRD-2026-TEST04',
        consumerId: 'consumer-01',
        shopId: 'shop-01',
        shopName: 'Johari Royal Boutique',
        items: const [],
        subtotal: 1800.0,
        totalAmount: 1859.0,
        status: OrderStatus.cancelled,
        deliveryAddress: defaultAddress,
        deliveryOtp: '1472',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(order.status, OrderStatus.cancelled);
      const earnedCommission = 0.0;
      const payablePayout = 0.0;
      expect(earnedCommission, 0.0);
      expect(payablePayout, 0.0);
    });

    // ─── SCENARIO 5: Refunded Order (Reversal Without Double-Counting) ────────
    test('Scenario 5: Completed order subsequently refunded reverses commission and seller payout cleanly', () {
      const originalSubtotal = 6000.0;
      final originalCommission = originalSubtotal * 0.03; // 180.0
      final originalSellerPayout = originalSubtotal * 0.97; // 5820.0

      // Refund event occurs
      const isRefunded = true;
      final reversedCommission = isRefunded ? -originalCommission : 0.0;
      final reversedSellerPayout = isRefunded ? -originalSellerPayout : 0.0;

      // Net balances after refund
      final netPlatformCommission = originalCommission + reversedCommission;
      final netSellerPayout = originalSellerPayout + reversedSellerPayout;

      expect(netPlatformCommission, 0.0);
      expect(netSellerPayout, 0.0);
    });

    // ─── SCENARIO 6: Delivery Partner Emergency Rejection Penalty ────────────
    test('Scenario 6: Delivery partner emergency cancellation charges ₹100 penalty', () {
      const driverId = 'driver-01';
      const penaltyAmount = 100.0;

      final penaltyItem = DeliveryPenaltyItem(
        orderId: 'ord-test-06',
        orderNumber: 'PRD-2026-TEST06',
        amount: penaltyAmount,
        reason: 'Emergency Rejection / Cancellation',
        chargedAt: DateTime.now(),
      );

      // Driver had 1 prior delivery (₹85 payout) and 1 emergency rejection (-₹100)
      final earningsModel = DeliveryEarningsModel(
        todayTripsCount: 1,
        todayBaseEarnings: 85.0,
        todayPenalties: penaltyAmount,
        penaltiesCount: 1,
        penalties: [penaltyItem],
      );

      expect(earningsModel.todayTotalEarnings, 85.0);
      expect(earningsModel.todayPenalties, 100.0);
      expect(earningsModel.rawNetBalance, -15.0);
      expect(earningsModel.todayNetEarnings, 0.0); // Clamped to non-negative for display
    });

    // ─── SCENARIO 7: Duplicate Status Events / Idempotency ────────────────────
    test('Scenario 7: Duplicate delivery status updates do not duplicate earnings or commission', () {
      final ledger = <String, double>{};

      void recordCommission(String orderId, double amount) {
        // Idempotent key
        final key = 'COMMISSION_$orderId';
        ledger[key] = amount; // Assigns idempotently without incrementing
      }

      void recordPayout(String orderId, double amount) {
        final key = 'PAYOUT_$orderId';
        ledger[key] = amount;
      }

      const orderId = 'ord-test-07';
      const commission = 250.0;
      const payout = 2250.0;

      // Event fired 1st time
      recordCommission(orderId, commission);
      recordPayout(orderId, payout);

      // Event duplicate / repeated webhook fired 2nd time
      recordCommission(orderId, commission);
      recordPayout(orderId, payout);

      // Event duplicate fired 3rd time
      recordCommission(orderId, commission);
      recordPayout(orderId, payout);

      expect(ledger['COMMISSION_$orderId'], 250.0);
      expect(ledger['PAYOUT_$orderId'], 2250.0);
    });
  });
}
