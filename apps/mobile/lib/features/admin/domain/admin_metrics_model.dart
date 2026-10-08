enum KycStatus {
  notStarted,
  pending,
  approved,
  rejected,
  correctionRequested;

  String get label {
    switch (this) {
      case KycStatus.notStarted:
        return 'Not Started';
      case KycStatus.pending:
        return 'Pending Verification';
      case KycStatus.approved:
        return 'Approved & Active';
      case KycStatus.rejected:
        return 'Rejected';
      case KycStatus.correctionRequested:
        return 'Correction Requested';
    }
  }

  static KycStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'approved':
      case 'verified':
        return KycStatus.approved;
      case 'rejected':
      case 'suspended':
        return KycStatus.rejected;
      case 'correction_requested':
      case 'correction':
        return KycStatus.correctionRequested;
      case 'pending':
        return KycStatus.pending;
      case 'not_started':
      default:
        return KycStatus.notStarted;
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
  final String bankAccountNumber;
  final String bankIfsc;
  final String bankName;
  final String panNumber;
  final String aadhaarNumber;
  final String businessRegNumber;
  final List<String> submittedDocuments;
  final String? kycNotes;
  final String? rejectionReason;
  final KycStatus status;
  final DateTime submittedAt;
  final DateTime? verifiedAt;

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
    this.bankAccountNumber = '987654321012',
    this.bankIfsc = 'HDFC0001234',
    this.bankName = 'HDFC Bank, Johari Bazaar',
    this.panNumber = 'ABCDE1234F',
    this.aadhaarNumber = '987654321098',
    this.businessRegNumber = 'RJ-JP-2024-8842',
    this.submittedDocuments = const [],
    this.kycNotes,
    this.rejectionReason,
    required this.status,
    required this.submittedAt,
    this.verifiedAt,
  });

  /// Masked Sensitive Data Getters for Security
  String get maskedPan {
    if (panNumber.length <= 4) return '******';
    return '${panNumber.substring(0, 2)}******${panNumber.substring(panNumber.length - 2)}';
  }

  String get maskedAadhaar {
    if (aadhaarNumber.length < 4) return '**** **** ****';
    final last4 = aadhaarNumber.substring(aadhaarNumber.length - 4);
    return '**** **** $last4';
  }

  String get maskedBankAccount {
    if (bankAccountNumber.length <= 4) return '******';
    final last4 = bankAccountNumber.substring(bankAccountNumber.length - 4);
    return '******$last4';
  }

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
    String? bankAccountNumber,
    String? bankIfsc,
    String? bankName,
    String? panNumber,
    String? aadhaarNumber,
    String? businessRegNumber,
    List<String>? submittedDocuments,
    String? kycNotes,
    String? rejectionReason,
    KycStatus? status,
    DateTime? submittedAt,
    DateTime? verifiedAt,
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
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      bankName: bankName ?? this.bankName,
      panNumber: panNumber ?? this.panNumber,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      businessRegNumber: businessRegNumber ?? this.businessRegNumber,
      submittedDocuments: submittedDocuments ?? this.submittedDocuments,
      kycNotes: kycNotes ?? this.kycNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  factory BoutiqueVerificationItem.fromMap(Map<String, dynamic> map) {
    return BoutiqueVerificationItem(
      id: map['id']?.toString() ?? '',
      shopName: map['name'] ?? map['shop_name'] ?? 'Boutique Store',
      ownerName: map['owner_name'] ?? map['full_name'] ?? 'Boutique Owner',
      ownerEmail: map['owner_email'] ?? map['email'] ?? 'seller@paridhan.local',
      ownerPhone: map['phone'] ?? map['contact_phone'] ?? '+91 98290 00000',
      gstin: map['gstin'] ?? '08AAAAA0000A1Z5',
      address: map['address'] ?? map['address_line1'] ?? 'Jaipur, Rajasthan',
      cityZone: map['city_zone'] ?? 'Pink City / Johari Bazaar',
      bannerUrl: map['banner_url'] ?? map['banner_image_url'] ?? map['logo_url'],
      licenseDocumentUrl: map['license_document_url'] ?? map['license_url'],
      bankAccountNumber: map['bank_account_number'] ?? '987654321012',
      bankIfsc: map['bank_ifsc'] ?? 'HDFC0001234',
      bankName: map['bank_name'] ?? 'HDFC Bank, Johari Bazaar',
      panNumber: map['pan_number'] ?? 'ABCDE1234F',
      aadhaarNumber: map['aadhaar_number'] ?? '987654321098',
      businessRegNumber: map['business_reg_number'] ?? 'RJ-JP-2024-8842',
      submittedDocuments: (map['submitted_documents'] as List?)?.map((e) => e.toString()).toList() ?? [],
      kycNotes: map['kyc_notes'],
      rejectionReason: map['kyc_rejection_reason'],
      status: KycStatus.fromString(map['kyc_status'] ?? (map['is_verified'] == true ? 'approved' : (map['status'] == 'pending' ? 'pending' : 'not_started'))),
      submittedAt: map['kyc_submitted_at'] != null
          ? DateTime.tryParse(map['kyc_submitted_at']) ?? DateTime.now()
          : (map['created_at'] != null ? DateTime.tryParse(map['created_at']) ?? DateTime.now() : DateTime.now()),
      verifiedAt: map['kyc_verified_at'] != null ? DateTime.tryParse(map['kyc_verified_at']) : null,
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
  final String status; // 'open', 'investigating', 'resolved', 'refunded'
  final DateTime createdAt;

  const DisputeTicket({
    required this.id,
    required this.orderNumber,
    required this.consumerName,
    required this.boutiqueName,
    required this.issueReason,
    required this.amount,
    required this.isResolved,
    this.status = 'open',
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
    String? status,
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
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DisputeTicket.fromMap(Map<String, dynamic> map) {
    final isRes = map['status'] == 'resolved' || map['status'] == 'refunded';
    return DisputeTicket(
      id: map['id']?.toString() ?? '',
      orderNumber: map['order_id']?.toString() ?? 'PRD-ORD',
      consumerName: map['consumer_name'] ?? map['full_name'] ?? 'Customer',
      boutiqueName: map['boutique_name'] ?? 'Jaipur Boutique',
      issueReason: map['reason'] ?? map['issue_reason'] ?? 'Issue with order handover',
      amount: (map['refund_amount'] as num?)?.toDouble() ?? (map['amount'] as num?)?.toDouble() ?? 0.0,
      isResolved: isRes,
      status: map['status'] ?? (isRes ? 'resolved' : 'open'),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// 1. Customer User Details Model
class AdminCustomerItem {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime registeredAt;
  final int totalOrders;
  final double totalSpending;
  final int refundsCount;
  final String accountStatus; // 'active', 'suspended', 'pending'
  final DateTime lastActivity;

  const AdminCustomerItem({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.registeredAt,
    required this.totalOrders,
    required this.totalSpending,
    this.refundsCount = 0,
    this.accountStatus = 'active',
    required this.lastActivity,
  });

  factory AdminCustomerItem.fromMap(Map<String, dynamic> map) {
    return AdminCustomerItem(
      id: map['id']?.toString() ?? '',
      name: map['full_name'] ?? map['name'] ?? 'Customer',
      email: map['email'] ?? 'customer@paridhan.app',
      phone: map['phone'] ?? '+91 98290 00000',
      registeredAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) ?? DateTime.now() : DateTime.now(),
      totalOrders: (map['total_orders'] as num?)?.toInt() ?? 0,
      totalSpending: (map['total_spending'] as num?)?.toDouble() ?? 0.0,
      refundsCount: (map['refunds_count'] as num?)?.toInt() ?? 0,
      accountStatus: map['status'] ?? 'active',
      lastActivity: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// 2. Seller Details Model
class AdminSellerItem {
  final String id;
  final String shopName;
  final String ownerName;
  final String email;
  final String phone;
  final String address;
  final String cityZone;
  final String gstin;
  final String status; // 'verified', 'pending', 'suspended'
  final KycStatus kycStatus;
  final int totalProducts;
  final int totalOrders;
  final double totalSales;
  final double commissionGenerated;
  final double sellerEarnings;
  final double commissionRate;
  final DateTime registeredAt;

  const AdminSellerItem({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.address,
    required this.cityZone,
    required this.gstin,
    required this.status,
    required this.kycStatus,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalSales,
    required this.commissionGenerated,
    required this.sellerEarnings,
    this.commissionRate = 10.0,
    required this.registeredAt,
  });

  factory AdminSellerItem.fromMap(Map<String, dynamic> map) {
    final sales = (map['total_sales'] as num?)?.toDouble() ?? 0.0;
    final rate = (map['commission_rate'] as num?)?.toDouble() ?? 10.0;
    final commission = (map['commission_generated'] as num?)?.toDouble() ?? (sales * (rate / 100));
    final earnings = (map['seller_earnings'] as num?)?.toDouble() ?? (sales - commission);

    return AdminSellerItem(
      id: map['id']?.toString() ?? '',
      shopName: map['name'] ?? 'Boutique Store',
      ownerName: map['owner_name'] ?? 'Owner',
      email: map['email'] ?? map['contact_email'] ?? 'seller@boutique.com',
      phone: map['phone'] ?? '+91 98290 11111',
      address: map['address'] ?? 'Jaipur',
      cityZone: map['city_zone'] ?? 'Pink City',
      gstin: map['gstin'] ?? '08AAAAA0000A1Z5',
      status: map['status'] ?? (map['is_verified'] == true ? 'verified' : 'pending'),
      kycStatus: KycStatus.fromString(map['kyc_status'] ?? (map['is_verified'] == true ? 'approved' : 'pending')),
      totalProducts: (map['total_products'] as num?)?.toInt() ?? 0,
      totalOrders: (map['total_orders'] as num?)?.toInt() ?? 0,
      totalSales: sales,
      commissionGenerated: commission,
      sellerEarnings: earnings,
      commissionRate: rate,
      registeredAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// 3. Delivery Partner Fleet Model
class AdminDeliveryPartnerItem {
  final String id;
  final String name;
  final String phone;
  final String vehicleType;
  final String vehicleNumber;
  final String? licenseUrl;
  final String? drivingLicenseNumber;
  final String? panNumber;
  final String? aadhaarNumber;
  final String? upiId;
  final bool isOnDuty;
  final String verificationStatus; // 'verified', 'pending', 'rejected'
  final String? rejectionReason;
  final int ordersDelivered;
  final double totalEarnings;
  final double rating;
  final double successRate;

  const AdminDeliveryPartnerItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.vehicleNumber,
    this.licenseUrl,
    this.drivingLicenseNumber = 'RJ14 20210049281',
    this.panNumber = 'ABCDE9876K',
    this.aadhaarNumber = '987654321012',
    this.upiId = 'driver@upi',
    required this.isOnDuty,
    required this.verificationStatus,
    this.rejectionReason,
    required this.ordersDelivered,
    required this.totalEarnings,
    this.rating = 4.8,
    this.successRate = 98.5,
  });

  AdminDeliveryPartnerItem copyWith({
    String? id,
    String? name,
    String? phone,
    String? vehicleType,
    String? vehicleNumber,
    String? licenseUrl,
    String? drivingLicenseNumber,
    String? panNumber,
    String? aadhaarNumber,
    String? upiId,
    bool? isOnDuty,
    String? verificationStatus,
    String? rejectionReason,
    int? ordersDelivered,
    double? totalEarnings,
    double? rating,
    double? successRate,
  }) {
    return AdminDeliveryPartnerItem(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      drivingLicenseNumber: drivingLicenseNumber ?? this.drivingLicenseNumber,
      panNumber: panNumber ?? this.panNumber,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      upiId: upiId ?? this.upiId,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      ordersDelivered: ordersDelivered ?? this.ordersDelivered,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      rating: rating ?? this.rating,
      successRate: successRate ?? this.successRate,
    );
  }

  bool get isVerified => verificationStatus == 'verified' || verificationStatus == 'approved';

  factory AdminDeliveryPartnerItem.fromMap(Map<String, dynamic> map) {
    return AdminDeliveryPartnerItem(
      id: map['id']?.toString() ?? '',
      name: map['full_name'] ?? map['name'] ?? 'Fleet Driver',
      phone: map['phone'] ?? '+91 98290 22222',
      vehicleType: map['vehicle_type'] ?? 'Two-Wheeler (EV)',
      vehicleNumber: map['vehicle_number'] ?? 'RJ 14 AB 1234',
      licenseUrl: map['license_url'],
      drivingLicenseNumber: map['driving_license_number'] ?? 'RJ14 20210049281',
      panNumber: map['pan_number'] ?? 'ABCDE9876K',
      aadhaarNumber: map['aadhaar_number'] ?? '987654321012',
      upiId: map['upi_id'] ?? 'driver@upi',
      isOnDuty: map['is_available'] == true || map['is_on_duty'] == true,
      verificationStatus: map['verification_status'] ?? 'verified',
      rejectionReason: map['kyc_rejection_reason'],
      ordersDelivered: (map['orders_delivered'] as num?)?.toInt() ?? 0,
      totalEarnings: (map['total_earnings'] as num?)?.toDouble() ?? 0.0,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.8,
      successRate: (map['success_rate'] as num?)?.toDouble() ?? 98.5,
    );
  }
}

/// 4. Admin Order Management Model
class AdminOrderItem {
  final String id;
  final String consumerName;
  final String consumerPhone;
  final String shopName;
  final String productTitles;
  final int itemCount;
  final double subtotal;
  final double deliveryFee;
  final double commissionAmount;
  final double sellerPayout;
  final double total;
  final String paymentMethod; // 'razorpay', 'cod'
  final String paymentStatus; // 'paid', 'pending', 'refunded', 'failed'
  final String orderStatus;   // 'placed', 'confirmed', 'packed', 'out_for_delivery', 'delivered', 'cancelled', 'returned'
  final String? deliveryPartnerName;
  final String deliveryAddress;
  final DateTime createdAt;

  const AdminOrderItem({
    required this.id,
    required this.consumerName,
    this.consumerPhone = '+91 98290 00000',
    required this.shopName,
    required this.productTitles,
    required this.itemCount,
    required this.subtotal,
    required this.deliveryFee,
    required this.commissionAmount,
    required this.sellerPayout,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    this.deliveryPartnerName,
    required this.deliveryAddress,
    required this.createdAt,
  });

  factory AdminOrderItem.fromMap(Map<String, dynamic> map) {
    final sub = (map['subtotal'] as num?)?.toDouble() ?? 0.0;
    final fee = (map['delivery_fee'] as num?)?.toDouble() ?? 30.0;
    final tot = (map['total'] as num?)?.toDouble() ?? (sub + fee);
    final comm = (map['commission_amount'] as num?)?.toDouble() ?? (sub * 0.10);
    final payout = (map['seller_payout_amount'] as num?)?.toDouble() ?? (sub - comm);

    return AdminOrderItem(
      id: map['id']?.toString() ?? '',
      consumerName: map['consumer_name'] ?? 'Customer',
      consumerPhone: map['consumer_phone'] ?? '+91 98290 00000',
      shopName: map['shop_name'] ?? 'Boutique Store',
      productTitles: map['product_titles'] ?? 'Handcrafted Apparel',
      itemCount: (map['item_count'] as num?)?.toInt() ?? 1,
      subtotal: sub,
      deliveryFee: fee,
      commissionAmount: comm,
      sellerPayout: payout,
      total: tot,
      paymentMethod: map['payment_method'] ?? 'razorpay',
      paymentStatus: map['payment_status'] ?? 'paid',
      orderStatus: map['status'] ?? 'confirmed',
      deliveryPartnerName: map['delivery_partner_name'],
      deliveryAddress: map['delivery_address_str'] ?? 'Jaipur, Rajasthan',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// 5. Inventory & Products Model
class AdminProductInventoryItem {
  final String id;
  final String title;
  final String shopName;
  final String categoryName;
  final double basePrice;
  final int totalVariants;
  final int totalStock;
  final int soldCount;
  final String status; // 'active', 'draft', 'out_of_stock'

  const AdminProductInventoryItem({
    required this.id,
    required this.title,
    required this.shopName,
    required this.categoryName,
    required this.basePrice,
    required this.totalVariants,
    required this.totalStock,
    this.soldCount = 0,
    required this.status,
  });

  bool get isLowStock => totalStock > 0 && totalStock <= 5;
  bool get isOutOfStock => totalStock == 0;
}

/// 6. Admin Audit Log Item
class AdminAuditLogItem {
  final String id;
  final String adminName;
  final String adminEmail;
  final String action;
  final String entity;
  final String entityId;
  final String details;
  final String? previousValue;
  final String? newValue;
  final String ipAddress;
  final String userAgent;
  final DateTime timestamp;

  const AdminAuditLogItem({
    required this.id,
    required this.adminName,
    this.adminEmail = 'admin@paridhan.app',
    required this.action,
    required this.entity,
    required this.entityId,
    required this.details,
    this.previousValue,
    this.newValue,
    this.ipAddress = '127.0.0.1',
    this.userAgent = 'Admin Portal Web / Mobile',
    required this.timestamp,
  });

  factory AdminAuditLogItem.fromMap(Map<String, dynamic> map) {
    return AdminAuditLogItem(
      id: map['id']?.toString() ?? '',
      adminName: map['admin_name'] ?? 'Super Admin',
      adminEmail: map['admin_email'] ?? 'admin@paridhan.app',
      action: map['action'] ?? 'ADMIN_ACTION',
      entity: map['entity'] ?? 'system',
      entityId: map['entity_id']?.toString() ?? '-',
      details: map['details'] ?? '',
      previousValue: map['previous_value']?.toString(),
      newValue: map['new_value']?.toString(),
      ipAddress: map['ip_address'] ?? '127.0.0.1',
      userAgent: map['user_agent'] ?? 'Admin Console',
      timestamp: map['created_at'] != null ? DateTime.tryParse(map['created_at']) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// 7. Trend Chart Data Point
class AdminChartPoint {
  final String label; // e.g. '01 Oct', 'Mon', 'Sarees'
  final double value;
  final double secondaryValue;

  const AdminChartPoint({
    required this.label,
    required this.value,
    this.secondaryValue = 0.0,
  });
}

/// 8. Master Consolidated Admin Metrics & Data Model
class AdminMetricsModel {
  // 1. Core KPIs
  final double totalGmv;
  final double platformCommissionRate;
  final double platformRevenue;
  final double totalCommissionEarned;
  final double totalDeliveryCharges;
  final double gatewayCharges;
  final double totalRefundsAmount;
  final double totalAdRevenue;
  final int totalOrdersCount;
  final int totalCustomersCount;
  final int totalSellersCount;
  final int activeBoutiquesCount;
  final int pendingKycCount;
  final int suspendedSellersCount;
  final int onDutyDeliveryFleetCount;
  final int totalDeliveryPartnersCount;
  final int pendingOrdersCount;
  final int openDisputesCount;

  // 2. Financial Breakdown
  double get grossSales => totalGmv;
  double get sellerEarnings => (totalGmv - totalCommissionEarned - (totalRefundsAmount * 0.90)).clamp(0.0, double.infinity);
  double get netPlatformEarnings {
    final platformRefundLoss = totalRefundsAmount * (platformCommissionRate / 100);
    final net = (platformRevenue + totalAdRevenue + (totalDeliveryCharges * 0.20)) - gatewayCharges - platformRefundLoss;
    return net.clamp(0.0, double.infinity);
  }

  // 3. Lists & Data Collections
  final List<BoutiqueVerificationItem> pendingBoutiques;
  final List<AdminSellerItem> sellers;
  final List<AdminCustomerItem> customers;
  final List<AdminDeliveryPartnerItem> deliveryPartners;
  final List<AdminOrderItem> orders;
  final List<AdminProductInventoryItem> inventoryItems;
  final List<CityZoneMetric> zoneMetrics;
  final List<DisputeTicket> disputes;
  final List<AdminAuditLogItem> auditLogs;

  // 4. Trend Data for Graphs
  final List<AdminChartPoint> revenueTrends;
  final List<AdminChartPoint> ordersTrends;
  final List<AdminChartPoint> gmvTrends;
  final List<AdminChartPoint> categorySalesDistribution;
  final List<AdminChartPoint> orderStatusDistribution;
  final List<AdminChartPoint> paymentMethodDistribution;

  const AdminMetricsModel({
    this.totalGmv = 0.0,
    this.platformCommissionRate = 10.0,
    this.platformRevenue = 0.0,
    this.totalCommissionEarned = 0.0,
    this.totalDeliveryCharges = 0.0,
    this.gatewayCharges = 0.0,
    this.totalRefundsAmount = 0.0,
    this.totalAdRevenue = 0.0,
    this.totalOrdersCount = 0,
    this.totalCustomersCount = 0,
    this.totalSellersCount = 0,
    this.activeBoutiquesCount = 0,
    this.pendingKycCount = 0,
    this.suspendedSellersCount = 0,
    this.onDutyDeliveryFleetCount = 0,
    this.totalDeliveryPartnersCount = 0,
    this.pendingOrdersCount = 0,
    this.openDisputesCount = 0,
    this.pendingBoutiques = const [],
    this.sellers = const [],
    this.customers = const [],
    this.deliveryPartners = const [],
    this.orders = const [],
    this.inventoryItems = const [],
    this.zoneMetrics = const [],
    this.disputes = const [],
    this.auditLogs = const [],
    this.revenueTrends = const [],
    this.ordersTrends = const [],
    this.gmvTrends = const [],
    this.categorySalesDistribution = const [],
    this.orderStatusDistribution = const [],
    this.paymentMethodDistribution = const [],
  });

  double get avgOrderValue => totalOrdersCount > 0 ? (totalGmv / totalOrdersCount) : 0.0;

  AdminMetricsModel copyWith({
    double? totalGmv,
    double? platformCommissionRate,
    double? platformRevenue,
    double? totalCommissionEarned,
    double? totalDeliveryCharges,
    double? gatewayCharges,
    double? totalRefundsAmount,
    double? totalAdRevenue,
    int? totalOrdersCount,
    int? totalCustomersCount,
    int? totalSellersCount,
    int? activeBoutiquesCount,
    int? pendingKycCount,
    int? suspendedSellersCount,
    int? onDutyDeliveryFleetCount,
    int? totalDeliveryPartnersCount,
    int? pendingOrdersCount,
    int? openDisputesCount,
    List<BoutiqueVerificationItem>? pendingBoutiques,
    List<AdminSellerItem>? sellers,
    List<AdminCustomerItem>? customers,
    List<AdminDeliveryPartnerItem>? deliveryPartners,
    List<AdminOrderItem>? orders,
    List<AdminProductInventoryItem>? inventoryItems,
    List<CityZoneMetric>? zoneMetrics,
    List<DisputeTicket>? disputes,
    List<AdminAuditLogItem>? auditLogs,
    List<AdminChartPoint>? revenueTrends,
    List<AdminChartPoint>? ordersTrends,
    List<AdminChartPoint>? gmvTrends,
    List<AdminChartPoint>? categorySalesDistribution,
    List<AdminChartPoint>? orderStatusDistribution,
    List<AdminChartPoint>? paymentMethodDistribution,
  }) {
    return AdminMetricsModel(
      totalGmv: totalGmv ?? this.totalGmv,
      platformCommissionRate: platformCommissionRate ?? this.platformCommissionRate,
      platformRevenue: platformRevenue ?? this.platformRevenue,
      totalCommissionEarned: totalCommissionEarned ?? this.totalCommissionEarned,
      totalDeliveryCharges: totalDeliveryCharges ?? this.totalDeliveryCharges,
      gatewayCharges: gatewayCharges ?? this.gatewayCharges,
      totalRefundsAmount: totalRefundsAmount ?? this.totalRefundsAmount,
      totalAdRevenue: totalAdRevenue ?? this.totalAdRevenue,
      totalOrdersCount: totalOrdersCount ?? this.totalOrdersCount,
      totalCustomersCount: totalCustomersCount ?? this.totalCustomersCount,
      totalSellersCount: totalSellersCount ?? this.totalSellersCount,
      activeBoutiquesCount: activeBoutiquesCount ?? this.activeBoutiquesCount,
      pendingKycCount: pendingKycCount ?? this.pendingKycCount,
      suspendedSellersCount: suspendedSellersCount ?? this.suspendedSellersCount,
      onDutyDeliveryFleetCount: onDutyDeliveryFleetCount ?? this.onDutyDeliveryFleetCount,
      totalDeliveryPartnersCount: totalDeliveryPartnersCount ?? this.totalDeliveryPartnersCount,
      pendingOrdersCount: pendingOrdersCount ?? this.pendingOrdersCount,
      openDisputesCount: openDisputesCount ?? this.openDisputesCount,
      pendingBoutiques: pendingBoutiques ?? this.pendingBoutiques,
      sellers: sellers ?? this.sellers,
      customers: customers ?? this.customers,
      deliveryPartners: deliveryPartners ?? this.deliveryPartners,
      orders: orders ?? this.orders,
      inventoryItems: inventoryItems ?? this.inventoryItems,
      zoneMetrics: zoneMetrics ?? this.zoneMetrics,
      disputes: disputes ?? this.disputes,
      auditLogs: auditLogs ?? this.auditLogs,
      revenueTrends: revenueTrends ?? this.revenueTrends,
      ordersTrends: ordersTrends ?? this.ordersTrends,
      gmvTrends: gmvTrends ?? this.gmvTrends,
      categorySalesDistribution: categorySalesDistribution ?? this.categorySalesDistribution,
      orderStatusDistribution: orderStatusDistribution ?? this.orderStatusDistribution,
      paymentMethodDistribution: paymentMethodDistribution ?? this.paymentMethodDistribution,
    );
  }
}
