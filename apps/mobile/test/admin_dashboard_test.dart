import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paridhan_mobile/main_consumer.dart';
import 'package:paridhan_mobile/core/constants/app_constants.dart';
import 'package:paridhan_mobile/features/auth/domain/user_profile.dart';
import 'package:paridhan_mobile/features/auth/presentation/auth_state.dart';
import 'package:paridhan_mobile/features/admin/data/admin_repository.dart';
import 'package:paridhan_mobile/features/admin/domain/admin_metrics_model.dart';
import 'package:paridhan_mobile/features/admin/presentation/admin_boutique_verification_screen.dart';
import 'package:paridhan_mobile/features/admin/presentation/admin_analytics_screen.dart';
import 'package:paridhan_mobile/features/admin/presentation/admin_disputes_screen.dart';
import 'package:paridhan_mobile/features/admin/presentation/admin_controller.dart';
import 'test_utils.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  group('Super Admin Control Center & Production Analytics Tests', () {
    test('AdminMetricsModel computes GMV, net platform earnings, and masked KYC data', () {
      const gmv = 200000.0;
      const commissionRate = 10.0;
      const commission = gmv * (commissionRate / 100);
      const adRevenue = 5000.0;
      const deliveryFee = 4000.0;
      const gateway = gmv * 0.02; // 4000.0
      const refunds = 2000.0;

      final metrics = AdminMetricsModel(
        totalGmv: gmv,
        platformCommissionRate: commissionRate,
        platformRevenue: commission,
        totalCommissionEarned: commission,
        totalAdRevenue: adRevenue,
        totalDeliveryCharges: deliveryFee,
        gatewayCharges: gateway,
        totalRefundsAmount: refunds,
        totalOrdersCount: 150,
        activeBoutiquesCount: 45,
        pendingKycCount: 3,
        onDutyDeliveryFleetCount: 12,
      );

      expect(metrics.totalGmv, 200000.0);
      expect(metrics.platformRevenue, 20000.0);
      expect(metrics.grossSales, 200000.0);
      expect(metrics.sellerEarnings, 200000.0 - 20000.0 - (2000.0 * 0.90));
      expect(metrics.avgOrderValue, 200000.0 / 150);
      expect(metrics.netPlatformEarnings, (20000.0 + 5000.0 + (4000.0 * 0.2) - 4000.0 - (2000.0 * 0.10)));

      final kycItem = BoutiqueVerificationItem(
        id: 'k-1',
        shopName: 'Jaipur Silks',
        ownerName: 'Manish Rathore',
        ownerEmail: 'manish@silk.in',
        ownerPhone: '+91 98290 12345',
        gstin: '08ABCDE1234F1Z5',
        address: 'Bapu Bazaar',
        cityZone: 'Pink City',
        panNumber: 'ABCDE1234F',
        aadhaarNumber: '123456789012',
        bankAccountNumber: '987654321098',
        status: KycStatus.pending,
        submittedAt: DateTime(2026, 1, 1),
      );

      // Verify default security data masking
      expect(kycItem.maskedPan, 'AB******4F');
      expect(kycItem.maskedAadhaar, '**** **** 9012');
      expect(kycItem.maskedBankAccount, '******1098');
    });

    test('AdminRepository executes metrics, KYC status with audit log, and dispute refund', () async {
      final repo = AdminRepository();

      // 1. Get Platform Metrics
      final metrics = await repo.getPlatformMetrics();
      expect(metrics.totalGmv, greaterThan(0));
      expect(metrics.zoneMetrics.isNotEmpty, isTrue);
      expect(metrics.pendingBoutiques.isNotEmpty, isTrue);
      expect(metrics.orders.isNotEmpty, isTrue);
      expect(metrics.sellers.isNotEmpty, isTrue);
      expect(metrics.customers.isNotEmpty, isTrue);
      expect(metrics.auditLogs.isNotEmpty, isTrue);

      // 2. Approve Boutique KYC with audit log
      final boutiqueToApprove = metrics.pendingBoutiques.first;
      final approveSuccess = await repo.updateBoutiqueKycStatus(
        boutiqueId: boutiqueToApprove.id,
        status: KycStatus.approved,
        verificationNotes: 'Verified via physical store inspection.',
      );
      expect(approveSuccess, isTrue);

      // 3. Resolve Dispute Ticket with Refund
      final dispute = metrics.disputes.first;
      final disputeSuccess = await repo.resolveDisputeTicket(
        disputeId: dispute.id,
        isRefundApproved: true,
      );
      expect(disputeSuccess, isTrue);

      // 4. Update Order Status
      final order = metrics.orders.first;
      final orderSuccess = await repo.updateOrderStatus(
        orderId: order.id,
        newStatus: 'delivered',
      );
      expect(orderSuccess, isTrue);
    });

    testWidgets('Renders Admin Dashboard Control Center with Tabs and Business KPIs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => _MockAdminAuthNotifier(
                  const UserProfile(
                    id: 'admin-01',
                    role: UserRole.admin,
                    fullName: 'Super Admin Jaipur',
                  ),
                )),
            adminProvider.overrideWith(() => _MockAdminController()),
          ],
          child: const ParidhanApp(flavorTitle: 'Admin Test'),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('PARIDHAN'), findsWidgets);
      expect(find.text('Admin Control Center'), findsWidgets);
      expect(find.text('Total Sales (GMV)'), findsOneWidget);
      expect(find.text('Platform Revenue'), findsOneWidget);
      expect(find.text('Total Orders'), findsWidgets);
    });

    testWidgets('Renders Admin Boutique Verification Screen with Sensitive Data Masking', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminProvider.overrideWith(() => _MockAdminController()),
          ],
          child: const MaterialApp(
            home: AdminBoutiqueVerificationScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Boutique KYC Verification'), findsOneWidget);
      expect(find.textContaining('Pending Review'), findsWidgets);
      expect(find.text('Financial & Identity Documents (Protected)'), findsWidgets);
      expect(find.text('Reveal'), findsWidgets);
    });

    testWidgets('Renders Admin Analytics and Disputes Screens', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1. Analytics Screen
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminProvider.overrideWith(() => _MockAdminController()),
          ],
          child: const MaterialApp(
            home: AdminAnalyticsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('City & Financial Analytics (Jaipur)'), findsOneWidget);
      expect(find.text('Platform Financial Breakdown'), findsOneWidget);
      expect(find.text('Jaipur Hyperlocal Zones'), findsOneWidget);

      // 2. Disputes Screen
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminProvider.overrideWith(() => _MockAdminController()),
          ],
          child: const MaterialApp(
            home: AdminDisputesScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Disputes & Refund Escalations'), findsOneWidget);
      expect(find.text('Approve Refund'), findsWidgets);
    });
  });
}

class _MockAdminController extends AdminNotifier {
  @override
  AdminDashboardState build() {
    return AdminDashboardState(
      isLoading: false,
      metrics: AdminMetricsModel(
        totalGmv: 184500.0,
        platformRevenue: 18450.0,
        pendingBoutiques: [
          BoutiqueVerificationItem(
            id: 'k-1',
            shopName: 'Jaipur Silks',
            ownerName: 'Manish Rathore',
            ownerEmail: 'manish@silk.in',
            ownerPhone: '+91 98290 12345',
            gstin: '08ABCDE1234F1Z5',
            address: 'Bapu Bazaar',
            cityZone: 'Pink City',
            status: KycStatus.pending,
            submittedAt: DateTime.now(),
          ),
        ],
        disputes: [
          DisputeTicket(
            id: 'disp-01',
            orderNumber: 'PRD-ORD-881',
            consumerName: 'Pooja',
            boutiqueName: 'Jaipur Silks',
            issueReason: 'Damaged item',
            amount: 1499.0,
            isResolved: false,
            createdAt: DateTime.now(),
          ),
        ],
        zoneMetrics: const [
          CityZoneMetric(
            zoneName: 'Pink City',
            activeBoutiques: 12,
            totalOrders: 40,
            gmvAmount: 48000.0,
            platformRevenue: 4800.0,
          ),
        ],
      ),
    );
  }
}

class _MockAdminAuthNotifier extends AuthNotifier {
  final UserProfile mockUser;
  _MockAdminAuthNotifier(this.mockUser);

  @override
  AuthState build() {
    return AuthState(
      isLoading: false,
      isGuest: false,
      user: mockUser,
    );
  }
}
