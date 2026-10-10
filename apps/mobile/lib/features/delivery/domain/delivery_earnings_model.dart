class DeliveryPenaltyItem {
  final String orderId;
  final String orderNumber;
  final double amount;
  final String reason;
  final DateTime chargedAt;

  const DeliveryPenaltyItem({
    required this.orderId,
    required this.orderNumber,
    required this.amount,
    required this.reason,
    required this.chargedAt,
  });

  factory DeliveryPenaltyItem.fromMap(Map<String, dynamic> map) {
    return DeliveryPenaltyItem(
      orderId: map['order_id'] ?? '',
      orderNumber: map['order_number'] ?? 'PRD-ORD',
      amount: (map['amount'] as num?)?.toDouble() ?? 100.0,
      reason: map['reason'] ?? 'Emergency Cancellation / Rejection',
      chargedAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

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
  final double todayPenalties;
  final int penaltiesCount;
  final double todayCodCollected;
  final double pendingCodRemittance;
  final double totalDistanceTodayKm;
  final List<DeliveryTripSummary> trips;
  final List<DeliveryPenaltyItem> penalties;

  const DeliveryEarningsModel({
    this.todayTripsCount = 0,
    this.todayBaseEarnings = 0.0,
    this.todayDistanceIncentive = 0.0,
    this.todayTips = 0.0,
    this.todayPenalties = 0.0,
    this.penaltiesCount = 0,
    this.todayCodCollected = 0.0,
    this.pendingCodRemittance = 0.0,
    this.totalDistanceTodayKm = 0.0,
    this.trips = const [],
    this.penalties = const [],
  });

  /// Gross earnings before penalties
  double get todayTotalEarnings =>
      todayBaseEarnings + todayDistanceIncentive + todayTips;

  /// Net payout after deducting cancellation/emergency penalties
  double get todayNetEarnings =>
      (todayTotalEarnings - todayPenalties).clamp(0.0, double.infinity);

  /// Unclamped net balance (can be negative if penalty exceeds earnings)
  double get rawNetBalance => todayTotalEarnings - todayPenalties;

  DeliveryEarningsModel copyWith({
    int? todayTripsCount,
    double? todayBaseEarnings,
    double? todayDistanceIncentive,
    double? todayTips,
    double? todayPenalties,
    int? penaltiesCount,
    double? todayCodCollected,
    double? pendingCodRemittance,
    double? totalDistanceTodayKm,
    List<DeliveryTripSummary>? trips,
    List<DeliveryPenaltyItem>? penalties,
  }) {
    return DeliveryEarningsModel(
      todayTripsCount: todayTripsCount ?? this.todayTripsCount,
      todayBaseEarnings: todayBaseEarnings ?? this.todayBaseEarnings,
      todayDistanceIncentive:
          todayDistanceIncentive ?? this.todayDistanceIncentive,
      todayTips: todayTips ?? this.todayTips,
      todayPenalties: todayPenalties ?? this.todayPenalties,
      penaltiesCount: penaltiesCount ?? this.penaltiesCount,
      todayCodCollected: todayCodCollected ?? this.todayCodCollected,
      pendingCodRemittance:
          pendingCodRemittance ?? this.pendingCodRemittance,
      totalDistanceTodayKm:
          totalDistanceTodayKm ?? this.totalDistanceTodayKm,
      trips: trips ?? this.trips,
      penalties: penalties ?? this.penalties,
    );
  }
}
