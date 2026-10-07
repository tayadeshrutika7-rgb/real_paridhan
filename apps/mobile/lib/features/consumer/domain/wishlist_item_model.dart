class WishlistItemModel {
  final String id;
  final String consumerId;
  final String productId;
  final String variantId;
  final String productTitle;
  final String shopId;
  final String shopName;
  final String size;
  final String color;
  final String imageUrl;
  final double originalPrice;
  final double currentPrice;
  final double? minBargainPrice;
  final bool bargainEnabled;
  final String targetDiscountNote;
  final DateTime createdAt;
  final int stockQty;

  const WishlistItemModel({
    required this.id,
    required this.consumerId,
    required this.productId,
    required this.variantId,
    required this.productTitle,
    required this.shopId,
    this.shopName = 'Local Boutique',
    required this.size,
    required this.color,
    required this.imageUrl,
    required this.originalPrice,
    required this.currentPrice,
    this.minBargainPrice,
    this.bargainEnabled = false,
    this.targetDiscountNote = 'Waiting for discount / price drop',
    required this.createdAt,
    this.stockQty = 5,
  });

  double get discountPercentage {
    if (originalPrice <= currentPrice || originalPrice <= 0) return 0.0;
    return ((originalPrice - currentPrice) / originalPrice) * 100;
  }

  double get potentialSavings => originalPrice > currentPrice ? originalPrice - currentPrice : 0.0;

  double get maxBargainDiscount {
    if (minBargainPrice != null && minBargainPrice! < currentPrice) {
      return currentPrice - minBargainPrice!;
    }
    return 0.0;
  }

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: json['id'] as String? ?? 'w-${DateTime.now().millisecondsSinceEpoch}',
      consumerId: json['consumer_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      variantId: json['variant_id'] as String? ?? '',
      productTitle: json['product_title'] as String? ?? 'Handcrafted Ethnic Garment',
      shopId: json['shop_id'] as String? ?? 'shop-amravati',
      shopName: json['shop_name'] as String? ?? 'Local Boutique',
      size: json['size'] as String? ?? 'Standard',
      color: json['color'] as String? ?? 'Standard',
      imageUrl: json['image_url'] as String? ?? 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400',
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? (json['base_price'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      minBargainPrice: (json['min_bargain_price'] as num?)?.toDouble(),
      bargainEnabled: json['bargain_enabled'] as bool? ?? false,
      targetDiscountNote: json['target_discount_note'] as String? ?? 'Waiting for discount / price drop',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      stockQty: json['stock_qty'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consumer_id': consumerId,
      'product_id': productId,
      'variant_id': variantId,
      'product_title': productTitle,
      'shop_id': shopId,
      'shop_name': shopName,
      'size': size,
      'color': color,
      'image_url': imageUrl,
      'original_price': originalPrice,
      'current_price': currentPrice,
      'min_bargain_price': minBargainPrice,
      'bargain_enabled': bargainEnabled,
      'target_discount_note': targetDiscountNote,
      'created_at': createdAt.toIso8601String(),
      'stock_qty': stockQty,
    };
  }

  WishlistItemModel copyWith({
    String? id,
    String? consumerId,
    String? productId,
    String? variantId,
    String? productTitle,
    String? shopId,
    String? shopName,
    String? size,
    String? color,
    String? imageUrl,
    double? originalPrice,
    double? currentPrice,
    double? minBargainPrice,
    bool? bargainEnabled,
    String? targetDiscountNote,
    DateTime? createdAt,
    int? stockQty,
  }) {
    return WishlistItemModel(
      id: id ?? this.id,
      consumerId: consumerId ?? this.consumerId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      productTitle: productTitle ?? this.productTitle,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      size: size ?? this.size,
      color: color ?? this.color,
      imageUrl: imageUrl ?? this.imageUrl,
      originalPrice: originalPrice ?? this.originalPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      minBargainPrice: minBargainPrice ?? this.minBargainPrice,
      bargainEnabled: bargainEnabled ?? this.bargainEnabled,
      targetDiscountNote: targetDiscountNote ?? this.targetDiscountNote,
      createdAt: createdAt ?? this.createdAt,
      stockQty: stockQty ?? this.stockQty,
    );
  }
}
