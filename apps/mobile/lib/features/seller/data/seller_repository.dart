import 'package:flutter/foundation.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/utils/image_compressor.dart';
import '../domain/shop_model.dart';
import '../domain/product_model.dart';
import '../domain/variant_model.dart';

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
      description: 'Authentic Rajasthani handblock prints, Bandhani sarees, and festive kurtas.',
      address: 'Shop 14, Johari Bazaar, Pink City, Jaipur, Rajasthan 302003',
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

    try {
      final res = await client
          .from('shops')
          .select()
          .eq('seller_id', sellerId)
          .maybeSingle();

      if (res != null) {
        return ShopModel.fromJson(res);
      }
      return null;
    } catch (e) {
      debugPrint('[SellerRepository] Error loading shop: $e');
      return _mockShop;
    }
  }

  Future<ShopModel> saveShop(ShopModel shop) async {
    final client = SupabaseService.client;
    if (client == null) {
      _mockShop = shop;
      return shop;
    }

    try {
      final data = shop.toJson();
      final res = await client.from('shops').upsert(data).select().single();
      return ShopModel.fromJson(res);
    } catch (e) {
      debugPrint('[SellerRepository] Error saving shop: $e');
      _mockShop = shop;
      return shop;
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
      return updatedProduct;
    }

    try {
      final productData = product.toJson();
      final productRes = await client.from('products').upsert(productData).select().single();
      final createdProduct = ProductModel.fromJson(productRes);

      // Upsert variants
      final List<VariantModel> savedVariants = [];
      for (final variant in variants) {
        final variantData = variant.copyWith(productId: createdProduct.id).toJson();
        final varRes = await client.from('product_variants').upsert(variantData).select().single();
        savedVariants.add(VariantModel.fromJson(varRes));
      }

      return createdProduct.copyWith(variants: savedVariants);
    } catch (e) {
      debugPrint('[SellerRepository] Error creating product: $e');
      return product.copyWith(variants: variants);
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
}
