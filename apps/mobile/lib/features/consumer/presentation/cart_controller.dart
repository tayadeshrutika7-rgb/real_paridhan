import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_state.dart';
import '../../seller/domain/product_model.dart';
import '../../seller/domain/variant_model.dart';
import '../data/consumer_repository.dart';
import '../domain/cart_item_model.dart';

class CartState {
  final bool isLoading;
  final List<CartItemModel> items;
  final String? errorMessage;

  const CartState({
    this.isLoading = false,
    this.items = const [],
    this.errorMessage,
  });

  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.itemTotal);

  CartState copyWith({
    bool? isLoading,
    List<CartItemModel>? items,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CartController extends Notifier<CartState> {
  late final ConsumerRepository _repository;

  @override
  CartState build() {
    _repository = ConsumerRepository();
    Future.microtask(() => loadCart());
    return const CartState(isLoading: true);
  }

  Future<void> loadCart() async {
    final authState = ref.read(authProvider);
    final userId = authState.user?.id ?? 'guest-consumer';

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repository.getCart(userId);
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load cart: $e');
    }
  }

  Future<bool> addItem({
    required ProductModel product,
    required VariantModel variant,
    int quantity = 1,
    double? agreedPrice,
  }) async {
    final authState = ref.read(authProvider);
    final userId = authState.user?.id ?? 'guest-consumer';

    final success = await _repository.addToCart(
      consumerId: userId,
      product: product,
      variant: variant,
      quantity: quantity,
      agreedPrice: agreedPrice,
    );

    if (success) {
      await loadCart();
    }
    return success;
  }

  Future<void> updateQuantity(String cartItemId, int newQty) async {
    await _repository.updateCartQty(cartItemId, newQty);
    await loadCart();
  }

  Future<void> clearCart() async {
    state = state.copyWith(items: []);
  }
}

final cartProvider = NotifierProvider<CartController, CartState>(() {
  return CartController();
});
