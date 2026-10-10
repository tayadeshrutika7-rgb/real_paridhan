import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/utils/image_compressor.dart';
import '../domain/shop_model.dart';
import '../domain/product_model.dart';
import '../domain/variant_model.dart';
import '../../consumer/data/consumer_repository.dart';

class SellerRepository {
  // In-memory cache for offline/mock dev
  static ShopModel? _mockShop;
  static final List<ProductModel> _mockProducts = [];

  SellerRepository() {
    if (_mockProducts.isEmpty) {
      _initMocks();
    }
  }

  void _initMocks() {
    _mockShop = const ShopModel(
      id: 'shop-jaipur-01',
      sellerId: 'mock-user-123',
      name: 'Jaipur Heritage Handlooms',
      ownerName: 'Rajesh Sharma',
      description: 'Authentic Rajasthani handblock prints, Bandhani sarees, and festive kurtas.',
      logoUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=400',
      bannerUrl: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=1200',
      address: 'Shop 14, Johari Bazaar, Pink City, Jaipur, Rajasthan 302003',
      contactPhone: '+91 98290 12345',
      contactEmail: 'rajesh.handlooms@jaipur.in',
      bankAccountNumber: '91827364501234',
      bankIfsc: 'HDFC0001234',
      bankName: 'HDFC Bank - Johari Bazaar Branch',
      latitude: 26.9200,
      longitude: 75.8267,
      status: 'verified',
      avgRating: 4.8,
      kycStatus: 'verified',
    );

    _mockProducts.addAll([
      const ProductModel(
        id: 'prod-001',
        shopId: 'shop-jaipur-01',
        categoryId: 'b0000001-0000-0000-0000-000000000001',
        title: 'Pure Cotton Handblock Anarkali Kurta',
        description: 'Traditional Sanganeri handblock print cotton kurta with gota patti detailing.',
        basePrice: 1899.00,
        minBargainPrice: 1499.00,
        bargainEnabled: true,
        status: 'active',
        variants: [
          VariantModel(
            id: 'var-001-s',
            productId: 'prod-001',
            size: 'S',
            color: 'Indigo Blue',
            stockQty: 8,
            sku: 'JPR-KUR-S',
            imageUrls: ['https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600'],
          ),
          VariantModel(
            id: 'var-001-m',
            productId: 'prod-001',
            size: 'M',
            color: 'Indigo Blue',
            stockQty: 15,
            sku: 'JPR-KUR-M',
            imageUrls: ['https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600'],
          ),
          VariantModel(
            id: 'var-001-l',
            productId: 'prod-001',
            size: 'L',
            color: 'Indigo Blue',
            stockQty: 10,
            sku: 'JPR-KUR-L',
            imageUrls: ['https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600'],
          ),
        ],
      ),
      const ProductModel(
        id: 'prod-002',
        shopId: 'shop-jaipur-01',
        categoryId: 'b0000001-0000-0000-0000-000000000002',
        title: 'Royal Chanderi Silk Festive Saree',
        description: 'Exquisite handwoven Chanderi silk saree with zari border and matching blouse piece.',
        basePrice: 3499.00,
        minBargainPrice: 2899.00,
        bargainEnabled: true,
        status: 'active',
        variants: [
          VariantModel(
            id: 'var-002-gold',
            productId: 'prod-002',
            size: 'Free Size',
            color: 'Champagne Gold',
            stockQty: 5,
            sku: 'JPR-SAR-GLD',
            imageUrls: ['https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600'],
          ),
        ],
      ),
    ]);
  }

  Future<ShopModel?> getShop(String sellerId) async {
    final client = SupabaseService.client;
    if (client == null) {
      return _mockShop;
    }

    String targetId = sellerId;
    if (targetId.isEmpty || targetId.startsWith('mock')) {
      final currentAuthId = client.auth.currentUser?.id;
      if (currentAuthId != null && currentAuthId.isNotEmpty) {
        targetId = currentAuthId;
      }
    }

    if (targetId.isEmpty || targetId.startsWith('mock')) {
      return null;
    }

    try {
      final res = await client
          .from('shops')
          .select()
          .eq('seller_id', targetId)
          .order('updated_at', ascending: false);

      if (res is List && res.isNotEmpty) {
        final list = res.map((r) => ShopModel.fromJson(r as Map<String, dynamic>)).toList();
        final verifiedShop = list.where((s) => s.isVerified).firstOrNull;
        return verifiedShop ?? list.first;
      }
      return null;
    } catch (e) {
      debugPrint('[SellerRepository] Error loading shop: $e');
      return null;
    }
  }

  static void updateMockShopStatus({
    required String status,
    required String kycStatus,
    String? reason,
    String? notes,
  }) {
    if (_mockShop != null) {
      _mockShop = _mockShop!.copyWith(
        status: status,
        kycStatus: kycStatus,
        kycRejectionReason: reason,
        kycNotes: notes,
        kycVerifiedAt: status == 'verified' ? DateTime.now() : null,
      );
    }
  }

  Future<ShopModel> saveShop(ShopModel shop) async {
    final client = SupabaseService.client;
    if (client == null) {
      _mockShop = shop;
      return shop;
    }

    // Resolve target seller ID
    String targetSellerId = shop.sellerId;
    if (targetSellerId.isEmpty || targetSellerId.startsWith('mock')) {
      final currentAuthId = client.auth.currentUser?.id;
      if (currentAuthId != null && currentAuthId.isNotEmpty) {
        targetSellerId = currentAuthId;
      }
    }

    if (targetSellerId.isEmpty || targetSellerId.startsWith('mock')) {
      throw Exception('Must be signed in with a valid seller account to register a boutique shop.');
    }

    try {
      // 1. Check if the seller already has an existing shop row in Supabase
      String? existingShopId;
      final existingRes = await client
          .from('shops')
          .select('id, status, is_verified, kyc_status')
          .eq('seller_id', targetSellerId)
          .order('updated_at', ascending: false);

      final existingList = existingRes as List;
      if (!shop.id.startsWith('shop-') && shop.id.isNotEmpty) {
        existingShopId = shop.id;
      } else if (existingList.isNotEmpty) {
        existingShopId = existingList.first['id'].toString();
      }

      // If duplicate rows exist for this seller, remove obsolete duplicate rows
      if (existingList.length > 1 && existingShopId != null) {
        for (final item in existingList) {
          final itemId = item['id'].toString();
          if (itemId != existingShopId) {
            try {
              await client.from('shops').delete().eq('id', itemId);
            } catch (_) {}
          }
        }
      }

      // 2. Prepare structured KYC metadata
      final extraKyc = <String, dynamic>{
        if (shop.ownerName != null && shop.ownerName!.isNotEmpty) 'owner_name': shop.ownerName,
        if (shop.gstin != null && shop.gstin!.isNotEmpty) 'gstin': shop.gstin,
        if (shop.panNumber != null && shop.panNumber!.isNotEmpty) 'pan_number': shop.panNumber,
        if (shop.contactPhone != null && shop.contactPhone!.isNotEmpty) 'contact_phone': shop.contactPhone,
        if (shop.contactEmail != null && shop.contactEmail!.isNotEmpty) 'contact_email': shop.contactEmail,
        if (shop.bankAccountNumber != null && shop.bankAccountNumber!.isNotEmpty) 'bank_account_number': shop.bankAccountNumber,
        if (shop.bankIfsc != null && shop.bankIfsc!.isNotEmpty) 'bank_ifsc': shop.bankIfsc,
        if (shop.bankName != null && shop.bankName!.isNotEmpty) 'bank_name': shop.bankName,
        if (shop.bankAccountName != null && shop.bankAccountName!.isNotEmpty) 'bank_account_name': shop.bankAccountName,
        if (shop.businessType != null && shop.businessType!.isNotEmpty) 'business_type': shop.businessType,
        if (shop.tradeLicenseNumber != null && shop.tradeLicenseNumber!.isNotEmpty) 'trade_license_number': shop.tradeLicenseNumber,
        if (shop.aadhaarNumber != null && shop.aadhaarNumber!.isNotEmpty) 'aadhaar_number': shop.aadhaarNumber,
        if (shop.pincode != null && shop.pincode!.isNotEmpty) 'pincode': shop.pincode,
        if (shop.landmark != null && shop.landmark!.isNotEmpty) 'landmark': shop.landmark,
        if (shop.kycDocuments.isNotEmpty) 'kyc_documents': shop.kycDocuments,
      };

      // Clean base description (strip old KYC metadata string if present)
      String cleanDesc = shop.description ?? '';
      if (cleanDesc.contains('[KYC_META]:')) {
        cleanDesc = cleanDesc.split('[KYC_META]:')[0].trim();
      }

      // 3. Prepare payload with standard columns matching PostgreSQL schema
      // Valid enum values in PostgreSQL: 'pending', 'verified', 'rejected', 'suspended'
      final resolvedKycStatus = (shop.kycStatus == 'approved' || shop.kycStatus == 'verified')
          ? 'verified'
          : (shop.kycStatus.isNotEmpty ? shop.kycStatus : 'pending');
      final resolvedStatus = (shop.status == 'approved' || shop.status == 'verified')
          ? 'verified'
          : (shop.status.isNotEmpty ? shop.status : 'pending');
      // is_verified is ONLY true when status is explicitly verified by admin
      final resolvedIsVerified = resolvedStatus == 'verified' && resolvedKycStatus == 'verified';

      // Store kyc_submitted_at timestamp in extraKyc metadata (not in raw table column)
      if (resolvedKycStatus == 'pending' && !resolvedIsVerified && extraKyc.isNotEmpty) {
        extraKyc['kyc_submitted_at'] = DateTime.now().toIso8601String();
      }

      final String fullDesc = extraKyc.isNotEmpty
          ? (cleanDesc.isNotEmpty ? '$cleanDesc\n[KYC_META]:${jsonEncode(extraKyc)}' : '[KYC_META]:${jsonEncode(extraKyc)}')
          : cleanDesc;

      final payload = <String, dynamic>{
        'seller_id': targetSellerId,
        'name': shop.name,
        'description': fullDesc,
        'address': shop.address,
        'location': 'POINT(${shop.longitude} ${shop.latitude})',
        'status': resolvedStatus,
        'kyc_status': resolvedKycStatus,
        'is_verified': resolvedIsVerified,
        'commission_rate': shop.commissionRate,
      };

      if (shop.logoUrl != null && shop.logoUrl!.isNotEmpty) {
        payload['logo_url'] = shop.logoUrl;
      }
      if (shop.bannerUrl != null && shop.bannerUrl!.isNotEmpty) {
        payload['banner_url'] = shop.bannerUrl;
      }

      Map<String, dynamic> res;
      if (existingShopId != null && existingShopId.isNotEmpty) {
        payload['id'] = existingShopId;
        payload['updated_at'] = DateTime.now().toIso8601String();
        res = await client.from('shops').upsert(payload).select().single();
      } else {
        res = await client.from('shops').insert(payload).select().single();
      }

      final updated = ShopModel.fromJson(res);
      _mockShop = updated;
      return updated;
    } catch (e) {
      debugPrint('[SellerRepository] Fatal error saving shop to Supabase: $e');
      rethrow;
    }
  }

  Future<List<ProductModel>> getProducts(String shopId) async {
    final client = SupabaseService.client;
    if (client == null) {
      return List.from(_mockProducts);
    }

    try {
      final productsRes = await client
          .from('products')
          .select('*, product_variants(*)')
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

      return (productsRes as List<dynamic>).map((json) {
        final variantsJson = (json['product_variants'] as List<dynamic>?) ?? [];
        final variants = variantsJson.map((v) => VariantModel.fromJson(v)).toList();
        return ProductModel.fromJson(json, variants: variants);
      }).toList();
    } catch (e) {
      debugPrint('[SellerRepository] Error fetching products: $e');
      return List.from(_mockProducts);
    }
  }

  Future<ProductModel> createOrUpdateProduct(ProductModel product, List<VariantModel> variants) async {
    final client = SupabaseService.client;
    if (client == null) {
      final updatedVariants = variants.map((v) {
        if (v.id.isEmpty) {
          return v.copyWith(
            id: 'mock-var-${DateTime.now().millisecondsSinceEpoch}-${v.size}',
            productId: product.id,
          );
        }
        return v;
      }).toList();

      final updatedProduct = product.copyWith(variants: updatedVariants);
      final index = _mockProducts.indexWhere((p) => p.id == product.id);
      if (index >= 0) {
        _mockProducts[index] = updatedProduct;
      } else {
        _mockProducts.insert(0, updatedProduct);
      }
      ConsumerRepository.addOrUpdateMockProduct(updatedProduct);
      return updatedProduct;
    }

    try {
      final productPayload = product.toSupabasePayload();
      final isExistingUuid = product.id.isNotEmpty &&
          !product.id.startsWith('prod-') &&
          !product.id.startsWith('mock-');

      Map<String, dynamic> productRes;
      if (isExistingUuid) {
        productPayload['id'] = product.id;
        productPayload['updated_at'] = DateTime.now().toIso8601String();
        productRes = await client.from('products').upsert(productPayload).select().single();
      } else {
        productRes = await client.from('products').insert(productPayload).select().single();
      }

      final createdProduct = ProductModel.fromJson(productRes);

      // Upsert variants
      final List<VariantModel> savedVariants = [];
      for (final variant in variants) {
        final variantPayload = <String, dynamic>{
          'product_id': createdProduct.id,
          'size': variant.size,
          'color': variant.color,
          'stock_qty': variant.stockQty,
          if (variant.priceOverride != null) 'price_override': variant.priceOverride,
          if (variant.sku != null && variant.sku!.isNotEmpty) 'sku': variant.sku,
          'image_urls': variant.imageUrls,
        };

        final isVariantUuid = variant.id.isNotEmpty &&
            !variant.id.startsWith('var-') &&
            !variant.id.startsWith('mock-');

        Map<String, dynamic> varRes;
        if (isVariantUuid) {
          variantPayload['id'] = variant.id;
          variantPayload['updated_at'] = DateTime.now().toIso8601String();
          varRes = await client.from('product_variants').upsert(variantPayload).select().single();
        } else {
          varRes = await client.from('product_variants').insert(variantPayload).select().single();
        }
        savedVariants.add(VariantModel.fromJson(varRes));
      }

      // Record in product_images table if images are present
      for (final variant in variants) {
        for (int i = 0; i < variant.imageUrls.length; i++) {
          final imgUrl = variant.imageUrls[i];
          try {
            await client.from('product_images').insert({
              'product_id': createdProduct.id,
              'url': imgUrl,
              'display_order': i,
              'is_primary': i == 0,
            });
          } catch (_) {}
        }
      }

      final fullProduct = createdProduct.copyWith(variants: savedVariants);
      final index = _mockProducts.indexWhere((p) => p.id == fullProduct.id);
      if (index >= 0) {
        _mockProducts[index] = fullProduct;
      } else {
        _mockProducts.insert(0, fullProduct);
      }
      ConsumerRepository.addOrUpdateMockProduct(fullProduct);
      return fullProduct;
    } catch (e) {
      debugPrint('[SellerRepository] Fatal error creating product in Supabase: $e');
      rethrow;
    }
  }

  Future<bool> updateVariantStock(String variantId, int newStock) async {
    final client = SupabaseService.client;
    if (client == null) {
      for (int i = 0; i < _mockProducts.length; i++) {
        final p = _mockProducts[i];
        final vIndex = p.variants.indexWhere((v) => v.id == variantId);
        if (vIndex >= 0) {
          final updatedList = List<VariantModel>.from(p.variants);
          updatedList[vIndex] = updatedList[vIndex].copyWith(stockQty: newStock);
          _mockProducts[i] = p.copyWith(variants: updatedList);
          return true;
        }
      }
      return true;
    }

    try {
      await client
          .from('product_variants')
          .update({'stock_qty': newStock})
          .eq('id', variantId);
      return true;
    } catch (e) {
      debugPrint('[SellerRepository] Error updating stock: $e');
      return false;
    }
  }

  /// Compresses image client-side to <= 500KB and uploads to Supabase Storage
  Future<String> uploadProductImage(String shopId, Uint8List rawBytes) async {
    // 1. Client-side compression
    final compressedBytes = await ImageCompressor.compressImage(rawBytes);

    final client = SupabaseService.client;
    if (client == null) {
      debugPrint('[SellerRepository] Image compressed: ${rawBytes.lengthInBytes} -> ${compressedBytes.lengthInBytes} bytes');
      return 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600';
    }

    try {
      final fileName = '$shopId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await client.storage.from('product-images').uploadBinary(
            fileName,
            compressedBytes,
          );
      final publicUrl = client.storage.from('product-images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('[SellerRepository] Error uploading image: $e');
      return 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600';
    }
  }

  /// Fetches real orders for this boutique shop from Supabase
  Future<List<Map<String, dynamic>>> getOrders(String shopId) async {
    final client = SupabaseService.client;
    if (client == null || shopId.isEmpty || shopId.startsWith('mock')) {
      return [];
    }
    try {
      final res = await client
          .from('orders')
          .select('id, order_number, status, subtotal, total_amount, seller_payout_amount, payment_status, created_at')
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);
      if (res is List) {
        return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[SellerRepository] Error fetching real orders: $e');
      return [];
    }
  }

  /// Fetches real bargains received by this seller or for shop products
  Future<List<Map<String, dynamic>>> getBargains(String sellerId, List<String> productIds) async {
    final client = SupabaseService.client;
    if (client == null) return [];
    try {
      if (sellerId.isNotEmpty && !sellerId.startsWith('mock')) {
        final res = await client
            .from('bargains')
            .select('id, product_id, seller_id, status, agreed_price, current_offer, created_at')
            .eq('seller_id', sellerId)
            .order('created_at', ascending: false);
        if (res is List && res.isNotEmpty) {
          return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
      if (productIds.isNotEmpty) {
        final res = await client
            .from('bargains')
            .select('id, product_id, seller_id, status, agreed_price, current_offer, created_at')
            .inFilter('product_id', productIds)
            .order('created_at', ascending: false);
        if (res is List) {
          return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[SellerRepository] Error fetching real bargains: $e');
      return [];
    }
  }

  /// Fetches real wishlist count for products belonging to this shop
  Future<int> getWishlistCount(List<String> productIds) async {
    final client = SupabaseService.client;
    if (client == null || productIds.isEmpty) return 0;
    int count = 0;
    try {
      final res1 = await client.from('wishlists').select('id').inFilter('product_id', productIds);
      if (res1 is List) count += res1.length;
    } catch (_) {}
    try {
      final res2 = await client.from('wishlist_items').select('id').inFilter('product_id', productIds);
      if (res2 is List) count += res2.length;
    } catch (_) {}
    return count;
  }

  /// Fetches real store views from advertisement impressions / clicks for this seller
  Future<int> getStoreViewsCount(String sellerId) async {
    final client = SupabaseService.client;
    if (client == null || sellerId.isEmpty || sellerId.startsWith('mock')) return 0;
    int views = 0;
    try {
      final res = await client.from('advertisements').select('impressions, clicks').eq('seller_id', sellerId);
      if (res is List) {
        for (final ad in res) {
          final m = ad as Map;
          views += ((m['impressions'] as num?)?.toInt() ?? 0) + ((m['clicks'] as num?)?.toInt() ?? 0);
        }
      }
    } catch (_) {}
    return views;
  }
}

