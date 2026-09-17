class NearbyShop {
  final String id;
  final String sellerId;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String address;
  final double distanceMeters;
  final double avgRating;
  final List<String> categoryIds;

  const NearbyShop({
    required this.id,
    required this.sellerId,
    required this.name,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    required this.address,
    required this.distanceMeters,
    this.avgRating = 0.0,
    this.categoryIds = const [],
  });

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  factory NearbyShop.fromJson(Map<String, dynamic> json) {
    return NearbyShop(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Local Boutique',
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      address: json['address'] as String? ?? '',
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0.0,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      categoryIds: (json['category_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
