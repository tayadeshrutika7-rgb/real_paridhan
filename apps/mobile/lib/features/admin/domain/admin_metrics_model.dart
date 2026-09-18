enum KycStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case KycStatus.pending:
        return 'Pending Verification';
      case KycStatus.approved:
        return 'Approved & Active';
      case KycStatus.rejected:
        return 'Rejected';
    }
  }

  static KycStatus fromString(String? val) {
    switch (val) {
      case 'approved':
      case 'verified':
        return KycStatus.approved;
      case 'rejected':
        return KycStatus.rejected;
      case 'pending':
      default:
        return KycStatus.pending;
    }
  }
}

class BoutiqueVerificationItem {
  final String id;
  final String shopName;
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;
  final String gstin;
  final String address;
  final String cityZone;
  final String? bannerUrl;
  final String? licenseDocumentUrl;
  final KycStatus status;
  final DateTime submittedAt;

  const BoutiqueVerificationItem({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.gstin,
    required this.address,
    required this.cityZone,
    this.bannerUrl,
    this.licenseDocumentUrl,
    required this.status,
    required this.submittedAt,
  });

  BoutiqueVerificationItem copyWith({
    String? id,
    String? shopName,
    String? ownerName,
    String? ownerEmail,
    String? ownerPhone,
    String? gstin,
    String? address,
    String? cityZone,
    String? bannerUrl,
    String? licenseDocumentUrl,
    KycStatus? status,
    DateTime? submittedAt,
  }) {
    return BoutiqueVerificationItem(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      gstin: gstin ?? this.gstin,
      address: address ?? this.address,
      cityZone: cityZone ?? this.cityZone,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      licenseDocumentUrl: licenseDocumentUrl ?? this.licenseDocumentUrl,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  factory BoutiqueVerificationItem.fromMap(Map<String, dynamic> map) {
    return BoutiqueVerificationItem(
      id: map['id'] ?? '',
      shopName: map['name'] ?? 'Boutique Store',
      ownerName: map['owner_name'] ?? 'Boutique Owner',
      ownerEmail: map['owner_email'] ?? 'seller@paridhan.local',
      ownerPhone: map['phone'] ?? '+91 98290 00000',
      gstin: map['gstin'] ?? '08AAAAA0000A1Z5',
      address: map['address_line1'] ?? 'Jaipur, Rajasthan',
      cityZone: map['city_zone'] ?? 'Pink City / Johari Bazaar',
      bannerUrl: map['banner_image_url'] ?? map['logo_url'],
      licenseDocumentUrl: map['license_document_url'],
      status: KycStatus.fromString(map['kyc_status'] ?? (map['is_verified'] == true ? 'approved' : 'pending')),
      submittedAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class CityZoneMetric {
  final String zoneName;
  final int activeBoutiques;
  final int totalOrders;
  final double gmvAmount;
  final double platformRevenue;

  const CityZoneMetric({
    required this.zoneName,
    required this.activeBoutiques,
    required this.totalOrders,
    required this.gmvAmount,
    required this.platformRevenue,
  });

  factory CityZoneMetric.fromMap(Map<String, dynamic> map) {
    final gmv = (map['gmv_amount'] as num?)?.toDouble() ?? 0.0;
    return CityZoneMetric(
      zoneName: map['zone_name'] ?? 'Jaipur Zone',
      activeBoutiques: (map['active_boutiques'] as num?)?.toInt() ?? 0,
      totalOrders: (map['total_orders'] as num?)?.toInt() ?? 0,
      gmvAmount: gmv,
      platformRevenue: (map['platform_revenue'] as num?)?.toDouble() ?? (gmv * 0.10),
    );
  }
}

class DisputeTicket {
  final String id;
  final String orderNumber;
  final String consumerName;
  final String boutiqueName;
  final String issueReason;
  final double amount;
  final bool isResolved;
  final DateTime createdAt;

  const DisputeTicket({
    required this.id,
    required this.orderNumber,
    required this.consumerName,
    required this.boutiqueName,
    required this.issueReason,
    required this.amount,
    required this.isResolved,
    required this.createdAt,
  });

  DisputeTicket copyWith({
    String? id,
    String? orderNumber,
    String? consumerName,
    String? boutiqueName,
    String? issueReason,
    double? amount,
    bool? isResolved,
    DateTime? createdAt,
  }) {
    return DisputeTicket(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      consumerName: consumerName ?? this.consumerName,
      boutiqueName: boutiqueName ?? this.boutiqueName,
      issueReason: issueReason ?? this.issueReason,
      amount: amount ?? this.amount,
      isResolved: isResolved ?? this.isResolved,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AdminMetricsModel {
  final double totalGmv;
  final double platformCommissionRate; // 10.0%
  final double platformRevenue; // GMV * 0.10
  final int totalOrdersCount;
  final int activeBoutiquesCount;
  final int pendingKycCount;
  final int onDutyDeliveryFleetCount;
  final List<BoutiqueVerificationItem> pendingBoutiques;
  final List<CityZoneMetric> zoneMetrics;
  final List<DisputeTicket> disputes;

  const AdminMetricsModel({
    this.totalGmv = 0.0,
    this.platformCommissionRate = 10.0,
    this.platformRevenue = 0.0,
    this.totalOrdersCount = 0,
    this.activeBoutiquesCount = 0,
    this.pendingKycCount = 0,
    this.onDutyDeliveryFleetCount = 0,
    this.pendingBoutiques = const [],
    this.zoneMetrics = const [],
    this.disputes = const [],
  });

  AdminMetricsModel copyWith({
    double? totalGmv,
    double? platformCommissionRate,
    double? platformRevenue,
    int? totalOrdersCount,
    int? activeBoutiquesCount,
    int? pendingKycCount,
    int? onDutyDeliveryFleetCount,
    List<BoutiqueVerificationItem>? pendingBoutiques,
    List<CityZoneMetric>? zoneMetrics,
    List<DisputeTicket>? disputes,
  }) {
    return AdminMetricsModel(
      totalGmv: totalGmv ?? this.totalGmv,
      platformCommissionRate: platformCommissionRate ?? this.platformCommissionRate,
      platformRevenue: platformRevenue ?? this.platformRevenue,
      totalOrdersCount: totalOrdersCount ?? this.totalOrdersCount,
      activeBoutiquesCount: activeBoutiquesCount ?? this.activeBoutiquesCount,
      pendingKycCount: pendingKycCount ?? this.pendingKycCount,
      onDutyDeliveryFleetCount: onDutyDeliveryFleetCount ?? this.onDutyDeliveryFleetCount,
      pendingBoutiques: pendingBoutiques ?? this.pendingBoutiques,
      zoneMetrics: zoneMetrics ?? this.zoneMetrics,
      disputes: disputes ?? this.disputes,
    );
  }
}
