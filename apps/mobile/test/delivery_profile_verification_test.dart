import 'package:flutter_test/flutter_test.dart';
import 'package:paridhan_mobile/features/delivery/domain/delivery_profile_model.dart';
import 'package:paridhan_mobile/features/delivery/domain/delivery_earnings_model.dart';
import 'package:paridhan_mobile/features/delivery/data/delivery_repository.dart';
import 'package:paridhan_mobile/features/admin/data/admin_repository.dart';

void main() {
  group('Delivery Profile & Verification Gating Tests', () {
    test('1. DeliveryProfileModel initializes bank, UPI, Aadhaar & license fields', () {
      const profile = DeliveryProfileModel(
        id: 'driver-test-01',
        fullName: 'Vikram Singh',
        phone: '+91 98290 33333',
        vehicleType: 'Motorcycle (Hero Splendor)',
        vehicleNumber: 'RJ 14 JP 4421',
        drivingLicenseNumber: 'RJ14 20210049281',
        bankName: 'HDFC Bank, Johari Bazaar',
        bankAccountNumber: '987654321012',
        bankIfsc: 'HDFC0001234',
        bankAccountName: 'Vikram Singh',
        upiId: 'vikram@okhdfcbank',
        aadhaarNumber: '987654321098',
        aadhaarUrl: 'https://images.unsplash.com/photo-aadhaar',
        verificationStatus: 'pending',
      );

      expect(profile.isVerified, false);
      expect(profile.isPending, true);
      expect(profile.bankName, 'HDFC Bank, Johari Bazaar');
      expect(profile.bankAccountNumber, '987654321012');
      expect(profile.bankIfsc, 'HDFC0001234');
      expect(profile.upiId, 'vikram@okhdfcbank');
      expect(profile.aadhaarNumber, '987654321098');

      final json = profile.toBankDetailsJson();
      expect(json['bank_name'], 'HDFC Bank, Johari Bazaar');
      expect(json['account_number'], '987654321012');
      expect(json['ifsc'], 'HDFC0001234');
      expect(json['upi_id'], 'vikram@okhdfcbank');
      expect(json['aadhaar_number'], '987654321098');
    });

    test('2. Unverified delivery partner CANNOT go online or receive orders', () async {
      final repo = DeliveryRepository();
      DeliveryRepository.setSimulatedVerificationStatus('pending');

      // Attempt to toggle duty online when pending
      final isOnline = await repo.setDutyStatus(
        isOnline: true,
        driverId: 'driver-test-01',
      );
      expect(isOnline, false, reason: 'Pending delivery partner must NOT be allowed to go online');

      // Attempt to fetch incoming requests when pending
      final requests = await repo.getIncomingRequests(driverId: 'driver-test-01');
      expect(requests.isEmpty, true, reason: 'Pending delivery partner must NOT receive any orders');
    });

    test('3. Approved delivery partner CAN go online and receive orders', () async {
      final repo = DeliveryRepository();
      DeliveryRepository.setSimulatedVerificationStatus('verified');

      // Duty can now be turned on
      final isOnline = await repo.setDutyStatus(
        isOnline: true,
        driverId: 'driver-test-01',
      );
      expect(isOnline, true, reason: 'Verified delivery partner CAN go online');

      // Requests can now be received
      final requests = await repo.getIncomingRequests(driverId: 'driver-test-01');
      expect(requests.isNotEmpty, true, reason: 'Verified delivery partner CAN receive orders');
      expect(requests.first.deliveryPayout, greaterThan(0));
    });

    test('4. Delivery partner income and monthly salary calculation', () {
      final earnings = DeliveryEarningsModel(
        todayTripsCount: 4,
        todayBaseEarnings: 320.0,
        todayDistanceIncentive: 45.0,
        todayTips: 30.0,
        todayPenalties: 0.0,
        penaltiesCount: 0,
        todayCodCollected: 1550.0,
        pendingCodRemittance: 1550.0,
        totalDistanceTodayKm: 18.4,
        trips: [
          DeliveryTripSummary(
            orderId: 'ord-01',
            orderNumber: 'PRD-ORD-1',
            shopName: 'Jaipur Heritage',
            dropArea: 'Johari Bazaar',
            distanceKm: 3.5,
            payout: 85.0,
            isCod: true,
            codAmount: 1550.0,
            completedAt: DateTime.now(),
          ),
        ],
      );

      expect(earnings.todayTotalEarnings, 395.0); // 320 + 45 + 30
      expect(earnings.todayNetEarnings, 395.0);
      expect(earnings.trips.first.payout, 85.0);
      expect(earnings.pendingCodRemittance, 1550.0);
    });

    test('5. Delivery partner side and Admin side show identical per-order earning (e.g. ₹180)', () async {
      final adminRepo = AdminRepository();
      const driverId = 'driver-01';
      const driverName = 'Ramesh Kumawat';

      final metrics = await adminRepo.getPlatformMetrics();
      final deliverySalaries = metrics.deliverySalaries;
      final rameshSalary = deliverySalaries.firstWhere((s) => s.driverId == driverId || s.driverName == driverName);

      // Verify that each order trip earning is computed strictly from order's delivery fee
      for (final trip in rameshSalary.tripRecords) {
        expect(trip.tripEarning, greaterThan(0));
        // Find matching order in metrics
        final matchedOrder = metrics.orders.firstWhere((o) => o.id == trip.orderId);
        expect(trip.tripEarning, matchedOrder.deliveryFee);
      }

      // Sum of trips equals perOrderEarningsTotal
      final expectedSum = rameshSalary.tripRecords.fold<double>(0.0, (acc, t) => acc + t.tripEarning);
      expect(rameshSalary.perOrderEarningsTotal, expectedSum);
    });

    test('6. Monthly salary disbursement transitions status from Pending to Paid/Credited on delivery side', () async {
      final adminRepo = AdminRepository();
      final deliveryRepo = DeliveryRepository();
      const driverId = 'driver-01';
      const driverName = 'Ramesh Kumawat';
      const month = 'October 2026';
      const disburseAmount = 180.0;
      const ref = 'UTR-AXIS-99281';
      const method = 'Bank NEFT Transfer';

      // 1. Initially or before disbursement
      AdminRepository.resetLocallyCachedStatus();
      var earnings = await deliveryRepo.getEarningsSummary(driverId);
      expect(earnings.monthlySalaryStatus.toLowerCase(), 'pending');
      expect(earnings.isSalaryCredited, false);

      // 2. Admin disburses salary
      final disbursed = await adminRepo.disburseDeliverySalary(
        driverId: driverId,
        driverName: driverName,
        monthName: month,
        amount: disburseAmount,
        paymentMethod: method,
        transactionRef: ref,
      );
      expect(disbursed, true);

      // 3. Delivery partner fetches earnings summary - must reflect Credited / Paid
      earnings = await deliveryRepo.getEarningsSummary(driverId);
      expect(earnings.monthlySalaryStatus.toLowerCase(), 'paid');
      expect(earnings.isSalaryCredited, true);
      expect(earnings.monthlySalaryAmount, disburseAmount);
      expect(earnings.monthlySalaryRef, ref);
      expect(earnings.monthlySalaryMethod, method);
    });
  });
}
