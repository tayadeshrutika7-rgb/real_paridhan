import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_state.dart';
import '../data/seller_repository.dart';
import '../domain/shop_model.dart';
import '../domain/product_model.dart';
import '../domain/variant_model.dart';

class SellerState {
  final bool isLoading;
  final ShopModel? shop;
  final List<ProductModel> products;
  final String? errorMessage;
  final String? successMessage;

  const SellerState({
    this.isLoading = false,
    this.shop,
    this.products = const [],
    this.errorMessage,
    this.successMessage,
  });

  SellerState copyWith({
    bool? isLoading,
    ShopModel? shop,
    List<ProductModel>? products,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SellerState(
      isLoading: isLoading ?? this.isLoading,
      shop: shop ?? this.shop,
      products: products ?? this.products,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class SellerController extends Notifier<SellerState> {
  late final SellerRepository _repository;

  @override
  SellerState build() {
    _repository = SellerRepository();
    final authState = ref.watch(authProvider);
    final sellerId = authState.user?.id ?? 'mock-user-123';
    
    // Defer async loading to microtask to prevent mutating state during build
    Future.microtask(() => _loadShopAndProducts(sellerId));

    return const SellerState(isLoading: true);
  }

  Future<void> _loadShopAndProducts(String sellerId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final shop = await _repository.getShop(sellerId);
      List<ProductModel> products = [];
      if (shop != null) {
        products = await _repository.getProducts(shop.id);
      }
      state = state.copyWith(
        isLoading: false,
        shop: shop,
        products: products,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load shop details: $e',
      );
    }
  }

  Future<bool> saveShopProfile({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? description,
    List<String> categoryIds = const [],
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authState = ref.read(authProvider);
      final sellerId = authState.user?.id ?? 'mock-user-123';

      final existingShop = state.shop;
      final shopToSave = ShopModel(
        id: existingShop?.id ?? 'shop-${DateTime.now().millisecondsSinceEpoch}',
        sellerId: sellerId,
        name: name,
        description: description,
        address: address,
        latitude: latitude,
        longitude: longitude,
        categoryIds: categoryIds,
        status: existingShop?.status ?? 'pending',
        avgRating: existingShop?.avgRating ?? 0.0,
      );

      final saved = await _repository.saveShop(shopToSave);
      state = state.copyWith(
        isLoading: false,
        shop: saved,
        successMessage: 'Shop profile saved successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> createOrUpdateProduct({
    String? existingProductId,
    required String title,
    String? description,
    required String categoryId,
    required double basePrice,
    required double minBargainPrice,
    required bool bargainEnabled,
    required List<VariantModel> variants,
  }) async {
    if (minBargainPrice > basePrice) {
      state = state.copyWith(
        errorMessage: 'Minimum bargain floor price cannot exceed base price.',
      );
      return false;
    }

    if (variants.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Product must have at least one variant (size/color).',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final shopId = state.shop?.id ?? 'shop-jaipur-01';
      final productId = existingProductId ?? 'prod-${DateTime.now().millisecondsSinceEpoch}';

      final product = ProductModel(
        id: productId,
        shopId: shopId,
        categoryId: categoryId,
        title: title,
        description: description,
        basePrice: basePrice,
        minBargainPrice: minBargainPrice,
        bargainEnabled: bargainEnabled,
        status: 'active',
        variants: variants,
      );

      await _repository.createOrUpdateProduct(product, variants);
      final updatedProducts = await _repository.getProducts(shopId);

      state = state.copyWith(
        isLoading: false,
        products: updatedProducts,
        successMessage: 'Product published successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateStock(String variantId, int newStock) async {
    try {
      final success = await _repository.updateVariantStock(variantId, newStock);
      if (success && state.shop != null) {
        final updatedProducts = await _repository.getProducts(state.shop!.id);
        state = state.copyWith(products: updatedProducts);
      }
      return success;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update stock: $e');
      return false;
    }
  }

  Future<String> uploadAndCompressImage(Uint8List rawBytes) async {
    final shopId = state.shop?.id ?? 'shop-jaipur-01';
    return await _repository.uploadProductImage(shopId, rawBytes);
  }
}

final sellerProvider = NotifierProvider<SellerController, SellerState>(() {
  return SellerController();
});
