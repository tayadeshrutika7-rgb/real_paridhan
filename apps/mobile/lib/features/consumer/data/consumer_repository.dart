import 'package:flutter/foundation.dart';
import '../../../core/network/supabase_client.dart';
import '../../seller/domain/shop_model.dart';
import '../../seller/domain/product_model.dart';
import '../../seller/domain/variant_model.dart';
import '../domain/nearby_shop.dart';
import '../domain/cart_item_model.dart';

class ConsumerRepository {
  // In-memory fixtures for offline / development
  static final List<NearbyShop> _mockNearbyShops = [
    const NearbyShop(
      id: 'shop-jaipur-01',
      sellerId: 'seller-01',
      name: 'Jaipur Heritage Handlooms',
      description: 'Authentic Rajasthani handblock prints, Bandhani sarees, and festive kurtas.',
      address: 'Shop 14, Johari Bazaar, Jaipur',
      distanceMeters: 650.0,
      avgRating: 4.8,
      bannerUrl: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600',
      categoryIds: ['a0000001-0000-0000-0000-000000000004'],
    ),
    const NearbyShop(
      id: 'shop-jaipur-02',
      sellerId: 'seller-02',
      name: 'Pink City Silk & Weaves',
      description: 'Chanderi silks, bridal lehengas, and zari dupattas crafted by local artisans.',
      address: 'Bapu Bazaar, Jaipur',
      distanceMeters: 1400.0,
      avgRating: 4.9,
      bannerUrl: 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600',
      categoryIds: ['a0000001-0000-0000-0000-000000000004'],
    ),
    const NearbyShop(
      id: 'shop-jaipur-03',
      sellerId: 'seller-03',
      name: 'Khadi & Cotton Guild',
      description: 'Handspun organic khadi shirts, kurtas, and Nehru jackets.',
      address: 'MI Road, Jaipur',
      distanceMeters: 2800.0,
      avgRating: 4.6,
      bannerUrl: 'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600',
      categoryIds: ['a0000001-0000-0000-0000-000000000001'],
    ),
  ];

  static final List<ProductModel> _mockCatalog = [
    const ProductModel(
      id: 'prod-001',
      shopId: 'shop-jaipur-01',
      categoryId: 'b0000001-0000-0000-0000-000000000001',
      title: 'Pure Cotton Handblock Anarkali Kurta',
      description: 'Traditional Sanganeri handblock print cotton kurta with gota patti detailing. 100% breathable organic cotton.',
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
      shopId: 'shop-jaipur-02',
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
        VariantModel(
          id: 'var-002-ruby',
          productId: 'prod-002',
          size: 'Free Size',
          color: 'Ruby Red',
          stockQty: 7,
          sku: 'JPR-SAR-RBY',
          imageUrls: ['https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600'],
        ),
      ],
    ),
    const ProductModel(
      id: 'prod-003',
      shopId: 'shop-jaipur-03',
      categoryId: 'b0000001-0000-0000-0000-000000000003',
      title: 'Handspun Khadi Mandarin Collar Shirt',
      description: 'Breathable handwoven natural khadi casual shirt for men. Styled with wooden buttons and regular fit.',
      basePrice: 1299.00,
      minBargainPrice: 999.00,
      bargainEnabled: true,
      status: 'active',
      variants: [
        VariantModel(
          id: 'var-003-m',
          productId: 'prod-003',
          size: 'M',
          color: 'Off-White',
          stockQty: 12,
          sku: 'KHD-SHR-M',
          imageUrls: ['https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600'],
        ),
        VariantModel(
          id: 'var-003-l',
          productId: 'prod-003',
          size: 'L',
          color: 'Off-White',
          stockQty: 14,
          sku: 'KHD-SHR-L',
          imageUrls: ['https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=600'],
        ),
      ],
    ),
  ];

  static final List<CartItemModel> _mockCart = [];

  Future<List<NearbyShop>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      return List.from(_mockNearbyShops);
    }

    try {
      final res = await client.rpc(
        'get_nearby_shops',
        params: {
          'lat': latitude,
          'lng': longitude,
          'radius_km': radiusKm,
        },
      );

      final List<dynamic> list = res as List<dynamic>;
      return list.map((json) => NearbyShop.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[ConsumerRepository] Error running get_nearby_shops RPC: $e');
      return List.from(_mockNearbyShops);
    }
  }

  Future<List<ProductModel>> searchProducts({
    String query = '',
    double? minPrice,
    double? maxPrice,
    String? categoryId,
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      final cleanQuery = query.toLowerCase().trim();
      return _mockCatalog.where((p) {
        final matchesQuery = cleanQuery.isEmpty ||
            p.title.toLowerCase().contains(cleanQuery) ||
            (p.description?.toLowerCase().contains(cleanQuery) ?? false);
        final matchesMin = minPrice == null || p.basePrice >= minPrice;
        final matchesMax = maxPrice == null || p.basePrice <= maxPrice;
        final matchesCategory = categoryId == null || p.categoryId == categoryId;
        return matchesQuery && matchesMin && matchesMax && matchesCategory;
      }).toList();
    }

    try {
      var dbQuery = client.from('products').select('*, product_variants(*)').eq('status', 'active');
      if (query.isNotEmpty) {
        dbQuery = dbQuery.textSearch('search_vector', query);
      }
      if (minPrice != null) dbQuery = dbQuery.gte('base_price', minPrice);
      if (maxPrice != null) dbQuery = dbQuery.lte('base_price', maxPrice);
      if (categoryId != null) dbQuery = dbQuery.eq('category_id', categoryId);

      final res = await dbQuery;
      return (res as List<dynamic>).map((json) {
        final variantsJson = (json['product_variants'] as List<dynamic>?) ?? [];
        final variants = variantsJson.map((v) => VariantModel.fromJson(v)).toList();
        return ProductModel.fromJson(json, variants: variants);
      }).toList();
    } catch (e) {
      debugPrint('[ConsumerRepository] Error searching products: $e');
      return _mockCatalog;
    }
  }

  Future<ShopModel?> getShopDetails(String shopId) async {
    final client = SupabaseService.client;
    if (client == null) {
      final nearby = _mockNearbyShops.firstWhere(
        (s) => s.id == shopId,
        orElse: () => _mockNearbyShops.first,
      );
      return ShopModel(
        id: nearby.id,
        sellerId: nearby.sellerId,
        name: nearby.name,
        description: nearby.description,
        address: nearby.address,
        latitude: 26.9200,
        longitude: 75.8267,
        avgRating: nearby.avgRating,
        bannerUrl: nearby.bannerUrl,
        status: 'verified',
      );
    }

    try {
      final res = await client.from('shops').select().eq('id', shopId).maybeSingle();
      return res != null ? ShopModel.fromJson(res) : null;
    } catch (e) {
      debugPrint('[ConsumerRepository] Error getting shop: $e');
      return null;
    }
  }

  Future<ProductModel?> getProductDetails(String productId) async {
    final client = SupabaseService.client;
    if (client == null) {
      try {
        return _mockCatalog.firstWhere((p) => p.id == productId);
      } catch (_) {
        return _mockCatalog.first;
      }
    }

    try {
      final res = await client
          .from('products')
          .select('*, product_variants(*), shops(id, name, seller_id)')
          .eq('id', productId)
          .maybeSingle();

      if (res != null) {
        final variantsJson = (res['product_variants'] as List<dynamic>?) ?? [];
        final variants = variantsJson.map((v) => VariantModel.fromJson(v)).toList();
        return ProductModel.fromJson(res, variants: variants);
      }
      return null;
    } catch (e) {
      debugPrint('[ConsumerRepository] Error getting product: $e');
      return null;
    }
  }

  Future<List<CartItemModel>> getCart(String consumerId) async {
    final client = SupabaseService.client;
    if (client == null) {
      return List.from(_mockCart);
    }

    try {
      final res = await client.from('cart_items').select('''
        id,
        consumer_id,
        variant_id,
        quantity,
        agreed_price,
        product_variants (
          size,
          color,
          price_override,
          image_urls,
          products (
            id,
            title,
            base_price,
            product_images (
              url
            ),
            shops (
              id,
              name
            )
          )
        )
      ''').eq('consumer_id', consumerId);

      return (res as List<dynamic>).map((item) {
        final variant = item['product_variants'] as Map<String, dynamic>? ?? {};
        final product = variant['products'] as Map<String, dynamic>? ?? {};
        final shop = product['shops'] as Map<String, dynamic>? ?? {};
        final variantImages = (variant['image_urls'] as List<dynamic>?) ?? [];
        final prodImages = (product['product_images'] as List<dynamic>?) ?? [];

        String imgUrl = '';
        if (variantImages.isNotEmpty && variantImages.first is String && (variantImages.first as String).isNotEmpty) {
          imgUrl = variantImages.first as String;
        } else if (prodImages.isNotEmpty && prodImages.first is Map && (prodImages.first['url'] as String?)?.isNotEmpty == true) {
          imgUrl = prodImages.first['url'] as String;
        } else {
          imgUrl = 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400';
        }

        return CartItemModel(
          id: item['id'] as String,
          consumerId: item['consumer_id'] as String,
          variantId: item['variant_id'] as String,
          productId: product['id'] as String? ?? '',
          productTitle: product['title'] as String? ?? 'Fashion Garment',
          size: variant['size'] as String? ?? 'Standard',
          color: variant['color'] as String? ?? 'Classic',
          quantity: item['quantity'] as int? ?? 1,
          imageUrl: imgUrl,
          unitPrice: (variant['price_override'] as num?)?.toDouble() ??
              (product['base_price'] as num?)?.toDouble() ?? 0.0,
          agreedPrice: (item['agreed_price'] as num?)?.toDouble(),
          shopId: shop['id'] as String? ?? '',
          shopName: shop['name'] as String? ?? 'Local Boutique',
        );
      }).toList();
    } catch (e) {
      debugPrint('[ConsumerRepository] Error fetching cart: $e');
      return List.from(_mockCart);
    }
  }

  Future<bool> addToCart({
    required String consumerId,
    required ProductModel product,
    required VariantModel variant,
    int quantity = 1,
    double? agreedPrice,
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      final existingIndex = _mockCart.indexWhere((c) => c.variantId == variant.id);
      if (existingIndex >= 0) {
        final existing = _mockCart[existingIndex];
        _mockCart[existingIndex] = existing.copyWith(
          quantity: existing.quantity + quantity,
          agreedPrice: agreedPrice ?? existing.agreedPrice,
        );
      } else {
        _mockCart.add(
          CartItemModel(
            id: 'mock-cart-${DateTime.now().millisecondsSinceEpoch}',
            consumerId: consumerId,
            variantId: variant.id,
            productId: product.id,
            productTitle: product.title,
            size: variant.size,
            color: variant.color,
            quantity: quantity,
            imageUrl: variant.imageUrls.isNotEmpty ? variant.imageUrls.first : product.primaryImageUrl,
            unitPrice: variant.priceOverride ?? product.basePrice,
            agreedPrice: agreedPrice,
            shopId: product.shopId,
            shopName: 'Local Boutique',
          ),
        );
      }
      return true;
    }

    try {
      double? finalAgreedPrice = agreedPrice;
      if (finalAgreedPrice == null) {
        try {
          final existingBargain = await client
              .from('bargains')
              .select('agreed_price')
              .eq('consumer_id', consumerId)
              .eq('variant_id', variant.id)
              .eq('status', 'accepted')
              .order('updated_at', ascending: false)
              .limit(1)
              .maybeSingle();

          if (existingBargain != null && existingBargain['agreed_price'] != null) {
            finalAgreedPrice = (existingBargain['agreed_price'] as num).toDouble();
          }
        } catch (_) {}
      }

      final upsertData = <String, dynamic>{
        'consumer_id': consumerId,
        'product_id': product.id,
        'variant_id': variant.id,
        'quantity': quantity,
      };
      if (finalAgreedPrice != null) {
        upsertData['agreed_price'] = finalAgreedPrice;
      }

      await client.from('cart_items').upsert(upsertData, onConflict: 'consumer_id,variant_id');
      return true;
    } catch (e) {
      debugPrint('[ConsumerRepository] Error adding to cart: $e');
      return false;
    }
  }

  Future<bool> updateCartQty(String cartItemId, int newQty) async {
    final client = SupabaseService.client;
    if (client == null) {
      final idx = _mockCart.indexWhere((c) => c.id == cartItemId);
      if (idx >= 0) {
        if (newQty <= 0) {
          _mockCart.removeAt(idx);
        } else {
          _mockCart[idx] = _mockCart[idx].copyWith(quantity: newQty);
        }
      }
      return true;
    }

    try {
      if (newQty <= 0) {
        await client.from('cart_items').delete().eq('id', cartItemId);
      } else {
        await client.from('cart_items').update({'quantity': newQty}).eq('id', cartItemId);
      }
      return true;
    } catch (e) {
      debugPrint('[ConsumerRepository] Error updating cart qty: $e');
      return false;
    }
  }

  Future<bool> removeItem(String cartItemId) async {
    final client = SupabaseService.client;
    if (client == null) {
      _mockCart.removeWhere((c) => c.id == cartItemId);
      return true;
    }

    try {
      await client.from('cart_items').delete().eq('id', cartItemId);
      return true;
    } catch (e) {
      debugPrint('[ConsumerRepository] Error removing cart item: $e');
      return false;
    }
  }
}
