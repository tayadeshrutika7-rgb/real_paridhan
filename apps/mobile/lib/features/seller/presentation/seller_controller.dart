import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_state.dart';
import '../data/seller_repository.dart';
import '../domain/shop_model.dart';
import '../domain/product_model.dart';
import '../domain/variant_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/notifications/domain/app_notification_model.dart';
import '../../../core/notifications/presentation/role_notification_controller.dart';
import '../../admin/presentation/admin_controller.dart';

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
  final SellerRepository _repository = SellerRepository();

  @override
  SellerState build() {
    final authState = ref.watch(authProvider);
    final sellerId = authState.user?.id ?? SupabaseService.client?.auth.currentUser?.id ?? '';
    
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
    String? ownerName,
    required String address,
    required double latitude,
    required double longitude,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    String? contactPhone,
    String? contactEmail,
    String? bankAccountNumber,
    String? bankIfsc,
    String? bankName,
    String? bankAccountName,
    String? gstin,
    String? panNumber,
    String? businessType,
    String? tradeLicenseNumber,
    String? aadhaarNumber,
    String? pincode,
    String? landmark,
    List<String>? kycDocuments,
    List<String> categoryIds = const [],
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authState = ref.read(authProvider);
      final sellerId = authState.user?.id ?? SupabaseService.client?.auth.currentUser?.id ?? '';

      if (sellerId.isEmpty || sellerId.startsWith('mock')) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Please sign in with your seller account before submitting your boutique profile.',
        );
        return false;
      }

      final existingShop = state.shop;
      final shopToSave = ShopModel(
        id: existingShop?.id ?? 'shop-${DateTime.now().millisecondsSinceEpoch}',
        sellerId: sellerId,
        name: name,
        ownerName: ownerName ?? existingShop?.ownerName,
        description: description ?? existingShop?.description,
        logoUrl: logoUrl ?? existingShop?.logoUrl,
        bannerUrl: bannerUrl ?? existingShop?.bannerUrl,
        address: address,
        contactPhone: contactPhone ?? existingShop?.contactPhone,
        contactEmail: contactEmail ?? existingShop?.contactEmail,
        bankAccountNumber: bankAccountNumber ?? existingShop?.bankAccountNumber,
        bankIfsc: bankIfsc ?? existingShop?.bankIfsc,
        bankName: bankName ?? existingShop?.bankName,
        bankAccountName: bankAccountName ?? existingShop?.bankAccountName,
        gstin: gstin ?? existingShop?.gstin,
        panNumber: panNumber ?? existingShop?.panNumber,
        businessType: businessType ?? existingShop?.businessType ?? 'sole_proprietorship',
        tradeLicenseNumber: tradeLicenseNumber ?? existingShop?.tradeLicenseNumber,
        aadhaarNumber: aadhaarNumber ?? existingShop?.aadhaarNumber,
        pincode: pincode ?? existingShop?.pincode,
        landmark: landmark ?? existingShop?.landmark,
        kycDocuments: kycDocuments ?? existingShop?.kycDocuments ?? const [],
        latitude: latitude,
        longitude: longitude,
        categoryIds: categoryIds.isNotEmpty ? categoryIds : (existingShop?.categoryIds ?? const []),
        status: existingShop?.status ?? 'pending',
        kycStatus: existingShop?.kycStatus == 'not_started' ? 'pending' : (existingShop?.kycStatus ?? 'pending'),
        avgRating: existingShop?.avgRating ?? 0.0,
      );

      final saved = await _repository.saveShop(shopToSave);
      state = state.copyWith(
        isLoading: false,
        shop: saved,
        successMessage: 'Shop profile saved successfully!',
      );

      // Post notification to Admin role
      ref.read(roleNotificationProvider(UserRole.admin).notifier).postNotification(
        title: 'New Boutique KYC Review: $name 🏪',
        body: 'Boutique "$name" has submitted registration and KYC proof for Super Admin verification.',
        category: NotificationCategory.kyc,
        deepLink: '/admin',
      );

      // Invalidate Admin Provider so dashboard immediately shows pending shop
      ref.invalidate(adminProvider);

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
      final authState = ref.read(authProvider);
      final sellerId = authState.user?.id ?? SupabaseService.client?.auth.currentUser?.id ?? '';
      
      ShopModel? shop = state.shop;
      if (shop == null && sellerId.isNotEmpty) {
        shop = await _repository.getShop(sellerId);
      }

      if (shop == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No boutique shop profile found. Please fill and save your shop details in Edit Profile first.',
        );
        return false;
      }

      final product = ProductModel(
        id: existingProductId ?? '',
        shopId: shop.id,
        shopName: shop.name,
        sellerId: shop.sellerId,
        categoryId: categoryId,
        title: title,
        description: description,
        basePrice: basePrice,
        minBargainPrice: minBargainPrice,
        bargainEnabled: bargainEnabled,
        status: 'active',
        variants: variants,
      );

      final published = await _repository.createOrUpdateProduct(product, variants);
      final updatedProducts = await _repository.getProducts(shop.id);

      state = state.copyWith(
        isLoading: false,
        shop: shop,
        products: updatedProducts.isNotEmpty ? updatedProducts : [published],
        successMessage: 'Product published successfully!',
      );
      return true;
    } catch (e) {
      debugPrint('[SellerController] Error creating product: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to publish product: $e',
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
