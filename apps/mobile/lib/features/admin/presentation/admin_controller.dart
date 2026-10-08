import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_repository.dart';
import '../domain/admin_metrics_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/notifications/domain/app_notification_model.dart';
import '../../../core/notifications/presentation/role_notification_controller.dart';
import '../../seller/presentation/seller_controller.dart';
import '../../consumer/presentation/consumer_controller.dart';
import '../../delivery/presentation/delivery_controller.dart';

class AdminDashboardState {
  final bool isLoading;
  final AdminMetricsModel metrics;
  final String filterPeriod; // 'Today', '7 Days', '30 Days', 'This Month', 'Custom'
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String searchQuery;
  final Set<String> unmaskedKycShops; // Shop IDs where Super Admin unmasked sensitive documents
  final String? errorMessage;
  final String? successMessage;

  const AdminDashboardState({
    this.isLoading = false,
    this.metrics = const AdminMetricsModel(),
    this.filterPeriod = 'This Month',
    this.customStartDate,
    this.customEndDate,
    this.searchQuery = '',
    this.unmaskedKycShops = const {},
    this.errorMessage,
    this.successMessage,
  });

  AdminDashboardState copyWith({
    bool? isLoading,
    AdminMetricsModel? metrics,
    String? filterPeriod,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? searchQuery,
    Set<String>? unmaskedKycShops,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AdminDashboardState(
      isLoading: isLoading ?? this.isLoading,
      metrics: metrics ?? this.metrics,
      filterPeriod: filterPeriod ?? this.filterPeriod,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      searchQuery: searchQuery ?? this.searchQuery,
      unmaskedKycShops: unmaskedKycShops ?? this.unmaskedKycShops,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AdminNotifier extends Notifier<AdminDashboardState> {
  final AdminRepository _repository = AdminRepository();

  @override
  AdminDashboardState build() {
    Future.microtask(() => loadDashboard());
    return const AdminDashboardState(isLoading: true);
  }

  Future<void> loadDashboard({String? period}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      filterPeriod: period ?? state.filterPeriod,
    );
    try {
      final data = await _repository.getPlatformMetrics(filterPeriod: state.filterPeriod);
      state = state.copyWith(
        isLoading: false,
        metrics: data,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load platform metrics: $e',
      );
    }
  }

  void setFilterPeriod(String period) {
    state = state.copyWith(filterPeriod: period);
    loadDashboard(period: period);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Super Admin Security: Toggle sensitive KYC document/number unmasking with audit log
  Future<void> toggleUnmaskKyc(String shopId, {String adminName = 'Super Admin'}) async {
    final current = Set<String>.from(state.unmaskedKycShops);
    if (current.contains(shopId)) {
      current.remove(shopId);
    } else {
      current.add(shopId);
      await _repository.logSensitiveDataAccess(
        entityId: shopId,
        entityType: 'shop_kyc_details',
        fieldAccessed: 'PAN, Aadhaar & Bank Account numbers',
        adminName: adminName,
      );
    }
    state = state.copyWith(unmaskedKycShops: current);
  }

  /// KYC Actions
  Future<bool> approveBoutique(
    String boutiqueId, {
    String? shopName,
    String? notes,
    String adminName = 'Super Admin',
  }) async {
    // Immediate optimistic state update
    final currentPending = List<BoutiqueVerificationItem>.from(state.metrics.pendingBoutiques);
    currentPending.removeWhere((b) => b.id == boutiqueId || (shopName != null && b.shopName == shopName) || b.shopName == boutiqueId);
    state = state.copyWith(
      metrics: state.metrics.copyWith(
        pendingBoutiques: currentPending,
        pendingKycCount: (state.metrics.pendingKycCount - 1).clamp(0, 9999),
        activeBoutiquesCount: state.metrics.activeBoutiquesCount + 1,
      ),
    );

    final success = await _repository.updateBoutiqueKycStatus(
      boutiqueId: boutiqueId,
      shopName: shopName,
      status: KycStatus.approved,
      verificationNotes: notes,
      adminName: adminName,
    );
    if (success) {
      // Invalidate active seller and consumer providers so verified status updates immediately in app UI
      ref.invalidate(sellerProvider);
      ref.invalidate(consumerProvider);

      // Notify Seller
      ref.read(roleNotificationProvider(UserRole.seller).notifier).postNotification(
        title: 'Boutique KYC Approved! 🎉',
        body: 'Your boutique has been verified. Full seller features and catalog are active.',
        category: NotificationCategory.kyc,
        deepLink: '/seller',
      );

      // Notify Admin
      ref.read(roleNotificationProvider(UserRole.admin).notifier).postNotification(
        title: 'Boutique KYC Verified',
        body: 'Approved boutique $boutiqueId ($adminName).',
        category: NotificationCategory.kyc,
        deepLink: '/admin/boutiques',
      );

      await loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> rejectBoutique(
    String boutiqueId, {
    String? shopName,
    required String reason,
    String adminName = 'Super Admin',
  }) async {
    // Immediate optimistic state update
    final currentPending = List<BoutiqueVerificationItem>.from(state.metrics.pendingBoutiques);
    currentPending.removeWhere((b) => b.id == boutiqueId || (shopName != null && b.shopName == shopName) || b.shopName == boutiqueId);
    state = state.copyWith(
      metrics: state.metrics.copyWith(
        pendingBoutiques: currentPending,
        pendingKycCount: (state.metrics.pendingKycCount - 1).clamp(0, 9999),
        suspendedSellersCount: state.metrics.suspendedSellersCount + 1,
      ),
    );

    final success = await _repository.updateBoutiqueKycStatus(
      boutiqueId: boutiqueId,
      shopName: shopName,
      status: KycStatus.rejected,
      reason: reason,
      adminName: adminName,
    );
    if (success) {
      ref.invalidate(sellerProvider);
      ref.invalidate(consumerProvider);

      // Notify Seller
      ref.read(roleNotificationProvider(UserRole.seller).notifier).postNotification(
        title: 'Boutique KYC Rejected',
        body: 'Verification was not approved: $reason. Please update details and resubmit.',
        category: NotificationCategory.kyc,
        deepLink: '/seller/shop',
      );

      // Notify Admin
      ref.read(roleNotificationProvider(UserRole.admin).notifier).postNotification(
        title: 'Boutique KYC Rejected',
        body: 'Rejected boutique $boutiqueId ($reason).',
        category: NotificationCategory.kyc,
        deepLink: '/admin/boutiques',
      );

      await loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> requestKycCorrection(
    String boutiqueId, {
    String? shopName,
    required String notes,
    String adminName = 'Super Admin',
  }) async {
    final currentPending = List<BoutiqueVerificationItem>.from(state.metrics.pendingBoutiques);
    currentPending.removeWhere((b) => b.id == boutiqueId || (shopName != null && b.shopName == shopName) || b.shopName == boutiqueId);
    state = state.copyWith(
      metrics: state.metrics.copyWith(
        pendingBoutiques: currentPending,
        pendingKycCount: (state.metrics.pendingKycCount - 1).clamp(0, 9999),
      ),
    );

    final success = await _repository.updateBoutiqueKycStatus(
      boutiqueId: boutiqueId,
      shopName: shopName,
      status: KycStatus.correctionRequested,
      verificationNotes: notes,
      adminName: adminName,
    );
    if (success) {
      ref.invalidate(sellerProvider);

      // Notify Seller
      ref.read(roleNotificationProvider(UserRole.seller).notifier).postNotification(
        title: 'KYC Documents Correction Required',
        body: 'Admin notes: $notes. Please re-upload verified documents.',
        category: NotificationCategory.kyc,
        deepLink: '/seller/shop',
      );

      // Notify Admin
      ref.read(roleNotificationProvider(UserRole.admin).notifier).postNotification(
        title: 'KYC Correction Requested',
        body: 'Requested updates for boutique $boutiqueId.',
        category: NotificationCategory.kyc,
        deepLink: '/admin/boutiques',
      );

      await loadDashboard();
      return true;
    }
    return false;
  }

  /// Delivery Partner KYC Verification Actions
  Future<bool> approveDeliveryPartner(
    String driverId, {
    String? notes,
    String adminName = 'Super Admin',
  }) async {
    final currentFleet = List<AdminDeliveryPartnerItem>.from(state.metrics.deliveryPartners);
    final driverIdx = currentFleet.indexWhere((d) => d.id == driverId);
    if (driverIdx != -1) {
      currentFleet[driverIdx] = currentFleet[driverIdx].copyWith(verificationStatus: 'verified');
      state = state.copyWith(
        metrics: state.metrics.copyWith(
          deliveryPartners: currentFleet,
        ),
      );
    }

    final success = await _repository.updateDeliveryPartnerKycStatus(
      driverId: driverId,
      verificationStatus: 'verified',
      verificationNotes: notes,
      adminName: adminName,
    );
    if (success) {
      ref.invalidate(deliveryProvider);

      // Notify Delivery Partner
      ref.read(roleNotificationProvider(UserRole.delivery).notifier).postNotification(
        title: 'Delivery Partner KYC Approved! 🛵',
        body: 'Your driving license and vehicle registration are verified. You can now go online and accept delivery orders.',
        category: NotificationCategory.kyc,
        deepLink: '/delivery',
      );

      // Notify Admin
      ref.read(roleNotificationProvider(UserRole.admin).notifier).postNotification(
        title: 'Delivery Partner Approved',
        body: 'Approved delivery partner $driverId ($adminName).',
        category: NotificationCategory.kyc,
        deepLink: '/admin/delivery',
      );

      await loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> rejectDeliveryPartner(
    String driverId, {
    required String reason,
    String adminName = 'Super Admin',
  }) async {
    final success = await _repository.updateDeliveryPartnerKycStatus(
      driverId: driverId,
      verificationStatus: 'rejected',
      reason: reason,
      adminName: adminName,
    );
    if (success) {
      ref.invalidate(deliveryProvider);

      // Notify Delivery Partner
      ref.read(roleNotificationProvider(UserRole.delivery).notifier).postNotification(
        title: 'Delivery Partner KYC Rejected',
        body: 'Onboarding was not approved: $reason. Please update details with admin support.',
        category: NotificationCategory.kyc,
        deepLink: '/delivery',
      );

      await loadDashboard();
      return true;
    }
    return false;
  }

  /// Seller Store Management
  Future<bool> updateSellerStatus(
    String shopId,
    String newStatus, {
    String? reason,
    String adminName = 'Super Admin',
  }) async {
    final success = await _repository.updateSellerAccountStatus(
      shopId: shopId,
      newStatus: newStatus,
      reason: reason,
      adminName: adminName,
    );
    if (success) {
      // Notify Seller
      ref.read(roleNotificationProvider(UserRole.seller).notifier).postNotification(
        title: 'Account Status: ${newStatus.toUpperCase()}',
        body: reason ?? 'Your seller account status was updated by Paridhan Administration.',
        category: NotificationCategory.kyc,
        deepLink: '/seller',
      );

      await loadDashboard();
      return true;
    }
    return false;
  }

  /// Disputes & Refunds
  Future<bool> resolveDispute(
    String disputeId, {
    bool isRefundApproved = false,
    String adminName = 'Super Admin',
  }) async {
    final success = await _repository.resolveDisputeTicket(
      disputeId: disputeId,
      isRefundApproved: isRefundApproved,
      adminName: adminName,
    );
    if (success) {
      // Notify Customer
      ref.read(roleNotificationProvider(UserRole.consumer).notifier).postNotification(
        title: isRefundApproved ? 'Dispute Resolved & Refund Initiated' : 'Dispute Resolved',
        body: isRefundApproved
            ? 'Your refund for ticket #$disputeId has been approved and processed.'
            : 'Ticket #$disputeId has been reviewed and closed.',
        category: NotificationCategory.dispute,
        deepLink: '/orders',
      );

      // Notify Seller
      ref.read(roleNotificationProvider(UserRole.seller).notifier).postNotification(
        title: 'Dispute Ticket #$disputeId Resolved',
        body: isRefundApproved
            ? 'Refund was approved and debited from platform payout.'
            : 'Dispute closed without refund.',
        category: NotificationCategory.order,
        deepLink: '/seller/orders',
      );

      // Notify Admin
      ref.read(roleNotificationProvider(UserRole.admin).notifier).postNotification(
        title: 'Dispute Closed',
        body: 'Dispute ticket #$disputeId resolved ($adminName).',
        category: NotificationCategory.dispute,
        deepLink: '/admin/disputes',
      );

      await loadDashboard();
      return true;
    }
    return false;
  }

  /// Order Overrides
  Future<bool> updateOrderStatus(
    String orderId,
    String newStatus, {
    String adminName = 'Super Admin',
  }) async {
    final success = await _repository.updateOrderStatus(
      orderId: orderId,
      newStatus: newStatus,
      adminName: adminName,
    );
    if (success) {
      await loadDashboard();
      return true;
    }
    return false;
  }
}

final adminProvider = NotifierProvider<AdminNotifier, AdminDashboardState>(() {
  return AdminNotifier();
});
