import 'variant_model.dart';

class ProductModel {
  final String id;
  final String shopId;
  final String? shopName;
  final String sellerId;   // owner of the shop
  final String categoryId;
  final String? brandId;
  final String title;
  final String? description;
  final double basePrice;
  final double minBargainPrice;
  final bool bargainEnabled;
  final String status; // active, draft, out_of_stock, removed
  final List<VariantModel> variants;
  final DateTime? createdAt;

  const ProductModel({
    required this.id,
    required this.shopId,
    this.shopName,
    this.sellerId = '',
    required this.categoryId,
    this.brandId,
    required this.title,
    this.description,
    required this.basePrice,
    required this.minBargainPrice,
    this.bargainEnabled = true,
    this.status = 'active',
    this.variants = const [],
    this.createdAt,
  });

  int get totalStock => variants.fold(0, (sum, v) => sum + v.stockQty);

  String get primaryImageUrl {
    for (final variant in variants) {
      if (variant.imageUrls.isNotEmpty) {
        return variant.imageUrls.first;
      }
    }
    return 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400';
  }

  factory ProductModel.fromJson(Map<String, dynamic> json, {List<VariantModel> variants = const []}) {
    return ProductModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      shopName: json['shop_name'] as String? ?? json['shops']?['name'] as String?,
      sellerId: json['seller_id'] as String? ?? json['shops']?['seller_id'] as String? ?? '',
      categoryId: json['category_id'] as String,
      brandId: json['brand_id'] as String?,
      title: json['title'] as String? ?? 'Untitled Product',
      description: json['description'] as String?,
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      minBargainPrice: (json['min_bargain_price'] as num?)?.toDouble() ?? 0.0,
      bargainEnabled: json['bargain_enabled'] as bool? ?? true,
      status: json['status'] as String? ?? 'draft',
      variants: variants,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'shop_name': shopName,
      'seller_id': sellerId,
      'category_id': categoryId,
      'brand_id': brandId,
      'title': title,
      'description': description,
      'base_price': basePrice,
      'min_bargain_price': minBargainPrice,
      'bargain_enabled': bargainEnabled,
      'status': status,
    };
  }

  ProductModel copyWith({
    String? id,
    String? shopId,
    String? shopName,
    String? sellerId,
    String? categoryId,
    String? brandId,
    String? title,
    String? description,
    double? basePrice,
    double? minBargainPrice,
    bool? bargainEnabled,
    String? status,
    List<VariantModel>? variants,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      sellerId: sellerId ?? this.sellerId,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      title: title ?? this.title,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      minBargainPrice: minBargainPrice ?? this.minBargainPrice,
      bargainEnabled: bargainEnabled ?? this.bargainEnabled,
      status: status ?? this.status,
      variants: variants ?? this.variants,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
