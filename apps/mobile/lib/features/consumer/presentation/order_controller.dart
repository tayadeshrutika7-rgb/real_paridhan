import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/order_repository.dart';
import '../domain/address_model.dart';
import '../domain/cart_item_model.dart';
import '../domain/order_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/notifications/domain/app_notification_model.dart';
import '../../../core/notifications/presentation/role_notification_controller.dart';

class OrderState {
  final List<AddressModel> addresses;
  final AddressModel? selectedAddress;
  final List<OrderModel> orders;
  final List<OrderModel> sellerOrders;
  final OrderModel? activeOrder;
  final PaymentMethod selectedPaymentMethod;
  final bool isLoading;
  final String? errorMessage;
  final OrderModel? placedOrder;

  const OrderState({
    this.addresses = const [],
    this.selectedAddress,
    this.orders = const [],
    this.sellerOrders = const [],
    this.activeOrder,
    this.selectedPaymentMethod = PaymentMethod.razorpay,
    this.isLoading = false,
    this.errorMessage,
    this.placedOrder,
  });

  OrderState copyWith({
    List<AddressModel>? addresses,
    AddressModel? selectedAddress,
    List<OrderModel>? orders,
    List<OrderModel>? sellerOrders,
    OrderModel? activeOrder,
    PaymentMethod? selectedPaymentMethod,
    bool? isLoading,
    String? errorMessage,
    OrderModel? placedOrder,
    bool clearError = false,
    bool clearPlacedOrder = false,
  }) {
    return OrderState(
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      orders: orders ?? this.orders,
      sellerOrders: sellerOrders ?? this.sellerOrders,
      activeOrder: activeOrder ?? this.activeOrder,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      placedOrder: clearPlacedOrder ? null : (placedOrder ?? this.placedOrder),
    );
  }
}

class OrderController extends Notifier<OrderState> {
  final OrderRepository _repository = OrderRepository();

  @override
  OrderState build() {
    Future.microtask(() => loadAddresses(''));
    return const OrderState();
  }

  Future<void> loadAddresses(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repository.getAddresses(userId);
      final defaultAddr = list.isNotEmpty
          ? list.firstWhere((a) => a.isDefault, orElse: () => list.first)
          : null;

      state = state.copyWith(
        addresses: list,
        selectedAddress: state.selectedAddress ?? defaultAddr,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void selectAddress(AddressModel address) {
    state = state.copyWith(selectedAddress: address);
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  Future<void> saveAddress(AddressModel address) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final saved = await _repository.saveAddress(address);
      final updatedList = [
        saved,
        ...state.addresses.where((a) => a.id != saved.id && a.addressLine1 != saved.addressLine1),
      ];
      state = state.copyWith(
        addresses: updatedList,
        selectedAddress: saved,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<OrderModel?> placeOrder({
    required String consumerId,
    required List<CartItemModel> cartItems,
    required double subtotal,
    required double deliveryFee,
    required double platformFee,
    required double totalAmount,
  }) async {
    final addr = state.selectedAddress;
    if (addr == null) {
      state = state.copyWith(errorMessage: 'Please select a delivery address');
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final order = await _repository.placeOrder(
        consumerId: consumerId,
        cartItems: cartItems,
        address: addr,
        paymentMethod: state.selectedPaymentMethod,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        platformFee: platformFee,
        totalAmount: totalAmount,
      );

      state = state.copyWith(
        isLoading: false,
        placedOrder: order,
        orders: [order, ...state.orders],
      );

      // 1. Customer Notification
      ref.read(roleNotificationProvider(UserRole.consumer).notifier).postNotification(
        title: 'Order Placed Successfully',
        body: 'Your order #${order.id.substring(0, 8)} has been placed for ₹${order.totalAmount.toStringAsFixed(0)}.',
        category: NotificationCategory.order,
        deepLink: '/order/${order.id}',
      );

      // 2. Seller Notification
      ref.read(roleNotificationProvider(UserRole.seller).notifier).postNotification(
        title: 'New Order Received',
        body: 'New order #${order.id.substring(0, 8)} with ${order.items.length} item(s) requires fulfillment.',
        category: NotificationCategory.order,
        deepLink: '/seller/orders',
      );

      // 3. Delivery Fleet Notification
      ref.read(roleNotificationProvider(UserRole.delivery).notifier).postNotification(
        title: 'New Delivery Assignment',
        body: 'Pickup available for order #${order.id.substring(0, 8)} in local area.',
        category: NotificationCategory.assignment,
        deepLink: '/delivery/trip/${order.id}',
      );

      // 4. Admin Operations Notification
      ref.read(roleNotificationProvider(UserRole.admin).notifier).postNotification(
        title: 'Platform Order Created',
        body: 'Order #${order.id.substring(0, 8)} recorded with GMV ₹${order.totalAmount.toStringAsFixed(0)}.',
        category: NotificationCategory.platform,
        deepLink: '/admin',
      );

      return order;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<void> loadConsumerOrders(String consumerId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final orders = await _repository.getConsumerOrders(consumerId);
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadSellerOrders(String sellerId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final orders = await _repository.getSellerOrders(sellerId);
      state = state.copyWith(sellerOrders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadOrderDetails(String orderId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final order = await _repository.getOrderDetails(orderId);
      state = state.copyWith(activeOrder: order, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> updateSellerOrderStatus(String orderId, OrderStatus status) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ok = await _repository.updateOrderStatus(orderId, status);
      if (ok) {
        final updatedSellerOrders = state.sellerOrders.map((o) {
          return o.id == orderId ? o.copyWith(status: status) : o;
        }).toList();

        final updatedActive = state.activeOrder?.id == orderId
            ? state.activeOrder!.copyWith(status: status)
            : state.activeOrder;

        state = state.copyWith(
          sellerOrders: updatedSellerOrders,
          activeOrder: updatedActive,
          isLoading: false,
        );

        // Notify seller
        ref.read(roleNotificationProvider(UserRole.seller).notifier).postNotification(
          title: 'Order Status Updated',
          body: 'Order #${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)} status set to ${status.name.toUpperCase()}.',
          category: NotificationCategory.order,
          deepLink: '/seller/orders',
        );

        // Notify customer
        ref.read(roleNotificationProvider(UserRole.consumer).notifier).postNotification(
          title: 'Order Update',
          body: 'Your order #${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)} is now ${status.name.toUpperCase()}.',
          category: NotificationCategory.order,
          deepLink: '/order/$orderId',
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> cancelOrderDueToCustomerUnavailable(String orderId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ok = await _repository.cancelOrderDueToCustomerUnavailable(orderId);
      if (ok) {
        final shortId = orderId.substring(0, orderId.length > 8 ? 8 : orderId.length);
        final updatedSellerOrders = state.sellerOrders.map((o) {
          return o.id == orderId
              ? o.copyWith(
                  status: OrderStatus.cancelled,
                  customerUnavailable: true,
                  deliveryIssue: 'customer_not_available',
                  deliveryIssueNotes: 'Cancelled by seller due to customer unavailability',
                )
              : o;
        }).toList();

        final updatedConsumerOrders = state.orders.map((o) {
          return o.id == orderId
              ? o.copyWith(
                  status: OrderStatus.cancelled,
                  customerUnavailable: true,
                  deliveryIssue: 'customer_not_available',
                )
              : o;
        }).toList();

        final updatedActive = state.activeOrder?.id == orderId
            ? state.activeOrder!.copyWith(
                status: OrderStatus.cancelled,
                customerUnavailable: true,
                deliveryIssue: 'customer_not_available',
              )
            : state.activeOrder;

        state = state.copyWith(
          sellerOrders: updatedSellerOrders,
          orders: updatedConsumerOrders,
          activeOrder: updatedActive,
          isLoading: false,
        );

        // 1. Seller notification
        ref.read(roleNotificationProvider(UserRole.seller).notifier).postNotification(
          title: 'Order Cancelled (Customer Unavailable)',
          body: 'Order #$shortId has been cancelled due to customer unavailability. Inventory restocked.',
          category: NotificationCategory.order,
          deepLink: '/seller/orders',
        );

        // 2. Customer notification
        ref.read(roleNotificationProvider(UserRole.consumer).notifier).postNotification(
          title: 'Order Cancelled: Doorstep Unreachable',
          body: 'Your order #$shortId was cancelled by the boutique as the delivery partner was unable to reach you.',
          category: NotificationCategory.order,
          deepLink: '/order/$orderId',
        );

        // 3. Admin notification
        ref.read(roleNotificationProvider(UserRole.admin).notifier).postNotification(
          title: 'Order Cancelled by Seller (Customer Unavailable)',
          body: 'Seller cancelled order #$shortId following delivery partner unavailability report.',
          category: NotificationCategory.platform,
          deepLink: '/admin',
        );

        return true;
      } else {
        state = state.copyWith(isLoading: false);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void clearPlacedOrder() {
    state = state.copyWith(clearPlacedOrder: true);
  }
}

final orderProvider =
    NotifierProvider<OrderController, OrderState>(OrderController.new);
