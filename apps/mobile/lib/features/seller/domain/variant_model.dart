class VariantModel {
  final String id;
  final String productId;
  final String size;
  final String color;
  final int stockQty;
  final double? priceOverride;
  final String? sku;
  final List<String> imageUrls;

  const VariantModel({
    required this.id,
    required this.productId,
    required this.size,
    required this.color,
    this.stockQty = 0,
    this.priceOverride,
    this.sku,
    this.imageUrls = const [],
  });

  double get price => priceOverride ?? 0.0;

  double effectivePrice(double fallbackBasePrice) =>
      priceOverride ?? fallbackBasePrice;

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    return VariantModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      size: json['size'] as String? ?? 'Free Size',
      color: json['color'] as String? ?? 'Standard',
      stockQty: json['stock_qty'] as int? ?? 0,
      priceOverride: (json['price_override'] as num?)?.toDouble(),
      sku: json['sku'] as String?,
      imageUrls: (json['image_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'size': size,
      'color': color,
      'stock_qty': stockQty,
      'price_override': priceOverride,
      'sku': sku,
      'image_urls': imageUrls,
    };
  }

  VariantModel copyWith({
    String? id,
    String? productId,
    String? size,
    String? color,
    int? stockQty,
    double? priceOverride,
    String? sku,
    List<String>? imageUrls,
  }) {
    return VariantModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      size: size ?? this.size,
      color: color ?? this.color,
      stockQty: stockQty ?? this.stockQty,
      priceOverride: priceOverride ?? this.priceOverride,
      sku: sku ?? this.sku,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}
