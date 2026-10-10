import 'dart:convert';

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
  final String sellerId;
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
  final String? bankAccountName;
  final String panNumber;
  final String aadhaarNumber;
  final String businessRegNumber;
  final String? businessType;
  final String? landmark;
  final String? pincode;
  final String? description;
  final List<String> submittedDocuments;
  final String? kycNotes;
  final String? rejectionReason;
  final KycStatus status;
  final DateTime submittedAt;
  final DateTime? verifiedAt;

  const BoutiqueVerificationItem({
    required this.id,
    this.sellerId = '',
    required this.shopName,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.gstin,
    required this.address,
    required this.cityZone,
    this.landmark = 'Johari Bazaar',
    this.pincode = '302001',
    this.businessType = 'Sole Proprietorship',
    this.bannerUrl,
    this.licenseDocumentUrl,
    this.bankAccountNumber = '987654321012',
    this.bankIfsc = 'HDFC0001234',
    this.bankName = 'HDFC Bank, Johari Bazaar',
    this.bankAccountName = 'Boutique Owner',
    this.panNumber = 'ABCDE1234F',
    this.aadhaarNumber = '987654321098',
    this.businessRegNumber = 'RJ-JP-2024-8842',
    this.submittedDocuments = const [],
    this.kycNotes,
    this.rejectionReason,
    this.description,
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

  /// Direct Unmasked Full Accessors for Admin Verification
  String get unmaskedPan => panNumber;
  String get unmaskedAadhaar => aadhaarNumber;
  String get unmaskedBankAccount => bankAccountNumber;

  BoutiqueVerificationItem copyWith({
    String? id,
    String? sellerId,
    String? shopName,
    String? ownerName,
    String? ownerEmail,
    String? ownerPhone,
    String? gstin,
    String? address,
    String? cityZone,
    String? landmark,
    String? pincode,
    String? businessType,
    String? bannerUrl,
    String? licenseDocumentUrl,
    String? bankAccountNumber,
    String? bankIfsc,
    String? bankName,
    String? bankAccountName,
    String? panNumber,
    String? aadhaarNumber,
    String? businessRegNumber,
    String? description,
    List<String>? submittedDocuments,
    String? kycNotes,
    String? rejectionReason,
    KycStatus? status,
    DateTime? submittedAt,
    DateTime? verifiedAt,
  }) {
    return BoutiqueVerificationItem(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      gstin: gstin ?? this.gstin,
      address: address ?? this.address,
      cityZone: cityZone ?? this.cityZone,
      landmark: landmark ?? this.landmark,
      pincode: pincode ?? this.pincode,
      businessType: businessType ?? this.businessType,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      licenseDocumentUrl: licenseDocumentUrl ?? this.licenseDocumentUrl,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      bankName: bankName ?? this.bankName,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      panNumber: panNumber ?? this.panNumber,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      businessRegNumber: businessRegNumber ?? this.businessRegNumber,
      description: description ?? this.description,
      submittedDocuments: submittedDocuments ?? this.submittedDocuments,
      kycNotes: kycNotes ?? this.kycNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  factory BoutiqueVerificationItem.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> kycMeta = {};
    String cleanDesc = '';
    final rawDesc = map['description']?.toString() ?? '';
    if (rawDesc.contains('[KYC_META]:')) {
      final parts = rawDesc.split('[KYC_META]:');
      cleanDesc = parts[0].trim();
      if (parts.length > 1) {
        try {
          kycMeta = Map<String, dynamic>.from(jsonDecode(parts[1].trim()) as Map);
        } catch (_) {}
      }
    } else {
      cleanDesc = rawDesc.trim();
    }

    String resolveStr(List<dynamic> candidates, String fallback) {
      for (final c in candidates) {
        if (c != null) {
          final s = c.toString().trim();
          if (s.isNotEmpty) return s;
        }
      }
      return fallback;
    }

    final kycDocs = <String>[];
    for (final source in [
      map['submitted_documents'],
      map['kyc_documents'],
      kycMeta['kyc_documents'],
    ]) {
      if (source is List) {
        for (final item in source) {
          final str = item?.toString().trim() ?? '';
          if (str.isNotEmpty && !kycDocs.contains(str)) {
            kycDocs.add(str);
          }
        }
      }
    }

    final kycStatusStr = resolveStr([
      map['kyc_status'],
      if (map['is_verified'] == true) 'approved',
      if (map['status'] == 'verified') 'approved',
      if (map['status'] == 'pending') 'pending',
    ], 'not_started');

    final owner = resolveStr([
      map['owner_name'],
      map['full_name'],
      kycMeta['owner_name'],
    ], 'Boutique Owner');

    return BoutiqueVerificationItem(
      id: map['id']?.toString() ?? '',
      sellerId: map['seller_id']?.toString() ?? '',
      shopName: resolveStr([map['name'], map['shop_name'], kycMeta['name']], 'Boutique Store'),
      ownerName: owner,
      ownerEmail: resolveStr([map['owner_email'], map['email'], map['contact_email'], kycMeta['contact_email']], 'seller@paridhan.local'),
      ownerPhone: resolveStr([map['phone'], map['contact_phone'], kycMeta['contact_phone']], '+91 98290 00000'),
      gstin: resolveStr([map['gstin'], kycMeta['gstin']], '08AAAAA0000A1Z5'),
      address: resolveStr([map['address'], map['address_line1'], kycMeta['address']], 'Jaipur, Rajasthan'),
      cityZone: resolveStr([map['city_zone'], kycMeta['city_zone'], map['city'], kycMeta['landmark']], 'Pink City / Johari Bazaar'),
      landmark: resolveStr([map['landmark'], kycMeta['landmark']], 'Johari Bazaar'),
      pincode: resolveStr([map['pincode'], kycMeta['pincode']], '302001'),
      businessType: resolveStr([map['business_type'], kycMeta['business_type']], 'Sole Proprietorship'),
      bannerUrl: resolveStr([map['banner_url'], map['banner_image_url'], map['logo_url']], ''),
      licenseDocumentUrl: resolveStr([
        map['license_document_url'],
        map['license_url'],
        if (kycDocs.isNotEmpty) kycDocs.first,
      ], ''),
      bankAccountNumber: resolveStr([map['bank_account_number'], kycMeta['bank_account_number']], '987654321012'),
      bankIfsc: resolveStr([map['bank_ifsc'], kycMeta['bank_ifsc']], 'HDFC0001234'),
      bankName: resolveStr([map['bank_name'], kycMeta['bank_name']], 'HDFC Bank, Johari Bazaar'),
      bankAccountName: resolveStr([map['bank_account_name'], kycMeta['bank_account_name'], owner], owner),
      panNumber: resolveStr([map['pan_number'], kycMeta['pan_number']], 'ABCDE1234F'),
      aadhaarNumber: resolveStr([map['aadhaar_number'], kycMeta['aadhaar_number']], '987654321098'),
      businessRegNumber: resolveStr([map['business_reg_number'], map['trade_license_number'], kycMeta['trade_license_number']], 'RJ-JP-2024-8842'),
      submittedDocuments: kycDocs,
      kycNotes: resolveStr([map['kyc_notes'], kycMeta['notes']], ''),
      rejectionReason: resolveStr([map['kyc_rejection_reason'], kycMeta['rejection_reason']], ''),
      description: cleanDesc,
      status: KycStatus.fromString(kycStatusStr),
      submittedAt: map['kyc_submitted_at'] != null
          ? DateTime.tryParse(map['kyc_submitted_at'].toString()) ?? DateTime.now()
          : (kycMeta['kyc_submitted_at'] != null
              ? DateTime.tryParse(kycMeta['kyc_submitted_at'].toString()) ?? DateTime.now()
              : (map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now())),
      verifiedAt: map['kyc_verified_at'] != null
          ? DateTime.tryParse(map['kyc_verified_at'].toString())
          : (kycMeta['kyc_verified_at'] != null ? DateTime.tryParse(kycMeta['kyc_verified_at'].toString()) : null),
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
      platformRevenue: (map['platform_revenue'] as num?)?.toDouble() ?? (gmv * 0.03),
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
      status: map['status'] ?? ((map['is_verified'] == true && map['kyc_status'] == 'verified') ? 'verified' : 'pending'),
      kycStatus: KycStatus.fromString(map['kyc_status'] ?? ((map['is_verified'] == true && map['status'] == 'verified') ? 'approved' : 'pending')),
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
  final String? aadhaarDocUrl;
  final String? upiId;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? bankAccountName;
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
    this.aadhaarDocUrl,
    this.upiId = 'driver@upi',
    this.bankName = 'HDFC Bank, Johari Bazaar',
    this.bankAccountNumber = '987654321012',
    this.bankIfsc = 'HDFC0001234',
    this.bankAccountName,
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
    String? aadhaarDocUrl,
    String? upiId,
    String? bankName,
    String? bankAccountNumber,
    String? bankIfsc,
    String? bankAccountName,
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
      aadhaarDocUrl: aadhaarDocUrl ?? this.aadhaarDocUrl,
      upiId: upiId ?? this.upiId,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      bankAccountName: bankAccountName ?? this.bankAccountName,
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
    Map<String, dynamic> bankMap = {};
    final rawBank = map['bank_account_details'];
    if (rawBank is Map<String, dynamic>) {
      bankMap = rawBank;
    } else if (rawBank is String && rawBank.isNotEmpty) {
      try {
        bankMap = Map<String, dynamic>.from(jsonDecode(rawBank) as Map);
      } catch (_) {}
    }

    final profMap = map['profiles'] is Map<String, dynamic> ? map['profiles'] as Map<String, dynamic> : {};
    final name = profMap['full_name'] ?? map['full_name'] ?? map['name'] ?? 'Fleet Driver';
    final phone = profMap['phone'] ?? map['phone'] ?? '+91 98290 22222';

    return AdminDeliveryPartnerItem(
      id: map['id']?.toString() ?? '',
      name: name,
      phone: phone,
      vehicleType: map['vehicle_type'] ?? 'Two-Wheeler (EV)',
      vehicleNumber: map['vehicle_number'] ?? 'RJ 14 AB 1234',
      licenseUrl: map['driving_license_url'] ?? map['license_url'] ?? bankMap['driving_license_url'],
      drivingLicenseNumber: bankMap['driving_license_number'] ?? map['driving_license_number'] ?? 'RJ14 20210049281',
      panNumber: bankMap['pan_number'] ?? map['pan_number'] ?? 'ABCDE9876K',
      aadhaarNumber: bankMap['aadhaar_number'] ?? map['aadhaar_number'] ?? '987654321012',
      aadhaarDocUrl: bankMap['aadhaar_url'] ?? map['aadhaar_url'],
      upiId: bankMap['upi_id'] ?? map['upi_id'] ?? 'driver@upi',
      bankName: bankMap['bank_name'] ?? map['bank_name'] ?? 'HDFC Bank, Johari Bazaar',
      bankAccountNumber: bankMap['account_number'] ?? map['bank_account_number'] ?? '987654321012',
      bankIfsc: bankMap['ifsc'] ?? map['bank_ifsc'] ?? 'HDFC0001234',
      bankAccountName: bankMap['account_holder'] ?? map['bank_account_name'] ?? name,
      isOnDuty: map['is_available'] == true || map['is_on_duty'] == true || map['is_online'] == true,
      verificationStatus: map['verification_status'] ?? 'verified',
      rejectionReason: bankMap['rejection_reason'] ?? map['kyc_rejection_reason'],
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
  final String? deliveryPartnerId;
  final String? deliveryPartnerName;
  final String deliveryAddress;
  final DateTime createdAt;
  final String sellerPayoutStatus; // 'paid', 'pending', 'processing'
  final String? sellerPayoutRef;
  final DateTime? sellerPaidAt;
  final String? sellerPaymentMethod;

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
    this.deliveryPartnerId,
    this.deliveryPartnerName,
    required this.deliveryAddress,
    required this.createdAt,
    this.sellerPayoutStatus = 'pending',
    this.sellerPayoutRef,
    this.sellerPaidAt,
    this.sellerPaymentMethod,
  });

  AdminOrderItem copyWith({
    String? id,
    String? consumerName,
    String? consumerPhone,
    String? shopName,
    String? productTitles,
    int? itemCount,
    double? subtotal,
    double? deliveryFee,
    double? commissionAmount,
    double? sellerPayout,
    double? total,
    String? paymentMethod,
    String? paymentStatus,
    String? orderStatus,
    String? deliveryPartnerId,
    String? deliveryPartnerName,
    String? deliveryAddress,
    DateTime? createdAt,
    String? sellerPayoutStatus,
    String? sellerPayoutRef,
    DateTime? sellerPaidAt,
    String? sellerPaymentMethod,
  }) {
    return AdminOrderItem(
      id: id ?? this.id,
      consumerName: consumerName ?? this.consumerName,
      consumerPhone: consumerPhone ?? this.consumerPhone,
      shopName: shopName ?? this.shopName,
      productTitles: productTitles ?? this.productTitles,
      itemCount: itemCount ?? this.itemCount,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      sellerPayout: sellerPayout ?? this.sellerPayout,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      deliveryPartnerId: deliveryPartnerId ?? this.deliveryPartnerId,
      deliveryPartnerName: deliveryPartnerName ?? this.deliveryPartnerName,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      createdAt: createdAt ?? this.createdAt,
      sellerPayoutStatus: sellerPayoutStatus ?? this.sellerPayoutStatus,
      sellerPayoutRef: sellerPayoutRef ?? this.sellerPayoutRef,
      sellerPaidAt: sellerPaidAt ?? this.sellerPaidAt,
      sellerPaymentMethod: sellerPaymentMethod ?? this.sellerPaymentMethod,
    );
  }

  factory AdminOrderItem.fromMap(Map<String, dynamic> map) {
    final sub = (map['subtotal'] as num?)?.toDouble() ?? 0.0;
    final fee = (map['delivery_fee'] as num?)?.toDouble() ?? 0.0;
    final pFee = (map['platform_fee'] as num?)?.toDouble() ?? 10.0;
    final totRaw = (map['total_amount'] as num?)?.toDouble() ?? (map['total'] as num?)?.toDouble() ?? 0.0;
    final tot = totRaw > 0 ? totRaw : (sub + fee + pFee);
    final commRaw = (map['commission_amount'] as num?)?.toDouble() ?? 0.0;
    final comm = commRaw > 0 ? commRaw : (sub * 0.03);
    final payoutRaw = (map['seller_payout_amount'] as num?)?.toDouble() ?? 0.0;
    final payout = payoutRaw > 0 ? payoutRaw : (sub - comm);
    final payoutStatus = map['seller_payout_status']?.toString() ?? (map['is_seller_paid'] == true ? 'paid' : 'pending');
    final payoutRef = map['seller_payout_ref']?.toString();
    final paidAt = map['seller_paid_at'] != null ? DateTime.tryParse(map['seller_paid_at'].toString()) : null;
    final payMethod = map['seller_payment_method']?.toString();
    final partnerId = map['delivery_partner_id']?.toString();
    final partnerName = map['delivery_partner_name'] ??
        (partnerId == '00000000-0000-0000-0000-000000000003' ? 'Vikram Singh' : (partnerId == '00000000-0000-0000-0000-000000000031' ? 'Rahul Sharma' : null));

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
      deliveryPartnerId: partnerId,
      deliveryPartnerName: partnerName,
      deliveryAddress: map['delivery_address_str'] ?? 'Jaipur, Rajasthan',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) ?? DateTime.now() : DateTime.now(),
      sellerPayoutStatus: payoutStatus,
      sellerPayoutRef: payoutRef,
      sellerPaidAt: paidAt,
      sellerPaymentMethod: payMethod,
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

/// 8. Shop-wise Commission & Payback Summary Model
class ShopSettlementSummary {
  final String shopId;
  final String shopName;
  final String ownerName;
  final String bankAccountNumber;
  final String bankIfsc;
  final String bankName;
  final int eligibleOrdersCount;
  final double grossSubtotal;
  final double commissionRate;
  final double commissionAmount;
  final double netPayback;
  final double amountPaid;
  final double pendingPayback;
  final String settlementStatus; // 'Settled', 'Partial', 'Pending'

  const ShopSettlementSummary({
    required this.shopId,
    required this.shopName,
    required this.ownerName,
    required this.bankAccountNumber,
    required this.bankIfsc,
    required this.bankName,
    required this.eligibleOrdersCount,
    required this.grossSubtotal,
    this.commissionRate = 3.0,
    required this.commissionAmount,
    required this.netPayback,
    required this.amountPaid,
    required this.pendingPayback,
    required this.settlementStatus,
  });
}

/// 9. Per-Order Delivery Trip Earnings Record
class DeliveryOrderTripRecord {
  final String orderId;
  final String orderNumber;
  final DateTime deliveryTime;
  final double orderAmount;
  final double tripEarning; // Payout for this trip
  final String deliveryZone;
  final String status;

  const DeliveryOrderTripRecord({
    required this.orderId,
    required this.orderNumber,
    required this.deliveryTime,
    required this.orderAmount,
    required this.tripEarning,
    required this.deliveryZone,
    this.status = 'Completed',
  });
}

/// 10. Delivery Fleet Monthly Salary Summary Model
class DeliveryMonthlySalarySummary {
  final String driverId;
  final String driverName;
  final String phone;
  final String vehicleType;
  final String vehicleNumber;
  final String upiId;
  final String bankAccount;
  final String monthName; // e.g. 'October 2026'
  final int completedOrdersCount;
  final double perOrderEarningsTotal;
  final double monthlyIncentiveBonus;
  final double penaltyDeductions;
  final double totalCalculatedSalary;
  final double amountPaid;
  final double pendingSalary;
  final String salaryStatus; // 'Paid', 'Pending', 'Processing'
  final String? paymentReference;
  final DateTime? paidAt;
  final List<DeliveryOrderTripRecord> tripRecords;

  const DeliveryMonthlySalarySummary({
    required this.driverId,
    required this.driverName,
    required this.phone,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.upiId,
    this.bankAccount = 'SBI 30981122334',
    required this.monthName,
    required this.completedOrdersCount,
    required this.perOrderEarningsTotal,
    this.monthlyIncentiveBonus = 2500.0,
    this.penaltyDeductions = 0.0,
    required this.totalCalculatedSalary,
    this.amountPaid = 0.0,
    required this.pendingSalary,
    this.salaryStatus = 'Pending',
    this.paymentReference,
    this.paidAt,
    this.tripRecords = const [],
  });

  DeliveryMonthlySalarySummary copyWith({
    String? driverId,
    String? driverName,
    String? phone,
    String? vehicleType,
    String? vehicleNumber,
    String? upiId,
    String? bankAccount,
    String? monthName,
    int? completedOrdersCount,
    double? perOrderEarningsTotal,
    double? monthlyIncentiveBonus,
    double? penaltyDeductions,
    double? totalCalculatedSalary,
    double? amountPaid,
    double? pendingSalary,
    String? salaryStatus,
    String? paymentReference,
    DateTime? paidAt,
    List<DeliveryOrderTripRecord>? tripRecords,
  }) {
    return DeliveryMonthlySalarySummary(
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      phone: phone ?? this.phone,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      upiId: upiId ?? this.upiId,
      bankAccount: bankAccount ?? this.bankAccount,
      monthName: monthName ?? this.monthName,
      completedOrdersCount: completedOrdersCount ?? this.completedOrdersCount,
      perOrderEarningsTotal: perOrderEarningsTotal ?? this.perOrderEarningsTotal,
      monthlyIncentiveBonus: monthlyIncentiveBonus ?? this.monthlyIncentiveBonus,
      penaltyDeductions: penaltyDeductions ?? this.penaltyDeductions,
      totalCalculatedSalary: totalCalculatedSalary ?? this.totalCalculatedSalary,
      amountPaid: amountPaid ?? this.amountPaid,
      pendingSalary: pendingSalary ?? this.pendingSalary,
      salaryStatus: salaryStatus ?? this.salaryStatus,
      paymentReference: paymentReference ?? this.paymentReference,
      paidAt: paidAt ?? this.paidAt,
      tripRecords: tripRecords ?? this.tripRecords,
    );
  }
}

/// 12. Cash on Delivery (COD) Remittance & Seller Payback Item Model
class AdminCodRemittanceItem {
  final String id;
  final String orderId;
  final String orderNumber;
  final String shopId;
  final String shopName;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String driverVehicle;
  final double codAmount;
  final double commissionAmount; // 3%
  final double sellerPayout; // 97%
  final DateTime orderDate;
  final String collectionStatus; // 'collected', 'delivered'
  final String remittanceStatus; // 'pending' (with driver), 'submitted' (remitted by driver, awaiting admin verification), 'verified' (verified & received by admin)
  final String? remittanceMethod;
  final String? remittanceRef;
  final DateTime? remittedAt;
  final DateTime? verifiedAt;
  final String sellerPayoutStatus; // 'pending', 'paid'
  final String? sellerPayoutRef;
  final DateTime? sellerPaidAt;

  const AdminCodRemittanceItem({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.shopId,
    required this.shopName,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.driverVehicle,
    required this.codAmount,
    required this.commissionAmount,
    required this.sellerPayout,
    required this.orderDate,
    this.collectionStatus = 'collected',
    this.remittanceStatus = 'pending',
    this.remittanceMethod,
    this.remittanceRef,
    this.remittedAt,
    this.verifiedAt,
    this.sellerPayoutStatus = 'pending',
    this.sellerPayoutRef,
    this.sellerPaidAt,
  });

  bool get isRemittedByDriver =>
      remittanceStatus == 'submitted' || remittanceStatus == 'verified' || remittanceStatus == 'remitted';
  bool get isVerifiedByAdmin =>
      remittanceStatus == 'verified' || remittanceStatus == 'remitted';
  bool get isSellerPaid => sellerPayoutStatus.toLowerCase() == 'paid';

  AdminCodRemittanceItem copyWith({
    String? id,
    String? orderId,
    String? orderNumber,
    String? shopId,
    String? shopName,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? driverVehicle,
    double? codAmount,
    double? commissionAmount,
    double? sellerPayout,
    DateTime? orderDate,
    String? collectionStatus,
    String? remittanceStatus,
    String? remittanceMethod,
    String? remittanceRef,
    DateTime? remittedAt,
    DateTime? verifiedAt,
    String? sellerPayoutStatus,
    String? sellerPayoutRef,
    DateTime? sellerPaidAt,
  }) {
    return AdminCodRemittanceItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverVehicle: driverVehicle ?? this.driverVehicle,
      codAmount: codAmount ?? this.codAmount,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      sellerPayout: sellerPayout ?? this.sellerPayout,
      orderDate: orderDate ?? this.orderDate,
      collectionStatus: collectionStatus ?? this.collectionStatus,
      remittanceStatus: remittanceStatus ?? this.remittanceStatus,
      remittanceMethod: remittanceMethod ?? this.remittanceMethod,
      remittanceRef: remittanceRef ?? this.remittanceRef,
      remittedAt: remittedAt ?? this.remittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      sellerPayoutStatus: sellerPayoutStatus ?? this.sellerPayoutStatus,
      sellerPayoutRef: sellerPayoutRef ?? this.sellerPayoutRef,
      sellerPaidAt: sellerPaidAt ?? this.sellerPaidAt,
    );
  }
}

/// 11. Master Consolidated Admin Metrics & Data Model
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
  double get sellerEarnings => (totalGmv - totalCommissionEarned - (totalRefundsAmount * 0.97)).clamp(0.0, double.infinity);
  double get netPlatformEarnings {
    final platformRefundLoss = totalRefundsAmount * (platformCommissionRate / 100);
    final net = (platformRevenue + totalAdRevenue + (totalDeliveryCharges * 0.20)) - gatewayCharges - platformRefundLoss;
    return net.clamp(0.0, double.infinity);
  }

  // 3. Lists & Data Collections
  final List<BoutiqueVerificationItem> pendingBoutiques;
  final List<BoutiqueVerificationItem> allBoutiques;
  final List<AdminSellerItem> sellers;
  final List<AdminCustomerItem> customers;
  final List<AdminDeliveryPartnerItem> deliveryPartners;
  final List<AdminOrderItem> orders;
  final List<AdminProductInventoryItem> inventoryItems;
  final List<CityZoneMetric> zoneMetrics;
  final List<DisputeTicket> disputes;
  final List<AdminAuditLogItem> auditLogs;
  final List<ShopSettlementSummary> shopSettlements;
  final List<DeliveryMonthlySalarySummary> deliverySalaries;
  final List<AdminCodRemittanceItem> codRemittances;

  // 4. Trend Data for Graphs
  final List<AdminChartPoint> revenueTrends;
  final List<AdminChartPoint> ordersTrends;
  final List<AdminChartPoint> gmvTrends;
  final List<AdminChartPoint> categorySalesDistribution;
  final List<AdminChartPoint> orderStatusDistribution;
  final List<AdminChartPoint> paymentMethodDistribution;

  const AdminMetricsModel({
    this.totalGmv = 0.0,
    this.platformCommissionRate = 3.0,
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
    this.allBoutiques = const [],
    this.sellers = const [],
    this.customers = const [],
    this.deliveryPartners = const [],
    this.orders = const [],
    this.inventoryItems = const [],
    this.zoneMetrics = const [],
    this.disputes = const [],
    this.auditLogs = const [],
    this.shopSettlements = const [],
    this.deliverySalaries = const [],
    this.codRemittances = const [],
    this.revenueTrends = const [],
    this.ordersTrends = const [],
    this.gmvTrends = const [],
    this.categorySalesDistribution = const [],
    this.orderStatusDistribution = const [],
    this.paymentMethodDistribution = const [],
  });

  double get avgOrderValue => totalOrdersCount > 0 ? (totalGmv / totalOrdersCount) : 0.0;

  // COD Calculations
  double get totalCodCollected =>
      codRemittances.fold<double>(0.0, (acc, c) => acc + c.codAmount);
  double get totalPendingCodRemittance => codRemittances
      .where((c) => !c.isVerifiedByAdmin)
      .fold<double>(0.0, (acc, c) => acc + c.codAmount);
  double get totalReceivedCodRemittance => codRemittances
      .where((c) => c.isVerifiedByAdmin)
      .fold<double>(0.0, (acc, c) => acc + c.codAmount);
  int get pendingCodCount =>
      codRemittances.where((c) => !c.isVerifiedByAdmin).length;
  int get successfulCodCount =>
      codRemittances.where((c) => c.isVerifiedByAdmin).length;

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
    List<BoutiqueVerificationItem>? allBoutiques,
    List<AdminSellerItem>? sellers,
    List<AdminCustomerItem>? customers,
    List<AdminDeliveryPartnerItem>? deliveryPartners,
    List<AdminOrderItem>? orders,
    List<AdminProductInventoryItem>? inventoryItems,
    List<CityZoneMetric>? zoneMetrics,
    List<DisputeTicket>? disputes,
    List<AdminAuditLogItem>? auditLogs,
    List<ShopSettlementSummary>? shopSettlements,
    List<DeliveryMonthlySalarySummary>? deliverySalaries,
    List<AdminCodRemittanceItem>? codRemittances,
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
      allBoutiques: allBoutiques ?? this.allBoutiques,
      sellers: sellers ?? this.sellers,
      customers: customers ?? this.customers,
      deliveryPartners: deliveryPartners ?? this.deliveryPartners,
      orders: orders ?? this.orders,
      inventoryItems: inventoryItems ?? this.inventoryItems,
      zoneMetrics: zoneMetrics ?? this.zoneMetrics,
      disputes: disputes ?? this.disputes,
      auditLogs: auditLogs ?? this.auditLogs,
      shopSettlements: shopSettlements ?? this.shopSettlements,
      deliverySalaries: deliverySalaries ?? this.deliverySalaries,
      codRemittances: codRemittances ?? this.codRemittances,
      revenueTrends: revenueTrends ?? this.revenueTrends,
      ordersTrends: ordersTrends ?? this.ordersTrends,
      gmvTrends: gmvTrends ?? this.gmvTrends,
      categorySalesDistribution: categorySalesDistribution ?? this.categorySalesDistribution,
      orderStatusDistribution: orderStatusDistribution ?? this.orderStatusDistribution,
      paymentMethodDistribution: paymentMethodDistribution ?? this.paymentMethodDistribution,
    );
  }
}
