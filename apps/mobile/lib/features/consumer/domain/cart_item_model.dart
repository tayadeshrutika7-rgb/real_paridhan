class CartItemModel {
  final String id;
  final String consumerId;
  final String variantId;
  final String productId;
  final String productTitle;
  final String size;
  final String color;
  final int quantity;
  final String imageUrl;
  final double unitPrice;
  final double? agreedPrice; // Negotiated via Bargaining state machine
  final String? bargainId;
  final String shopId;
  final String shopName;

  const CartItemModel({
    required this.id,
    required this.consumerId,
    required this.variantId,
    required this.productId,
    required this.productTitle,
    required this.size,
    required this.color,
    required this.quantity,
    required this.imageUrl,
    required this.unitPrice,
    this.agreedPrice,
    this.bargainId,
    required this.shopId,
    required this.shopName,
  });

  bool get hasBargainPrice => agreedPrice != null && agreedPrice! < unitPrice;

  double get effectivePrice => agreedPrice ?? unitPrice;

  double get price => effectivePrice;

  double get itemTotal => effectivePrice * quantity;

  double get totalPrice => itemTotal;

  CartItemModel copyWith({
    String? id,
    String? consumerId,
    String? variantId,
    String? productId,
    String? productTitle,
    String? size,
    String? color,
    int? quantity,
    String? imageUrl,
    double? unitPrice,
    double? agreedPrice,
    String? bargainId,
    String? shopId,
    String? shopName,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      consumerId: consumerId ?? this.consumerId,
      variantId: variantId ?? this.variantId,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      size: size ?? this.size,
      color: color ?? this.color,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      unitPrice: unitPrice ?? this.unitPrice,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      bargainId: bargainId ?? this.bargainId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
    );
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      consumerId: json['consumer_id'] as String,
      variantId: json['variant_id'] as String,
      productId: json['product_id'] as String? ?? '',
      productTitle: json['product_title'] as String? ?? 'Garment',
      size: json['size'] as String? ?? 'Free Size',
      color: json['color'] as String? ?? 'Standard',
      quantity: json['quantity'] as int? ?? 1,
      imageUrl: json['image_url'] as String? ?? '',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      agreedPrice: (json['agreed_price'] as num?)?.toDouble(),
      bargainId: json['bargain_id'] as String?,
      shopId: json['shop_id'] as String? ?? '',
      shopName: json['shop_name'] as String? ?? 'Local Boutique',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consumer_id': consumerId,
      'variant_id': variantId,
      'quantity': quantity,
      'agreed_price': agreedPrice,
      'bargain_id': bargainId,
    };
  }
}
