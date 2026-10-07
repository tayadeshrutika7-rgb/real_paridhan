class ShopModel {
  final String id;
  final String sellerId;
  final String name;
  final String? ownerName;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String address;
  final String? contactPhone;
  final String? contactEmail;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? bankName;
  final String? bankAccountName;
  final String? gstin;
  final String? panNumber;
  final String? businessType; // sole_proprietorship, partnership, pvt_ltd, llp, artisan
  final String? tradeLicenseNumber;
  final String? aadhaarNumber;
  final String? pincode;
  final String? landmark;
  final List<String> kycDocuments;
  final double latitude;
  final double longitude;
  final String status; // pending, verified, rejected, suspended
  final List<String> categoryIds;
  final double avgRating;
  final String? razorpayLinkedAccountId;
  final String kycStatus; // not_started, pending, verified, rejected, correction_requested
  final String? kycRejectionReason;
  final String? kycNotes;
  final DateTime? kycVerifiedAt;
  final double commissionRate;
  final DateTime? createdAt;

  const ShopModel({
    required this.id,
    required this.sellerId,
    required this.name,
    this.ownerName,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    required this.address,
    this.contactPhone,
    this.contactEmail,
    this.bankAccountNumber,
    this.bankIfsc,
    this.bankName,
    this.bankAccountName,
    this.gstin,
    this.panNumber,
    this.businessType = 'sole_proprietorship',
    this.tradeLicenseNumber,
    this.aadhaarNumber,
    this.pincode,
    this.landmark,
    this.kycDocuments = const [],
    required this.latitude,
    required this.longitude,
    this.status = 'pending',
    this.categoryIds = const [],
    this.avgRating = 0.0,
    this.razorpayLinkedAccountId,
    this.kycStatus = 'not_started',
    this.kycRejectionReason,
    this.kycNotes,
    this.kycVerifiedAt,
    this.commissionRate = 10.0,
    this.createdAt,
  });

  bool get isVerified => status == 'verified' || kycStatus == 'verified';

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
      sellerId: json['seller_id'] as String? ?? json['sellerId'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Shop',
      ownerName: json['owner_name'] as String? ?? json['ownerName'] as String?,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String? ?? json['logoUrl'] as String?,
      bannerUrl: json['banner_url'] as String? ?? json['bannerUrl'] as String?,
      address: json['address'] as String? ?? '',
      contactPhone: json['contact_phone'] as String? ?? json['contactPhone'] as String?,
      contactEmail: json['contact_email'] as String? ?? json['contactEmail'] as String?,
      bankAccountNumber: json['bank_account_number'] as String? ?? json['bankAccountNumber'] as String?,
      bankIfsc: json['bank_ifsc'] as String? ?? json['bankIfsc'] as String?,
      bankName: json['bank_name'] as String? ?? json['bankName'] as String?,
      bankAccountName: json['bank_account_name'] as String? ?? json['bankAccountName'] as String?,
      gstin: json['gstin'] as String?,
      panNumber: json['pan_number'] as String? ?? json['panNumber'] as String?,
      businessType: json['business_type'] as String? ?? json['businessType'] as String? ?? 'sole_proprietorship',
      tradeLicenseNumber: json['trade_license_number'] as String? ?? json['tradeLicenseNumber'] as String?,
      aadhaarNumber: json['aadhaar_number'] as String? ?? json['aadhaarNumber'] as String?,
      pincode: json['pincode'] as String?,
      landmark: json['landmark'] as String?,
      kycDocuments: (json['kyc_documents'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
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
      kycRejectionReason: json['kyc_rejection_reason'] as String?,
      kycNotes: json['kyc_notes'] as String?,
      kycVerifiedAt: json['kyc_verified_at'] != null
          ? DateTime.tryParse(json['kyc_verified_at'] as String)
          : null,
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
      'owner_name': ownerName,
      'description': description,
      'logo_url': logoUrl,
      'banner_url': bannerUrl,
      'address': address,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'bank_account_number': bankAccountNumber,
      'bank_ifsc': bankIfsc,
      'bank_name': bankName,
      'bank_account_name': bankAccountName,
      'gstin': gstin,
      'pan_number': panNumber,
      'business_type': businessType,
      'trade_license_number': tradeLicenseNumber,
      'aadhaar_number': aadhaarNumber,
      'pincode': pincode,
      'landmark': landmark,
      'kyc_documents': kycDocuments,
      'location': 'POINT($longitude $latitude)', // PostGIS WKT
      'status': status,
      'category_ids': categoryIds,
      'avg_rating': avgRating,
      'razorpay_linked_account_id': razorpayLinkedAccountId,
      'kyc_status': kycStatus,
      'kyc_rejection_reason': kycRejectionReason,
      'kyc_notes': kycNotes,
      'kyc_verified_at': kycVerifiedAt?.toIso8601String(),
      'commission_rate': commissionRate,
    };
  }

  ShopModel copyWith({
    String? id,
    String? sellerId,
    String? name,
    String? ownerName,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    String? address,
    String? contactPhone,
    String? contactEmail,
    String? bankAccountNumber,
    String? bankIfsc,
    String? bankName,
    String? bankAccountName,
    String? gstin,
    String? panNumber,
    String? businessType,
    String? tradeLicenseNumber,
    String? aadhaarNumber,
    String? pincode,
    String? landmark,
    List<String>? kycDocuments,
    double? latitude,
    double? longitude,
    String? status,
    List<String>? categoryIds,
    double? avgRating,
    String? razorpayLinkedAccountId,
    String? kycStatus,
    String? kycRejectionReason,
    String? kycNotes,
    DateTime? kycVerifiedAt,
    double? commissionRate,
    DateTime? createdAt,
  }) {
    return ShopModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      address: address ?? this.address,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      bankName: bankName ?? this.bankName,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      gstin: gstin ?? this.gstin,
      panNumber: panNumber ?? this.panNumber,
      businessType: businessType ?? this.businessType,
      tradeLicenseNumber: tradeLicenseNumber ?? this.tradeLicenseNumber,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      kycDocuments: kycDocuments ?? this.kycDocuments,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      categoryIds: categoryIds ?? this.categoryIds,
      avgRating: avgRating ?? this.avgRating,
      razorpayLinkedAccountId:
          razorpayLinkedAccountId ?? this.razorpayLinkedAccountId,
      kycStatus: kycStatus ?? this.kycStatus,
      kycRejectionReason: kycRejectionReason ?? this.kycRejectionReason,
      kycNotes: kycNotes ?? this.kycNotes,
      kycVerifiedAt: kycVerifiedAt ?? this.kycVerifiedAt,
      commissionRate: commissionRate ?? this.commissionRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
