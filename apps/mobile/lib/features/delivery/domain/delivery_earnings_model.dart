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

class DeliveryCodRemittanceItem {
  final String id;
  final String driverId;
  final String driverName;
  final double amount;
  final String status; // 'pending' (Awaiting Admin Verification), 'verified' (Settled & Verified by Admin)
  final String paymentMethod; // 'Admin Primary UPI', 'Bank IMPS/NEFT Escrow', 'Jaipur HQ Cash Hub'
  final String reference; // UTR or Ref number
  final String? notes;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final List<String> orderNumbers;
  final List<String> orderIds;
  final bool isSellerPaid;

  const DeliveryCodRemittanceItem({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.reference,
    this.notes,
    required this.createdAt,
    this.verifiedAt,
    this.orderNumbers = const [],
    this.orderIds = const [],
    this.isSellerPaid = false,
  });

  bool get isVerified =>
      status.toLowerCase() == 'verified' || status.toLowerCase() == 'remitted';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driver_id': driverId,
      'driver_name': driverName,
      'amount': amount,
      'status': status,
      'payment_method': paymentMethod,
      'reference': reference,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
      'order_numbers': orderNumbers,
      'order_ids': orderIds,
      'is_seller_paid': isSellerPaid,
    };
  }

  factory DeliveryCodRemittanceItem.fromMap(Map<String, dynamic> map) {
    return DeliveryCodRemittanceItem(
      id: map['id']?.toString() ?? '',
      driverId: map['driver_id']?.toString() ?? '',
      driverName: map['driver_name']?.toString() ?? 'Delivery Partner',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: map['status']?.toString() ?? 'pending',
      paymentMethod: map['payment_method']?.toString() ?? 'Admin UPI Transfer',
      reference: map['reference']?.toString() ?? '',
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      verifiedAt: map['verified_at'] != null
          ? DateTime.tryParse(map['verified_at'].toString())
          : null,
      orderNumbers: (map['order_numbers'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      orderIds: (map['order_ids'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      isSellerPaid: map['is_seller_paid'] == true,
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
  final List<DeliveryCodRemittanceItem> remittances;

  // Monthly Salary Ledger Sync
  final String monthlySalaryMonth;
  final String monthlySalaryStatus; // 'Paid', 'Pending'
  final double monthlySalaryAmount;
  final String? monthlySalaryRef;
  final String? monthlySalaryMethod;
  final DateTime? monthlySalaryPaidAt;
  final int monthlySalaryTripsCount;

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
    this.remittances = const [],
    this.monthlySalaryMonth = 'October 2026',
    this.monthlySalaryStatus = 'Pending',
    this.monthlySalaryAmount = 0.0,
    this.monthlySalaryRef,
    this.monthlySalaryMethod,
    this.monthlySalaryPaidAt,
    this.monthlySalaryTripsCount = 0,
  });

  /// Gross earnings before penalties
  double get todayTotalEarnings =>
      todayBaseEarnings + todayDistanceIncentive + todayTips;

  /// Net payout after deducting cancellation/emergency penalties
  double get todayNetEarnings =>
      (todayTotalEarnings - todayPenalties).clamp(0.0, double.infinity);

  /// Unclamped net balance (can be negative if penalty exceeds earnings)
  double get rawNetBalance => todayTotalEarnings - todayPenalties;

  bool get isSalaryCredited => monthlySalaryStatus.toLowerCase() == 'paid';

  /// Total amount of COD cash remitted / settled with admin
  double get totalCodRemitted =>
      remittances.fold<double>(0.0, (acc, r) => acc + r.amount);

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
    List<DeliveryCodRemittanceItem>? remittances,
    String? monthlySalaryMonth,
    String? monthlySalaryStatus,
    double? monthlySalaryAmount,
    String? monthlySalaryRef,
    String? monthlySalaryMethod,
    DateTime? monthlySalaryPaidAt,
    int? monthlySalaryTripsCount,
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
      remittances: remittances ?? this.remittances,
      monthlySalaryMonth: monthlySalaryMonth ?? this.monthlySalaryMonth,
      monthlySalaryStatus: monthlySalaryStatus ?? this.monthlySalaryStatus,
      monthlySalaryAmount: monthlySalaryAmount ?? this.monthlySalaryAmount,
      monthlySalaryRef: monthlySalaryRef ?? this.monthlySalaryRef,
      monthlySalaryMethod: monthlySalaryMethod ?? this.monthlySalaryMethod,
      monthlySalaryPaidAt: monthlySalaryPaidAt ?? this.monthlySalaryPaidAt,
      monthlySalaryTripsCount: monthlySalaryTripsCount ?? this.monthlySalaryTripsCount,
    );
  }
}
