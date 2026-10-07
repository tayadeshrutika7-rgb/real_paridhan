class AddressModel {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String landmark;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    this.landmark = '',
    this.city = 'Amravati',
    this.state = 'Maharashtra',
    required this.pincode,
    this.latitude = 20.9320,
    this.longitude = 77.7523,
    this.isDefault = false,
  });

  String get formattedAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2,
      if (landmark.isNotEmpty) 'Near $landmark',
      '$city, $state - $pincode',
    ];
    return parts.join(', ');
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String? ?? 'addr-${DateTime.now().millisecondsSinceEpoch}',
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Recipient',
      phone: json['phone'] as String? ?? '',
      addressLine1: json['address_line1'] as String? ?? '',
      addressLine2: json['address_line2'] as String?,
      landmark: json['landmark'] as String? ?? '',
      city: json['city'] as String? ?? 'Amravati',
      state: json['state'] as String? ?? 'Maharashtra',
      pincode: (json['pincode'] ?? json['postal_code'] ?? json['postalCode'] ?? '444601').toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 20.9320,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 77.7523,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'landmark': landmark,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
    };
  }

  AddressModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? landmark,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
