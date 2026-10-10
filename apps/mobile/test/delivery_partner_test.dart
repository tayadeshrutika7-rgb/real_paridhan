import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paridhan_mobile/main_consumer.dart';
import 'package:paridhan_mobile/core/constants/app_constants.dart';
import 'package:paridhan_mobile/core/routing/app_router.dart';
import 'package:paridhan_mobile/features/auth/domain/user_profile.dart';
import 'package:paridhan_mobile/features/auth/presentation/auth_state.dart';
import 'package:paridhan_mobile/features/delivery/data/delivery_repository.dart';
import 'package:paridhan_mobile/features/delivery/domain/delivery_task_model.dart';
import 'package:paridhan_mobile/features/delivery/domain/delivery_earnings_model.dart';
import 'package:paridhan_mobile/features/delivery/domain/delivery_route_batch_model.dart';
import 'package:paridhan_mobile/features/delivery/presentation/delivery_earnings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_utils.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = TestHttpOverrides();
  });

  group('Phase 6: Hyperlocal Delivery Partner & Dispatch Engine Tests', () {
    setUp(() {
      DeliveryRepository.resetSimulatedState();
    });
    test('DeliveryTaskModel distance and step progression calculations', () {
      const task = DeliveryTaskModel(
        id: 'task-01',
        orderId: 'ord-01',
        orderNumber: 'PRD-2026-1234',
        status: DeliveryTaskStatus.accepted,
        shopId: 'shop-01',
        shopName: 'Jaipur Handlooms',
        shopAddress: 'Johari Bazaar',
        shopPhone: '9829012345',
        shopLat: 26.9124,
        shopLng: 75.7873,
        distanceToShopKm: 1.5,
        customerName: 'Aarav Sharma',
        customerPhone: '9876543210',
        dropAddress: 'C-Scheme, Jaipur',
        dropLat: 26.9150,
        dropLng: 75.7900,
        distanceToCustomerKm: 3.5,
        deliveryPayout: 90.0,
        orderTotalAmount: 2000.0,
        isCod: true,
        codCashToCollect: 2000.0,
        items: [
          DeliveryTaskItem(
            title: 'Kurta',
            size: 'M',
            color: 'Blue',
            quantity: 1,
            price: 2000.0,
          ),
        ],
        deliveryOtp: '4829',
      );

      expect(task.totalDistanceKm, 5.0);
      expect(task.progressStepIndex, 0); // Heading to shop
      expect(task.isCod, isTrue);
      expect(task.codCashToCollect, 2000.0);

      final pickedUpTask = task.copyWith(status: DeliveryTaskStatus.pickedUp);
      expect(pickedUpTask.progressStepIndex, 2); // On the way to customer
    });

    test('DeliveryEarningsModel calculates total earnings, deducts penalties and tracks COD remittance', () {
      final penalties = <DeliveryPenaltyItem>[
        DeliveryPenaltyItem(
          orderId: 'ord-01',
          orderNumber: 'PRD-2026-101',
          amount: 100.0,
          reason: 'Emergency Cancellation: Bike Breakdown',
          chargedAt: DateTime.now(),
        ),
      ];

      final earnings = DeliveryEarningsModel(
        todayTripsCount: 5,
        todayBaseEarnings: 400.0,
        todayDistanceIncentive: 60.0,
        todayTips: 40.0,
        todayCodCollected: 3500.0,
        pendingCodRemittance: 3500.0,
        totalDistanceTodayKm: 22.5,
        todayPenalties: 100.0,
        penaltiesCount: 1,
        penalties: penalties,
      );

      expect(earnings.todayTotalEarnings, 500.0); // 400 + 60 + 40
      expect(earnings.todayPenalties, 100.0);
      expect(earnings.todayNetEarnings, 400.0); // 500 - 100
      expect(earnings.rawNetBalance, 400.0);
      expect(earnings.pendingCodRemittance, 3500.0);
      expect(earnings.todayTripsCount, 5);
      expect(earnings.penalties.length, 1);
      expect(earnings.penalties.first.amount, 100.0);
    });

    test('DeliveryRepository duty toggle, radar dispatch, pickup, and OTP validation', () async {
      final repo = DeliveryRepository();
      const driverId = 'driver-test-01';

      // 1. Toggle duty online
      final isOnline = await repo.setDutyStatus(isOnline: true, driverId: driverId);
      expect(isOnline, isTrue);

      // 2. Fetch incoming requests
      final incoming = await repo.getIncomingRequests(driverId: driverId);
      expect(incoming.isNotEmpty, isTrue);
      final firstTask = incoming.first;

      // 3. Accept Task
      final accepted = await repo.acceptTask(taskId: firstTask.id, driverId: driverId);
      expect(accepted, isNotNull);
      expect(accepted!.status, DeliveryTaskStatus.accepted);

      // 4. Confirm Store Pickup
      final pickedUp = await repo.confirmPickup(firstTask.id);
      expect(pickedUp, isNotNull);
      expect(pickedUp!.status, DeliveryTaskStatus.pickedUp);

      // 5. Verify Invalid OTP
      final wrongOtpSuccess = await repo.verifyOtpAndCompleteDelivery(
        taskId: firstTask.id,
        orderId: firstTask.orderId,
        inputOtp: '0000',
        isCod: firstTask.isCod,
        codCollectedAmount: firstTask.codCashToCollect,
      );
      expect(wrongOtpSuccess, isFalse);

      // 6. Verify Correct OTP
      final correctOtpSuccess = await repo.verifyOtpAndCompleteDelivery(
        taskId: firstTask.id,
        orderId: firstTask.orderId,
        inputOtp: firstTask.deliveryOtp,
        isCod: firstTask.isCod,
        codCollectedAmount: firstTask.codCashToCollect,
      );
      expect(correctOtpSuccess, isTrue);
    });

    test('Delivery emergency rejection charges ₹100 penalty and updates partner earnings', () async {
      final repo = DeliveryRepository();
      const driverId = 'driver-test-emergency';

      // 1. Accept a trip
      final incoming = await repo.getIncomingRequests(driverId: driverId);
      final task = incoming.first;
      await repo.acceptTask(taskId: task.id, driverId: driverId);

      // Verify active trip exists
      final activeTripBefore = await repo.getActiveTrip(driverId);
      expect(activeTripBefore, isNotNull);

      // 2. Reject trip on emergency basis (personal reason)
      final success = await repo.rejectDeliveryEmergency(
        taskId: task.id,
        orderId: task.orderId,
        driverId: driverId,
        reason: 'Personal bike breakdown',
      );
      expect(success, isTrue);

      // 3. Active trip must be cleared
      final activeTripAfter = await repo.getActiveTrip(driverId);
      expect(activeTripAfter, isNull);

      // 4. Partner's earnings must reflect the ₹100 penalty
      final earnings = await repo.getEarningsSummary(driverId);
      expect(earnings.todayPenalties, greaterThanOrEqualTo(100.0));
      expect(earnings.penaltiesCount, greaterThanOrEqualTo(1));
      expect(earnings.penalties.any((p) => p.amount == 100.0 && p.reason.contains('bike breakdown')), isTrue);
    });

    test('Reporting customer unavailable records issue without charging delivery partner', () async {
      final repo = DeliveryRepository();
      const driverId = 'driver-test-unavailable';

      // 1. Accept a trip
      final incoming = await repo.getIncomingRequests(driverId: driverId);
      final task = incoming.last;
      await repo.acceptTask(taskId: task.id, driverId: driverId);

      // 2. Report customer unavailable
      final success = await repo.reportCustomerUnavailable(
        taskId: task.id,
        orderId: task.orderId,
        driverId: driverId,
        notes: 'Door locked, phone switched off after 3 attempts',
      );
      expect(success, isTrue);

      // 3. Active trip is cleared
      final activeTripAfter = await repo.getActiveTrip(driverId);
      expect(activeTripAfter, isNull);

      // 4. Zero penalty must be charged
      final earnings = await repo.getEarningsSummary(driverId);
      expect(earnings.todayPenalties, 0.0);
      expect(earnings.penaltiesCount, 0);
    });

    test('DeliveryRouteBatchModel finds same-path batches and checks on-the-way orders', () {
      final incoming = [
        const DeliveryTaskModel(
          id: 'task-101',
          orderId: 'ord-101',
          orderNumber: 'PRD-2026-101',
          status: DeliveryTaskStatus.pending,
          shopId: 'shop-01',
          shopName: 'Jaipur Handlooms',
          shopAddress: 'Johari Bazaar',
          shopPhone: '9829012345',
          shopLat: 26.9196,
          shopLng: 75.8267,
          distanceToShopKm: 1.4,
          customerName: 'Pooja Verma',
          customerPhone: '9876543210',
          dropAddress: 'C-Scheme, Jaipur',
          dropLat: 26.9124,
          dropLng: 75.7873,
          distanceToCustomerKm: 3.2,
          deliveryPayout: 85.0,
          orderTotalAmount: 1899.0,
          isCod: false,
          codCashToCollect: 0.0,
          items: [
            DeliveryTaskItem(
              title: 'Anarkali Kurta',
              size: 'M',
              color: 'Blue',
              quantity: 1,
              price: 1899.0,
            ),
          ],
          deliveryOtp: '4829',
        ),
        const DeliveryTaskModel(
          id: 'task-102',
          orderId: 'ord-102',
          orderNumber: 'PRD-2026-102',
          status: DeliveryTaskStatus.pending,
          shopId: 'shop-02',
          shopName: 'Rajputana Silks',
          shopAddress: 'Bapu Bazaar',
          shopPhone: '9829044556',
          shopLat: 26.9150,
          shopLng: 75.8200,
          distanceToShopKm: 2.1,
          customerName: 'Rohit Khandelwal',
          customerPhone: '9829099887',
          dropAddress: 'C-Scheme, Jaipur',
          dropLat: 26.9140,
          dropLng: 75.7890,
          distanceToCustomerKm: 3.4,
          deliveryPayout: 110.0,
          orderTotalAmount: 2450.0,
          isCod: true,
          codCashToCollect: 2450.0,
          items: [
            DeliveryTaskItem(
              title: 'Dupatta Set',
              size: 'L',
              color: 'Maroon',
              quantity: 1,
              price: 2450.0,
            ),
          ],
          deliveryOtp: '9103',
        ),
      ];

      final batches = DeliveryRouteBatchModel.findSamePathBatches(incoming);
      expect(batches.isNotEmpty, isTrue);
      final batch = batches.first;
      expect(batch.orderCount, 2);
      expect(batch.totalPayout, 195.0); // 85 + 110
      expect(batch.isEasyToCarry, isTrue);
      expect(batch.detourDistanceKm, lessThan(3.0));

      final onTheWay = DeliveryRouteBatchModel.checkOnTheWayOrder(
        activeTrip: incoming.first,
        incomingOrders: incoming,
      );
      expect(onTheWay, isNotNull);
      expect(onTheWay!.extraEarnings, 110.0);
    });

    testWidgets('Renders Delivery Partner Radar and Overview', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appFlavorProvider.overrideWith(() => FlavorNotifier(AppFlavor.delivery)),
            authProvider.overrideWith(() => _MockDeliveryAuthNotifier(
                  const UserProfile(
                    id: 'driver-test-01',
                    role: UserRole.delivery,
                    fullName: 'Vikram Singh (Fleet)',
                  ),
                )),
          ],
          child: const ParidhanApp(flavorTitle: 'Delivery Test'),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Delivery Partner Radar'), findsOneWidget);
      expect(find.text('Vikram Singh (Fleet)'), findsOneWidget);
      expect(find.text('Nearby Order Radar'), findsOneWidget);
      expect(find.text('Accept Order'), findsWidgets);
      expect(find.textContaining('SAME-PATH BUNDLE'), findsWidgets);
    });

    testWidgets('Renders Delivery Earnings & COD Remittance Screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeliveryEarningsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Earnings & COD Settlement'), findsOneWidget);
      expect(find.text('Today\'s Net Payout'), findsOneWidget);
      expect(find.text('Cash on Delivery (COD) Held'), findsOneWidget);
      expect(find.text('Trip History'), findsOneWidget);
    });
  });
}

class _MockDeliveryAuthNotifier extends AuthNotifier {
  final UserProfile mockUser;
  _MockDeliveryAuthNotifier(this.mockUser);

  @override
  AuthState build() {
    return AuthState(
      isLoading: false,
      isGuest: false,
      user: mockUser,
    );
  }
}
