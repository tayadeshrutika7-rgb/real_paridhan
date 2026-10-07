import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_state.dart';
import '../../seller/domain/product_model.dart';
import '../../seller/domain/variant_model.dart';
import '../data/consumer_repository.dart';
import '../domain/wishlist_item_model.dart';
import 'cart_controller.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/notifications/domain/app_notification_model.dart';
import '../../../core/notifications/presentation/role_notification_controller.dart';

class WishlistState {
  final bool isLoading;
  final List<WishlistItemModel> items;
  final String? errorMessage;

  const WishlistState({
    this.isLoading = false,
    this.items = const [],
    this.errorMessage,
  });

  int get totalItems => items.length;

  double get totalOriginalValue => items.fold(0.0, (sum, i) => sum + i.originalPrice);
  double get totalCurrentValue => items.fold(0.0, (sum, i) => sum + i.currentPrice);
  double get totalSavingsPotential => items.fold(0.0, (sum, i) => sum + i.potentialSavings);
  double get totalBargainSavings => items.fold(0.0, (sum, i) => sum + i.maxBargainDiscount);

  bool isItemWishlisted(String productId, {String? variantId}) {
    return items.any(
      (item) => item.productId == productId && (variantId == null || variantId.isEmpty || item.variantId == variantId),
    );
  }

  WishlistState copyWith({
    bool? isLoading,
    List<WishlistItemModel>? items,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WishlistState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class WishlistController extends Notifier<WishlistState> {
  final ConsumerRepository _repository = ConsumerRepository();

  @override
  WishlistState build() {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    if (user == null || authState.isGuest || user.id.startsWith('guest')) {
      return const WishlistState(isLoading: false, items: []);
    }
    Future.microtask(() => loadWishlist(userId: user.id));
    return const WishlistState(isLoading: true);
  }

  Future<void> loadWishlist({String? userId}) async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    final effectiveUserId = userId ?? user?.id;

    if (effectiveUserId == null || authState.isGuest || effectiveUserId.startsWith('guest')) {
      state = state.copyWith(isLoading: false, items: []);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repository.getWishlist(effectiveUserId);
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load wishlist: $e');
    }
  }

  bool isWishlisted(String productId, {String? variantId}) {
    final authState = ref.read(authProvider);
    if (authState.isGuest || authState.user == null) return false;
    return state.isItemWishlisted(productId, variantId: variantId);
  }

  Future<bool> toggleWishlist({
    required ProductModel product,
    required VariantModel variant,
    String? shopName,
  }) async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    // Guests strictly cannot add or toggle wishlist items
    if (user == null || authState.isGuest || user.id.startsWith('guest')) {
      return false;
    }
    final userId = user.id;

    final alreadyWishlisted = isWishlisted(product.id, variantId: variant.id);

    if (alreadyWishlisted) {
      final item = state.items.firstWhere(
        (i) => i.productId == product.id && (variant.id.isEmpty || i.variantId == variant.id),
      );
      await removeFromWishlist(item.id, productId: product.id, variantId: variant.id);
      return false;
    } else {
      final double originalPrice = (product.basePrice * 1.35).roundToDouble();
      final newItem = WishlistItemModel(
        id: 'wish-${DateTime.now().millisecondsSinceEpoch}',
        consumerId: userId,
        productId: product.id,
        variantId: variant.id,
        productTitle: product.title,
        shopId: product.shopId,
        shopName: shopName ?? 'Local Boutique',
        size: variant.size,
        color: variant.color,
        imageUrl: variant.imageUrls.isNotEmpty ? variant.imageUrls.first : product.primaryImageUrl,
        originalPrice: originalPrice > product.basePrice ? originalPrice : product.basePrice * 1.25,
        currentPrice: variant.priceOverride ?? product.basePrice,
        minBargainPrice: product.minBargainPrice,
        bargainEnabled: product.bargainEnabled,
        targetDiscountNote: product.bargainEnabled
            ? 'Waiting for discount or bargaining offer'
            : 'Waiting for seasonal discount / price drop',
        createdAt: DateTime.now(),
        stockQty: variant.stockQty,
      );

      final currentList = List<WishlistItemModel>.from(state.items)..insert(0, newItem);
      state = state.copyWith(items: currentList);

      await _repository.addToWishlist(newItem);

      // Post strictly to customer role notification state
      await ref.read(roleNotificationProvider(UserRole.consumer).notifier).postNotification(
        title: 'Saved to Wishlist',
        body: '${product.title} has been added to your wishlist.',
        category: NotificationCategory.wishlist,
        deepLink: '/wishlist',
      );

      return true;
    }
  }

  Future<void> addToWishlist(WishlistItemModel item) async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null || authState.isGuest || user.id.startsWith('guest')) {
      return;
    }
    final currentList = List<WishlistItemModel>.from(state.items);
    final idx = currentList.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      currentList[idx] = item;
    } else {
      currentList.insert(0, item);
    }
    state = state.copyWith(items: currentList);
    await _repository.addToWishlist(item);

    // Post strictly to customer role notification state
    await ref.read(roleNotificationProvider(UserRole.consumer).notifier).postNotification(
      title: 'Saved to Wishlist',
      body: '${item.productTitle} has been added to your wishlist.',
      category: NotificationCategory.wishlist,
      deepLink: '/wishlist',
    );
  }

  Future<void> removeFromWishlist(String wishlistItemId, {String? productId, String? variantId}) async {
    final currentList = List<WishlistItemModel>.from(state.items)
      ..removeWhere((i) =>
          i.id == wishlistItemId ||
          (productId != null && i.productId == productId && (variantId == null || i.variantId == variantId)));
    state = state.copyWith(items: currentList);
    await _repository.removeFromWishlist(wishlistItemId, productId: productId, variantId: variantId);
  }

  Future<bool> moveToCart(WishlistItemModel item) async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null || authState.isGuest || user.id.startsWith('guest')) {
      return false;
    }

    // 1. Create a dummy ProductModel and VariantModel to add to Cart
    final product = ProductModel(
      id: item.productId,
      shopId: item.shopId,
      categoryId: '',
      title: item.productTitle,
      description: item.productTitle,
      basePrice: item.currentPrice,
      minBargainPrice: item.minBargainPrice ?? 0.0,
      bargainEnabled: item.bargainEnabled,
      variants: [
        VariantModel(
          id: item.variantId,
          productId: item.productId,
          size: item.size,
          color: item.color,
          stockQty: item.stockQty,
          sku: 'SKU-${item.variantId}',
          imageUrls: [item.imageUrl],
        ),
      ],
    );

    final variant = product.variants.first;

    final cartCtrl = ref.read(cartProvider.notifier);
    final success = await cartCtrl.addItem(product: product, variant: variant, quantity: 1);

    if (success) {
      await removeFromWishlist(item.id);
    }
    return success;
  }

  Future<void> clearWishlist() async {
    state = state.copyWith(items: []);
  }
}

final wishlistProvider = NotifierProvider<WishlistController, WishlistState>(() {
  return WishlistController();
});
