class AdvertisementModel {
  final String id;
  final String sellerId;
  final String shopId;
  final String shopName;
  final String sellerEmail;
  final String sellerPhone;
  final String title;
  final String subtitle;
  final String tag;
  final String bannerImageUrl;
  final String placement; // 'home_hero', 'category_header', 'featured_feed'
  final String targetType; // 'shop', 'product', 'category', 'offer'
  final String? targetId;
  final String? targetCategory;
  final String buttonText;
  final String? badgeText;
  final int durationDays;
  final double budget;
  final String? paymentId;
  final String paymentStatus; // 'paid', 'pending', 'failed'
  final String paymentMethod; // 'razorpay'
  final String status; // 'pending', 'approved', 'live', 'rejected', 'paused', 'completed'
  final String? adminNotes;
  final bool isPaused;
  final int impressions;
  final int clicks;
  final int ordersCount;
  final double revenueGenerated;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? expiresAt;

  const AdvertisementModel({
    required this.id,
    required this.sellerId,
    required this.shopId,
    required this.shopName,
    required this.sellerEmail,
    required this.sellerPhone,
    required this.title,
    required this.subtitle,
    this.tag = 'BOUTIQUE SPOTLIGHT',
    required this.bannerImageUrl,
    this.placement = 'home_hero',
    this.targetType = 'shop',
    this.targetId,
    this.targetCategory,
    this.buttonText = 'Explore Collection',
    this.badgeText,
    this.durationDays = 15,
    this.budget = 1499.00,
    this.paymentId,
    this.paymentStatus = 'paid',
    this.paymentMethod = 'razorpay',
    this.status = 'pending',
    this.adminNotes,
    this.isPaused = false,
    this.impressions = 0,
    this.clicks = 0,
    this.ordersCount = 0,
    this.revenueGenerated = 0.0,
    required this.createdAt,
    this.approvedAt,
    this.expiresAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved' || status == 'live';
  bool get isRejected => status == 'rejected';
  bool get isPausedState => isPaused || status == 'paused';
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isLive => isApproved && !isPaused && !isExpired;

  String get effectiveStatus {
    if (isExpired) return 'completed';
    if (isPausedState) return 'paused';
    return status;
  }

  double get ctr => impressions > 0 ? (clicks / impressions) * 100 : 0.0;

  factory AdvertisementModel.fromJson(Map<String, dynamic> json) {
    return AdvertisementModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String? ?? '',
      shopId: json['shop_id'] as String? ?? '',
      shopName: json['shop_name'] as String? ?? 'Boutique Store',
      sellerEmail: json['seller_email'] as String? ?? '',
      sellerPhone: json['seller_phone'] as String? ?? '',
      title: json['title'] as String? ?? 'Exclusive Collection',
      subtitle: json['subtitle'] as String? ?? '',
      tag: json['tag'] as String? ?? 'BOUTIQUE SPOTLIGHT',
      bannerImageUrl: json['banner_image_url'] as String? ??
          'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=1200',
      placement: json['placement'] as String? ?? 'home_hero',
      targetType: json['target_type'] as String? ?? 'shop',
      targetId: json['target_id'] as String?,
      targetCategory: json['target_category'] as String?,
      buttonText: json['button_text'] as String? ?? 'Explore Collection',
      badgeText: json['badge_text'] as String?,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 15,
      budget: (json['budget'] as num?)?.toDouble() ?? 1499.00,
      paymentId: json['payment_id'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'paid',
      paymentMethod: json['payment_method'] as String? ?? 'razorpay',
      status: json['status'] as String? ?? 'pending',
      adminNotes: json['admin_notes'] as String?,
      isPaused: json['is_paused'] as bool? ?? false,
      impressions: (json['impressions'] as num?)?.toInt() ?? 0,
      clicks: (json['clicks'] as num?)?.toInt() ?? 0,
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      revenueGenerated: (json['revenue_generated'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'shop_id': shopId,
      'shop_name': shopName,
      'seller_email': sellerEmail,
      'seller_phone': sellerPhone,
      'title': title,
      'subtitle': subtitle,
      'tag': tag,
      'banner_image_url': bannerImageUrl,
      'placement': placement,
      'target_type': targetType,
      'target_id': targetId,
      'target_category': targetCategory,
      'button_text': buttonText,
      'badge_text': badgeText,
      'duration_days': durationDays,
      'budget': budget,
      'payment_id': paymentId,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'status': status,
      'admin_notes': adminNotes,
      'is_paused': isPaused,
      'impressions': impressions,
      'clicks': clicks,
      'orders_count': ordersCount,
      'revenue_generated': revenueGenerated,
      'created_at': createdAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  AdvertisementModel copyWith({
    String? id,
    String? sellerId,
    String? shopId,
    String? shopName,
    String? sellerEmail,
    String? sellerPhone,
    String? title,
    String? subtitle,
    String? tag,
    String? bannerImageUrl,
    String? placement,
    String? targetType,
    String? targetId,
    String? targetCategory,
    String? buttonText,
    String? badgeText,
    int? durationDays,
    double? budget,
    String? paymentId,
    String? paymentStatus,
    String? paymentMethod,
    String? status,
    String? adminNotes,
    bool? isPaused,
    int? impressions,
    int? clicks,
    int? ordersCount,
    double? revenueGenerated,
    DateTime? createdAt,
    DateTime? approvedAt,
    DateTime? expiresAt,
  }) {
    return AdvertisementModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      sellerEmail: sellerEmail ?? this.sellerEmail,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      tag: tag ?? this.tag,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      placement: placement ?? this.placement,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      targetCategory: targetCategory ?? this.targetCategory,
      buttonText: buttonText ?? this.buttonText,
      badgeText: badgeText ?? this.badgeText,
      durationDays: durationDays ?? this.durationDays,
      budget: budget ?? this.budget,
      paymentId: paymentId ?? this.paymentId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      isPaused: isPaused ?? this.isPaused,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      ordersCount: ordersCount ?? this.ordersCount,
      revenueGenerated: revenueGenerated ?? this.revenueGenerated,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
