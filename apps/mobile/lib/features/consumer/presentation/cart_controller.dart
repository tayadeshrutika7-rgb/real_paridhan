import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_state.dart';
import '../../seller/domain/product_model.dart';
import '../../seller/domain/variant_model.dart';
import '../data/consumer_repository.dart';
import '../domain/cart_item_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/notifications/domain/app_notification_model.dart';
import '../../../core/notifications/presentation/role_notification_controller.dart';

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
  final ConsumerRepository _repository = ConsumerRepository();

  @override
  CartState build() {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.id;
    if (userId == null || authState.isGuest || userId.startsWith('guest')) {
      return const CartState(isLoading: false, items: []);
    }
    Future.microtask(() => loadCart(userId: userId));
    return const CartState(isLoading: true);
  }

  Future<void> loadCart({String? userId}) async {
    final authState = ref.read(authProvider);
    final effectiveUserId = userId ?? authState.user?.id;
    if (effectiveUserId == null || authState.isGuest || effectiveUserId.startsWith('guest')) {
      state = const CartState(isLoading: false, items: []);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dbItems = await _repository.getCart(effectiveUserId);
      
      // Preserve any in-memory bargain items if db didn't return them
      final currentBargainItems = state.items.where((i) => i.hasBargainPrice || i.bargainId != null).toList();
      final merged = List<CartItemModel>.from(dbItems);
      for (final bItem in currentBargainItems) {
        final alreadyPresent = merged.any(
          (m) => m.id == bItem.id ||
                 (m.bargainId != null && m.bargainId == bItem.bargainId) ||
                 (m.variantId.isNotEmpty && m.variantId == bItem.variantId),
        );
        if (!alreadyPresent) {
          merged.insert(0, bItem);
        }
      }

      state = state.copyWith(isLoading: false, items: merged);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load cart: $e');
    }
  }

  Future<void> addBargainDealToCart(dynamic bargain) async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null || authState.isGuest || user.id.startsWith('guest')) {
      return;
    }
    final userId = user.id;
    final double effectiveAgreedPrice = (bargain.agreedPrice as num?)?.toDouble() ??
        (bargain.consumerOffer as num?)?.toDouble() ??
        0.0;
    final double basePrice = (bargain.basePrice as num?)?.toDouble() ?? effectiveAgreedPrice;
    final String bargainId = bargain.id as String? ?? 'b-${DateTime.now().millisecondsSinceEpoch}';
    final String variantId = bargain.variantId as String? ?? 'var-$bargainId';
    final String productId = bargain.productId as String? ?? 'prod-$bargainId';
    final String title = bargain.productTitle as String? ?? 'Handcrafted Garment';
    final String? imgUrl = bargain.productImageUrl as String?;
    final String sellerId = bargain.sellerId as String? ?? 'shop-amravati';

    final currentItems = List<CartItemModel>.from(state.items);
    final existingIndex = currentItems.indexWhere(
      (item) => (variantId.isNotEmpty && item.variantId == variantId) ||
                (item.bargainId == bargainId) ||
                (productId.isNotEmpty && item.productId == productId),
    );

    final cartItem = CartItemModel(
      id: existingIndex >= 0 ? currentItems[existingIndex].id : 'deal-$bargainId',
      consumerId: userId,
      variantId: variantId,
      productId: productId,
      productTitle: title,
      size: bargain.variantLabel as String? ?? (existingIndex >= 0 ? currentItems[existingIndex].size : 'Standard'),
      color: existingIndex >= 0 ? currentItems[existingIndex].color : 'Standard',
      quantity: existingIndex >= 0 ? currentItems[existingIndex].quantity : 1,
      imageUrl: (imgUrl != null && imgUrl.isNotEmpty)
          ? imgUrl
          : (existingIndex >= 0 ? currentItems[existingIndex].imageUrl : 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400'),
      unitPrice: basePrice > 0 ? basePrice : (existingIndex >= 0 ? currentItems[existingIndex].unitPrice : effectiveAgreedPrice),
      agreedPrice: effectiveAgreedPrice,
      bargainId: bargainId,
      shopId: sellerId,
      shopName: 'Local Boutique (Amravati)',
    );

    if (existingIndex >= 0) {
      currentItems[existingIndex] = cartItem;
    } else {
      currentItems.insert(0, cartItem);
    }

    state = state.copyWith(isLoading: false, items: currentItems, clearError: true);

    // Save to repository in background
    try {
      await _repository.addBargainToCart(
        consumerId: userId,
        bargain: bargain,
        agreedPrice: effectiveAgreedPrice,
      );
    } catch (_) {}
  }

  Future<bool> addItem({
    required ProductModel product,
    required VariantModel variant,
    int quantity = 1,
    double? agreedPrice,
  }) async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null || authState.isGuest || user.id.startsWith('guest')) {
      return false;
    }
    final userId = user.id;

    final success = await _repository.addToCart(
      consumerId: userId,
      product: product,
      variant: variant,
      quantity: quantity,
      agreedPrice: agreedPrice,
    );

    if (success) {
      await loadCart();
      // Post strictly to customer role notification state
      await ref.read(roleNotificationProvider(UserRole.consumer).notifier).postNotification(
        title: 'Added to Cart',
        body: '${product.title} has been added to your shopping cart.',
        category: NotificationCategory.cart,
        deepLink: '/cart',
      );
    }
    return success;
  }

  Future<void> updateQuantity(String cartItemId, int newQty) async {
    final idx = state.items.indexWhere((i) => i.id == cartItemId);
    if (idx >= 0) {
      final currentList = List<CartItemModel>.from(state.items);
      if (newQty <= 0) {
        currentList.removeAt(idx);
      } else {
        currentList[idx] = currentList[idx].copyWith(quantity: newQty);
      }
      state = state.copyWith(items: currentList);
    }
    await _repository.updateCartQty(cartItemId, newQty);
  }

  Future<void> removeItem(String cartItemId) async {
    final currentList = List<CartItemModel>.from(state.items)..removeWhere((i) => i.id == cartItemId);
    state = state.copyWith(items: currentList);
    await _repository.removeItem(cartItemId);
  }

  Future<void> clearCart() async {
    state = state.copyWith(items: []);
  }
}

final cartProvider = NotifierProvider<CartController, CartState>(() {
  return CartController();
});
