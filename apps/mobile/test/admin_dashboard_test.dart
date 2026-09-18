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
import 'test_utils.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  group('Phase 7: Super Admin Dashboard & City Analytics Tests', () {
    test('AdminMetricsModel computes 10% platform revenue and zone aggregations', () {
      const gmv = 200000.0;
      const commissionRate = 10.0;
      const revenue = gmv * (commissionRate / 100);

      const metrics = AdminMetricsModel(
        totalGmv: gmv,
        platformCommissionRate: commissionRate,
        platformRevenue: revenue,
        totalOrdersCount: 150,
        activeBoutiquesCount: 45,
        pendingKycCount: 3,
        onDutyDeliveryFleetCount: 12,
      );

      expect(metrics.totalGmv, 200000.0);
      expect(metrics.platformRevenue, 20000.0); // 10% of ₹2,00,000 = ₹20,000
      expect(metrics.platformCommissionRate, 10.0);
      expect(metrics.pendingKycCount, 3);
    });

    test('AdminRepository fetches metrics, updates KYC status, and resolves disputes', () async {
      final repo = AdminRepository();

      // 1. Get Platform Metrics
      final metrics = await repo.getPlatformMetrics();
      expect(metrics.totalGmv, greaterThan(0));
      expect(metrics.zoneMetrics.isNotEmpty, isTrue);
      expect(metrics.pendingBoutiques.isNotEmpty, isTrue);

      // 2. Approve Boutique KYC
      final boutiqueToApprove = metrics.pendingBoutiques.first;
      final approveSuccess = await repo.updateBoutiqueKycStatus(
        boutiqueId: boutiqueToApprove.id,
        status: KycStatus.approved,
      );
      expect(approveSuccess, isTrue);

      // 3. Resolve Dispute Ticket
      final dispute = metrics.disputes.first;
      final disputeSuccess = await repo.resolveDisputeTicket(disputeId: dispute.id);
      expect(disputeSuccess, isTrue);
    });

    testWidgets('Renders Admin Dashboard with GMV and Operations Hub', (WidgetTester tester) async {
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
          ],
          child: const ParidhanApp(flavorTitle: 'Admin Test'),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Super Admin Portal'), findsOneWidget);
      expect(find.text('Super Admin Jaipur (City Ops: Jaipur)'), findsOneWidget);
      expect(find.text('Gross Merchandise Value (GMV)'), findsOneWidget);
      expect(find.text('Operations Hub'), findsOneWidget);
      expect(find.text('Boutique KYC'), findsOneWidget);
      expect(find.text('City Analytics'), findsOneWidget);
    });

    testWidgets('Renders Admin Boutique Verification Screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminBoutiqueVerificationScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Boutique KYC Verification'), findsOneWidget);
      expect(find.text('Pending Review'), findsOneWidget);
      expect(find.text('Approve & Activate'), findsWidgets);
    });

    testWidgets('Renders Admin Analytics and Disputes Screens', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1. Analytics Screen
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminAnalyticsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('City-Level Analytics (Jaipur)'), findsOneWidget);
      expect(find.text('Jaipur Hyperlocal Zones'), findsOneWidget);
      expect(find.text('Top Fashion Categories'), findsOneWidget);

      // 2. Disputes Screen
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminDisputesScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Disputes & Escalations'), findsOneWidget);
    });
  });
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
