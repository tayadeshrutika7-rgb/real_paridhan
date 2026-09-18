import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_state.dart';
import '../data/delivery_repository.dart';
import '../domain/delivery_task_model.dart';
import '../domain/delivery_earnings_model.dart';

class DeliveryState {
  final bool isOnline;
  final bool isLoading;
  final DeliveryTaskModel? activeTrip;
  final List<DeliveryTaskModel> incomingRequests;
  final DeliveryEarningsModel earnings;
  final String? errorMessage;

  const DeliveryState({
    this.isOnline = true,
    this.isLoading = false,
    this.activeTrip,
    this.incomingRequests = const [],
    this.earnings = const DeliveryEarningsModel(),
    this.errorMessage,
  });

  DeliveryState copyWith({
    bool? isOnline,
    bool? isLoading,
    DeliveryTaskModel? activeTrip,
    bool clearActiveTrip = false,
    List<DeliveryTaskModel>? incomingRequests,
    DeliveryEarningsModel? earnings,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DeliveryState(
      isOnline: isOnline ?? this.isOnline,
      isLoading: isLoading ?? this.isLoading,
      activeTrip: clearActiveTrip ? null : (activeTrip ?? this.activeTrip),
      incomingRequests: incomingRequests ?? this.incomingRequests,
      earnings: earnings ?? this.earnings,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DeliveryNotifier extends Notifier<DeliveryState> {
  final DeliveryRepository _repository = DeliveryRepository();

  @override
  DeliveryState build() {
    // Initial fetch
    Future.microtask(() => loadDashboard());
    return const DeliveryState(isLoading: true);
  }

  String get _currentDriverId {
    final user = ref.read(authProvider).user;
    return user?.id ?? 'delivery-test-driver';
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final active = await _repository.getActiveTrip(_currentDriverId);
      final earnings = await _repository.getEarningsSummary(_currentDriverId);
      final incoming = state.isOnline
          ? await _repository.getIncomingRequests(driverId: _currentDriverId)
          : <DeliveryTaskModel>[];

      state = state.copyWith(
        isLoading: false,
        activeTrip: active,
        earnings: earnings,
        incomingRequests: incoming,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load delivery data: $e',
      );
    }
  }

  Future<void> toggleDuty(bool isOnline) async {
    state = state.copyWith(isOnline: isOnline);
    await _repository.setDutyStatus(
      isOnline: isOnline,
      driverId: _currentDriverId,
    );

    if (isOnline) {
      final incoming = await _repository.getIncomingRequests(driverId: _currentDriverId);
      state = state.copyWith(incomingRequests: incoming);
    } else {
      state = state.copyWith(incomingRequests: []);
    }
  }

  Future<bool> acceptIncomingTask(String taskId) async {
    state = state.copyWith(isLoading: true);
    final task = await _repository.acceptTask(
      taskId: taskId,
      driverId: _currentDriverId,
    );

    if (task != null) {
      final remaining = state.incomingRequests.where((t) => t.id != taskId).toList();
      state = state.copyWith(
        isLoading: false,
        activeTrip: task,
        incomingRequests: remaining,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Task no longer available.',
      );
      return false;
    }
  }

  void dismissRequest(String taskId) {
    final updated = state.incomingRequests.where((t) => t.id != taskId).toList();
    state = state.copyWith(incomingRequests: updated);
  }

  Future<bool> confirmStorePickup(String taskId) async {
    state = state.copyWith(isLoading: true);
    final updated = await _repository.confirmPickup(taskId);
    if (updated != null) {
      state = state.copyWith(isLoading: false, activeTrip: updated);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not confirm pickup.',
      );
      return false;
    }
  }

  Future<bool> verifyCustomerOtp({
    required String taskId,
    required String orderId,
    required String otp,
    required bool isCod,
    required double codAmount,
  }) async {
    state = state.copyWith(isLoading: true);
    final success = await _repository.verifyOtpAndCompleteDelivery(
      taskId: taskId,
      orderId: orderId,
      inputOtp: otp,
      isCod: isCod,
      codCollectedAmount: codAmount,
      driverId: _currentDriverId,
    );

    if (success) {
      final earnings = await _repository.getEarningsSummary(_currentDriverId);
      state = state.copyWith(
        isLoading: false,
        clearActiveTrip: true,
        earnings: earnings,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid OTP. Please ask the customer for their 4-digit Delivery PIN.',
      );
      return false;
    }
  }
}

final deliveryProvider = NotifierProvider<DeliveryNotifier, DeliveryState>(() {
  return DeliveryNotifier();
});
