import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/order_repository.dart';
import '../domain/address_model.dart';
import '../domain/cart_item_model.dart';
import '../domain/order_model.dart';

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
  late final OrderRepository _repository;

  @override
  OrderState build() {
    _repository = OrderRepository();
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
        selectedAddress: defaultAddr,
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
        ...state.addresses.where((a) => a.id != saved.id),
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
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void clearPlacedOrder() {
    state = state.copyWith(clearPlacedOrder: true);
  }
}

final orderProvider =
    NotifierProvider<OrderController, OrderState>(OrderController.new);
