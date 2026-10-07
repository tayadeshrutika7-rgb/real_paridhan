import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_state.dart';
import '../data/delivery_repository.dart';
import '../domain/delivery_task_model.dart';
import '../domain/delivery_earnings_model.dart';
import '../domain/delivery_route_batch_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/notifications/domain/app_notification_model.dart';
import '../../../core/notifications/presentation/role_notification_controller.dart';

class DeliveryState {
  final bool isOnline;
  final bool isLoading;
  final String verificationStatus; // 'verified', 'pending', 'rejected'
  final DeliveryTaskModel? activeTrip;
  final List<DeliveryTaskModel> incomingRequests;
  final List<DeliveryRouteBatchModel> availableBatches;
  final DeliveryRouteBatchModel? onTheWayOrder;
  final DeliveryEarningsModel earnings;
  final String? errorMessage;

  const DeliveryState({
    this.isOnline = true,
    this.isLoading = false,
    this.verificationStatus = 'verified',
    this.activeTrip,
    this.incomingRequests = const [],
    this.availableBatches = const [],
    this.onTheWayOrder,
    this.earnings = const DeliveryEarningsModel(),
    this.errorMessage,
  });

  bool get isVerified => verificationStatus == 'verified';

  DeliveryState copyWith({
    bool? isOnline,
    bool? isLoading,
    String? verificationStatus,
    DeliveryTaskModel? activeTrip,
    bool clearActiveTrip = false,
    List<DeliveryTaskModel>? incomingRequests,
    List<DeliveryRouteBatchModel>? availableBatches,
    DeliveryRouteBatchModel? onTheWayOrder,
    bool clearOnTheWayOrder = false,
    DeliveryEarningsModel? earnings,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DeliveryState(
      isOnline: isOnline ?? this.isOnline,
      isLoading: isLoading ?? this.isLoading,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      activeTrip: clearActiveTrip ? null : (activeTrip ?? this.activeTrip),
      incomingRequests: incomingRequests ?? this.incomingRequests,
      availableBatches: availableBatches ?? this.availableBatches,
      onTheWayOrder: clearOnTheWayOrder ? null : (onTheWayOrder ?? this.onTheWayOrder),
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
      final verification = await _repository.getDriverVerificationStatus(_currentDriverId);
      final active = await _repository.getActiveTrip(_currentDriverId);
      final earnings = await _repository.getEarningsSummary(_currentDriverId);
      final incoming = state.isOnline
          ? await _repository.getIncomingRequests(driverId: _currentDriverId)
          : <DeliveryTaskModel>[];

      final batches = DeliveryRouteBatchModel.findSamePathBatches(incoming);
      final onTheWay = active != null
          ? DeliveryRouteBatchModel.checkOnTheWayOrder(activeTrip: active, incomingOrders: incoming)
          : null;

      state = state.copyWith(
        isLoading: false,
        verificationStatus: verification,
        activeTrip: active,
        earnings: earnings,
        incomingRequests: incoming,
        availableBatches: batches,
        onTheWayOrder: onTheWay,
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
      final batches = DeliveryRouteBatchModel.findSamePathBatches(incoming);
      state = state.copyWith(
        incomingRequests: incoming,
        availableBatches: batches,
      );
    } else {
      state = state.copyWith(
        incomingRequests: [],
        availableBatches: [],
        clearOnTheWayOrder: true,
      );
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
      final batches = DeliveryRouteBatchModel.findSamePathBatches(remaining);
      final onTheWay = DeliveryRouteBatchModel.checkOnTheWayOrder(
        activeTrip: task,
        incomingOrders: remaining,
      );

      state = state.copyWith(
        isLoading: false,
        activeTrip: task,
        incomingRequests: remaining,
        availableBatches: batches,
        onTheWayOrder: onTheWay,
      );

      // 1. Delivery notification
      ref.read(roleNotificationProvider(UserRole.delivery).notifier).postNotification(
        title: 'Trip Assigned & Started',
        body: 'Navigating to ${task.shopName} for pickup.',
        category: NotificationCategory.trip,
        deepLink: '/delivery/trip/${task.id}',
      );

      // 2. Seller notification
      ref.read(roleNotificationProvider(UserRole.seller).notifier).postNotification(
        title: 'Delivery Partner En Route',
        body: 'A partner has accepted order #${task.orderId.substring(0, task.orderId.length > 8 ? 8 : task.orderId.length)} for pickup.',
        category: NotificationCategory.order,
        deepLink: '/seller/orders',
      );

      // 3. Customer notification
      ref.read(roleNotificationProvider(UserRole.consumer).notifier).postNotification(
        title: 'Delivery Partner Assigned',
        body: 'A partner is picking up your order #${task.orderId.substring(0, task.orderId.length > 8 ? 8 : task.orderId.length)}.',
        category: NotificationCategory.order,
        deepLink: '/order/${task.orderId}',
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

  /// Accept multi-order route batch
  Future<bool> acceptRouteBatch(DeliveryRouteBatchModel batch) async {
    if (batch.tasks.isEmpty) return false;
    state = state.copyWith(isLoading: true);

    DeliveryTaskModel? primaryTask;
    for (final task in batch.tasks) {
      final accepted = await _repository.acceptTask(
        taskId: task.id,
        driverId: _currentDriverId,
      );
      primaryTask ??= accepted;
    }

    if (primaryTask != null) {
      final taskIds = batch.tasks.map((t) => t.id).toSet();
      final remaining = state.incomingRequests.where((t) => !taskIds.contains(t.id)).toList();
      final batches = DeliveryRouteBatchModel.findSamePathBatches(remaining);

      state = state.copyWith(
        isLoading: false,
        activeTrip: primaryTask,
        incomingRequests: remaining,
        availableBatches: batches,
      );

      ref.read(roleNotificationProvider(UserRole.delivery).notifier).postNotification(
        title: 'Batch Route Accepted',
        body: 'En route to ${batch.tasks.length} optimized pickup/drop stops.',
        category: NotificationCategory.trip,
      );

      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not accept route batch.',
      );
      return false;
    }
  }

  void dismissRequest(String taskId) {
    final updated = state.incomingRequests.where((t) => t.id != taskId).toList();
    final batches = DeliveryRouteBatchModel.findSamePathBatches(updated);
    state = state.copyWith(
      incomingRequests: updated,
      availableBatches: batches,
    );
  }

  Future<bool> confirmStorePickup(String taskId) async {
    state = state.copyWith(isLoading: true);
    final updated = await _repository.confirmPickup(taskId);
    if (updated != null) {
      state = state.copyWith(isLoading: false, activeTrip: updated);

      // Delivery notification
      ref.read(roleNotificationProvider(UserRole.delivery).notifier).postNotification(
        title: 'Pickup Completed',
        body: 'Package collected from ${updated.shopName}. Proceed to customer drop location.',
        category: NotificationCategory.trip,
        deepLink: '/delivery/trip/$taskId',
      );

      // Customer notification
      ref.read(roleNotificationProvider(UserRole.consumer).notifier).postNotification(
        title: 'Out for Doorstep Delivery 🚀',
        body: 'Your package is on its way with the delivery partner.',
        category: NotificationCategory.order,
        deepLink: '/order/${updated.orderId}',
      );

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

      // Delivery notification
      ref.read(roleNotificationProvider(UserRole.delivery).notifier).postNotification(
        title: 'Trip Completed! Payout Credited 💰',
        body: 'Order delivery confirmed. Earnings updated in your wallet.',
        category: NotificationCategory.trip,
        deepLink: '/delivery/earnings',
      );

      // Customer notification
      ref.read(roleNotificationProvider(UserRole.consumer).notifier).postNotification(
        title: 'Order Delivered Successfully 🎉',
        body: 'Thank you for shopping on Paridhan! We hope you love your handcrafted garment.',
        category: NotificationCategory.order,
        deepLink: '/order/$orderId',
      );

      // Seller notification
      ref.read(roleNotificationProvider(UserRole.seller).notifier).postNotification(
        title: 'Order Delivered to Customer',
        body: 'Order #${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)} delivered. Payout scheduled.',
        category: NotificationCategory.order,
        deepLink: '/seller/orders',
      );

      // Admin notification
      ref.read(roleNotificationProvider(UserRole.admin).notifier).postNotification(
        title: 'Delivery Fulfilled',
        body: 'Order #$orderId delivered by partner $_currentDriverId.',
        category: NotificationCategory.platform,
        deepLink: '/admin',
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
