class DeliveryTripSummary {
  final String orderId;
  final String orderNumber;
  final String shopName;
  final String dropArea;
  final double distanceKm;
  final double payout;
  final bool isCod;
  final double codAmount;
  final DateTime completedAt;

  const DeliveryTripSummary({
    required this.orderId,
    required this.orderNumber,
    required this.shopName,
    required this.dropArea,
    required this.distanceKm,
    required this.payout,
    required this.isCod,
    required this.codAmount,
    required this.completedAt,
  });

  factory DeliveryTripSummary.fromMap(Map<String, dynamic> map) {
    return DeliveryTripSummary(
      orderId: map['order_id'] ?? '',
      orderNumber: map['order_number'] ?? 'PRD-ORD',
      shopName: map['shop_name'] ?? 'Local Boutique',
      dropArea: map['drop_area'] ?? 'Jaipur',
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 4.2,
      payout: (map['payout'] as num?)?.toDouble() ?? 75.0,
      isCod: map['is_cod'] == true,
      codAmount: (map['cod_amount'] as num?)?.toDouble() ?? 0.0,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class DeliveryEarningsModel {
  final int todayTripsCount;
  final double todayBaseEarnings;
  final double todayDistanceIncentive;
  final double todayTips;
  final double todayCodCollected;
  final double pendingCodRemittance;
  final double totalDistanceTodayKm;
  final List<DeliveryTripSummary> trips;

  const DeliveryEarningsModel({
    this.todayTripsCount = 0,
    this.todayBaseEarnings = 0.0,
    this.todayDistanceIncentive = 0.0,
    this.todayTips = 0.0,
    this.todayCodCollected = 0.0,
    this.pendingCodRemittance = 0.0,
    this.totalDistanceTodayKm = 0.0,
    this.trips = const [],
  });

  double get todayTotalEarnings =>
      todayBaseEarnings + todayDistanceIncentive + todayTips;

  DeliveryEarningsModel copyWith({
    int? todayTripsCount,
    double? todayBaseEarnings,
    double? todayDistanceIncentive,
    double? todayTips,
    double? todayCodCollected,
    double? pendingCodRemittance,
    double? totalDistanceTodayKm,
    List<DeliveryTripSummary>? trips,
  }) {
    return DeliveryEarningsModel(
      todayTripsCount: todayTripsCount ?? this.todayTripsCount,
      todayBaseEarnings: todayBaseEarnings ?? this.todayBaseEarnings,
      todayDistanceIncentive:
          todayDistanceIncentive ?? this.todayDistanceIncentive,
      todayTips: todayTips ?? this.todayTips,
      todayCodCollected: todayCodCollected ?? this.todayCodCollected,
      pendingCodRemittance:
          pendingCodRemittance ?? this.pendingCodRemittance,
      totalDistanceTodayKm:
          totalDistanceTodayKm ?? this.totalDistanceTodayKm,
      trips: trips ?? this.trips,
    );
  }
}
