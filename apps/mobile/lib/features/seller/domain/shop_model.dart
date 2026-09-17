class ShopModel {
  final String id;
  final String sellerId;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String address;
  final double latitude;
  final double longitude;
  final String status; // pending, verified, rejected, suspended
  final List<String> categoryIds;
  final double avgRating;
  final String? razorpayLinkedAccountId;
  final String kycStatus; // not_started, pending, verified, rejected
  final double commissionRate;
  final DateTime? createdAt;

  const ShopModel({
    required this.id,
    required this.sellerId,
    required this.name,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.status = 'pending',
    this.categoryIds = const [],
    this.avgRating = 0.0,
    this.razorpayLinkedAccountId,
    this.kycStatus = 'not_started',
    this.commissionRate = 10.0,
    this.createdAt,
  });

  bool get isVerified => status == 'verified';

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    // PostGIS location parsing fallback (GeoJSON or Point)
    double lat = 26.9124; // Default Jaipur latitude
    double lng = 75.7873; // Default Jaipur longitude

    if (json['latitude'] != null && json['longitude'] != null) {
      lat = (json['latitude'] as num).toDouble();
      lng = (json['longitude'] as num).toDouble();
    } else if (json['location'] != null && json['location'] is Map) {
      final loc = json['location'] as Map<String, dynamic>;
      if (loc['coordinates'] is List && (loc['coordinates'] as List).length >= 2) {
        lng = (loc['coordinates'][0] as num).toDouble();
        lat = (loc['coordinates'][1] as num).toDouble();
      }
    }

    return ShopModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      name: json['name'] as String? ?? 'Unnamed Shop',
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      address: json['address'] as String? ?? '',
      latitude: lat,
      longitude: lng,
      status: json['status'] as String? ?? 'pending',
      categoryIds: (json['category_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      razorpayLinkedAccountId: json['razorpay_linked_account_id'] as String?,
      kycStatus: json['kyc_status'] as String? ?? 'not_started',
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 10.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'banner_url': bannerUrl,
      'address': address,
      'location': 'POINT($longitude $latitude)', // PostGIS WKT
      'status': status,
      'category_ids': categoryIds,
      'avg_rating': avgRating,
      'razorpay_linked_account_id': razorpayLinkedAccountId,
      'kyc_status': kycStatus,
      'commission_rate': commissionRate,
    };
  }

  ShopModel copyWith({
    String? id,
    String? sellerId,
    String? name,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    String? address,
    double? latitude,
    double? longitude,
    String? status,
    List<String>? categoryIds,
    double? avgRating,
    String? razorpayLinkedAccountId,
    String? kycStatus,
    double? commissionRate,
    DateTime? createdAt,
  }) {
    return ShopModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      categoryIds: categoryIds ?? this.categoryIds,
      avgRating: avgRating ?? this.avgRating,
      razorpayLinkedAccountId:
          razorpayLinkedAccountId ?? this.razorpayLinkedAccountId,
      kycStatus: kycStatus ?? this.kycStatus,
      commissionRate: commissionRate ?? this.commissionRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
