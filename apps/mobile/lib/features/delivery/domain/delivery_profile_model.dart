import 'dart:convert';

class DeliveryProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehicleNumber;
  final String drivingLicenseNumber;
  final String drivingLicenseUrl;
  final String bankName;
  final String bankAccountNumber;
  final String bankIfsc;
  final String bankAccountName;
  final String upiId;
  final String aadhaarNumber;
  final String aadhaarUrl;
  final String verificationStatus; // 'verified', 'pending', 'rejected'
  final String? rejectionReason;
  final bool isOnline;

  const DeliveryProfileModel({
    required this.id,
    this.fullName = 'Vikram Singh (Johari Rider)',
    this.email = 'delivery1@gm.com',
    this.phone = '+91 98290 33333',
    this.vehicleType = 'Motorcycle (Hero Splendor Plus)',
    this.vehicleNumber = 'RJ 14 JP 4421',
    this.drivingLicenseNumber = 'RJ14 20210049281',
    this.drivingLicenseUrl = 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?auto=format&fit=crop&w=400&q=80',
    this.bankName = 'HDFC Bank, Johari Bazaar',
    this.bankAccountNumber = '987654321012',
    this.bankIfsc = 'HDFC0001234',
    this.bankAccountName = 'Vikram Singh',
    this.upiId = 'vikram.singh@okhdfcbank',
    this.aadhaarNumber = '987654321098',
    this.aadhaarUrl = 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=400&q=80',
    this.verificationStatus = 'verified',
    this.rejectionReason,
    this.isOnline = true,
  });

  bool get isVerified => verificationStatus == 'verified' || verificationStatus == 'approved';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';

  DeliveryProfileModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? vehicleType,
    String? vehicleNumber,
    String? drivingLicenseNumber,
    String? drivingLicenseUrl,
    String? bankName,
    String? bankAccountNumber,
    String? bankIfsc,
    String? bankAccountName,
    String? upiId,
    String? aadhaarNumber,
    String? aadhaarUrl,
    String? verificationStatus,
    String? rejectionReason,
    bool? isOnline,
  }) {
    return DeliveryProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      drivingLicenseNumber: drivingLicenseNumber ?? this.drivingLicenseNumber,
      drivingLicenseUrl: drivingLicenseUrl ?? this.drivingLicenseUrl,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      upiId: upiId ?? this.upiId,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      aadhaarUrl: aadhaarUrl ?? this.aadhaarUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  factory DeliveryProfileModel.fromMap(Map<String, dynamic> map, {Map<String, dynamic>? profileMap}) {
    Map<String, dynamic> bankMap = {};
    final rawBank = map['bank_account_details'];
    if (rawBank is Map<String, dynamic>) {
      bankMap = rawBank;
    } else if (rawBank is String && rawBank.isNotEmpty) {
      try {
        bankMap = Map<String, dynamic>.from(jsonDecode(rawBank) as Map);
      } catch (_) {}
    }

    final pMap = profileMap ?? (map['profiles'] is Map<String, dynamic> ? map['profiles'] as Map<String, dynamic> : {});

    return DeliveryProfileModel(
      id: map['id']?.toString() ?? '',
      fullName: pMap['full_name']?.toString() ?? map['full_name']?.toString() ?? 'Vikram Singh (Johari Rider)',
      email: pMap['email']?.toString() ?? map['email']?.toString() ?? 'delivery1@gm.com',
      phone: pMap['phone']?.toString() ?? map['phone']?.toString() ?? '+91 98290 33333',
      vehicleType: map['vehicle_type']?.toString() ?? 'Motorcycle (Hero Splendor Plus)',
      vehicleNumber: map['vehicle_number']?.toString() ?? 'RJ 14 JP 4421',
      drivingLicenseNumber: bankMap['driving_license_number']?.toString() ?? map['driving_license_number']?.toString() ?? 'RJ14 20210049281',
      drivingLicenseUrl: map['driving_license_url']?.toString() ?? bankMap['driving_license_url']?.toString() ?? '',
      bankName: bankMap['bank_name']?.toString() ?? 'HDFC Bank, Johari Bazaar',
      bankAccountNumber: bankMap['account_number']?.toString() ?? map['bank_account_number']?.toString() ?? '987654321012',
      bankIfsc: bankMap['ifsc']?.toString() ?? map['bank_ifsc']?.toString() ?? 'HDFC0001234',
      bankAccountName: bankMap['account_holder']?.toString() ?? pMap['full_name']?.toString() ?? 'Vikram Singh',
      upiId: bankMap['upi_id']?.toString() ?? map['upi_id']?.toString() ?? 'vikram.singh@okhdfcbank',
      aadhaarNumber: bankMap['aadhaar_number']?.toString() ?? map['aadhaar_number']?.toString() ?? '987654321098',
      aadhaarUrl: bankMap['aadhaar_url']?.toString() ?? map['aadhaar_url']?.toString() ?? '',
      verificationStatus: map['verification_status']?.toString() ?? 'verified',
      rejectionReason: bankMap['rejection_reason']?.toString() ?? map['kyc_rejection_reason']?.toString(),
      isOnline: map['is_online'] == true,
    );
  }

  Map<String, dynamic> toBankDetailsJson() {
    return {
      'bank_name': bankName,
      'account_number': bankAccountNumber,
      'ifsc': bankIfsc,
      'account_holder': bankAccountName,
      'upi_id': upiId,
      'aadhaar_number': aadhaarNumber,
      'aadhaar_url': aadhaarUrl,
      'driving_license_number': drivingLicenseNumber,
      'driving_license_url': drivingLicenseUrl,
      if (rejectionReason != null && rejectionReason!.isNotEmpty) 'rejection_reason': rejectionReason,
    };
  }
}
