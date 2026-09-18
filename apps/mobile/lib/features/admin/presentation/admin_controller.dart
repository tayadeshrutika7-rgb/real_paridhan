import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_repository.dart';
import '../domain/admin_metrics_model.dart';

class AdminDashboardState {
  final bool isLoading;
  final AdminMetricsModel metrics;
  final String filterPeriod;
  final String? errorMessage;

  const AdminDashboardState({
    this.isLoading = false,
    this.metrics = const AdminMetricsModel(),
    this.filterPeriod = 'This Month',
    this.errorMessage,
  });

  AdminDashboardState copyWith({
    bool? isLoading,
    AdminMetricsModel? metrics,
    String? filterPeriod,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminDashboardState(
      isLoading: isLoading ?? this.isLoading,
      metrics: metrics ?? this.metrics,
      filterPeriod: filterPeriod ?? this.filterPeriod,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _repository.getPlatformMetrics();
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

  Future<bool> approveBoutique(String boutiqueId) async {
    final success = await _repository.updateBoutiqueKycStatus(
      boutiqueId: boutiqueId,
      status: KycStatus.approved,
    );
    if (success) {
      await loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> rejectBoutique(String boutiqueId) async {
    final success = await _repository.updateBoutiqueKycStatus(
      boutiqueId: boutiqueId,
      status: KycStatus.rejected,
    );
    if (success) {
      await loadDashboard();
      return true;
    }
    return false;
  }

  Future<bool> resolveDispute(String disputeId) async {
    final success = await _repository.resolveDisputeTicket(disputeId: disputeId);
    if (success) {
      await loadDashboard();
      return true;
    }
    return false;
  }

  void setFilterPeriod(String period) {
    state = state.copyWith(filterPeriod: period);
  }
}

final adminProvider = NotifierProvider<AdminNotifier, AdminDashboardState>(() {
  return AdminNotifier();
});
