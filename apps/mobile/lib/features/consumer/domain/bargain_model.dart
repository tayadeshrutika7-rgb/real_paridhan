enum BargainStatus { open, countered, accepted, rejected, expired }

enum BargainMessageType { offer, counter, accept, reject, text }

class BargainMessage {
  final String id;
  final String bargainId;
  final String senderId;
  final double? offerAmount;
  final BargainMessageType messageType;
  final String? text;
  final DateTime createdAt;

  const BargainMessage({
    required this.id,
    required this.bargainId,
    required this.senderId,
    this.offerAmount,
    required this.messageType,
    this.text,
    required this.createdAt,
  });

  factory BargainMessage.fromJson(Map<String, dynamic> map) =>
      BargainMessage.fromMap(map);

  factory BargainMessage.fromMap(Map<String, dynamic> map) {
    return BargainMessage(
      id: map['id'] as String,
      bargainId: map['bargain_id'] as String,
      senderId: map['sender_id'] as String,
      offerAmount: map['offer_amount'] != null
          ? (map['offer_amount'] as num).toDouble()
          : null,
      messageType: BargainMessageType.values.firstWhere(
        (e) => e.name == map['message_type'],
        orElse: () => BargainMessageType.text,
      ),
      text: map['text'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class Bargain {
  final String id;
  final String consumerId;
  final String sellerId;
  final String productId;
  final String variantId;
  final BargainStatus status;
  final double consumerOffer;
  final double? counterOffer;
  final double? agreedPrice;
  final double basePrice;
  final double minBargainPrice;
  final String? productTitle;
  final String? variantLabel;
  final String? productImageUrl;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Bargain({
    required this.id,
    required this.consumerId,
    required this.sellerId,
    required this.productId,
    required this.variantId,
    required this.status,
    required this.consumerOffer,
    this.counterOffer,
    this.agreedPrice,
    required this.basePrice,
    required this.minBargainPrice,
    this.productTitle,
    this.variantLabel,
    this.productImageUrl,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Bargain copyWith({
    String? id,
    String? consumerId,
    String? sellerId,
    String? productId,
    String? variantId,
    BargainStatus? status,
    double? consumerOffer,
    double? counterOffer,
    double? agreedPrice,
    double? basePrice,
    double? minBargainPrice,
    String? productTitle,
    String? variantLabel,
    String? productImageUrl,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bargain(
      id: id ?? this.id,
      consumerId: consumerId ?? this.consumerId,
      sellerId: sellerId ?? this.sellerId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      status: status ?? this.status,
      consumerOffer: consumerOffer ?? this.consumerOffer,
      counterOffer: counterOffer ?? this.counterOffer,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      basePrice: basePrice ?? this.basePrice,
      minBargainPrice: minBargainPrice ?? this.minBargainPrice,
      productTitle: productTitle ?? this.productTitle,
      variantLabel: variantLabel ?? this.variantLabel,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Bargain.fromJson(Map<String, dynamic> map) => Bargain.fromMap(map);

  factory Bargain.fromMap(Map<String, dynamic> map) {
    return Bargain(
      id: map['id'] as String,
      consumerId: map['consumer_id'] as String,
      sellerId: map['seller_id'] as String,
      productId: map['product_id'] as String,
      variantId: map['variant_id'] as String,
      status: BargainStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BargainStatus.open,
      ),
      consumerOffer: (map['consumer_offer'] as num).toDouble(),
      counterOffer: map['counter_offer'] != null
          ? (map['counter_offer'] as num).toDouble()
          : null,
      agreedPrice: map['agreed_price'] != null
          ? (map['agreed_price'] as num).toDouble()
          : null,
      basePrice: (map['base_price'] as num? ?? 0).toDouble(),
      minBargainPrice: (map['min_bargain_price'] as num? ?? 0).toDouble(),
      productTitle: map['product_title'] as String?,
      variantLabel: map['variant_label'] as String?,
      productImageUrl: map['product_image_url'] as String?,
      expiresAt: DateTime.parse(map['expires_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  bool get isActive =>
      status == BargainStatus.open || status == BargainStatus.countered;
  bool get isTerminal =>
      status == BargainStatus.accepted ||
      status == BargainStatus.rejected ||
      status == BargainStatus.expired;
}
