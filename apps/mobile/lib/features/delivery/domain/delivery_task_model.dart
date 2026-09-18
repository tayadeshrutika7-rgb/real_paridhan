enum DeliveryTaskStatus {
  pending,
  accepted,
  arrivedAtStore,
  pickedUp,
  inTransit,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case DeliveryTaskStatus.pending:
        return 'Searching Partner';
      case DeliveryTaskStatus.accepted:
        return 'Partner Assigned';
      case DeliveryTaskStatus.arrivedAtStore:
        return 'Arrived at Store';
      case DeliveryTaskStatus.pickedUp:
        return 'Package Picked Up';
      case DeliveryTaskStatus.inTransit:
        return 'Out for Delivery';
      case DeliveryTaskStatus.delivered:
        return 'Delivered';
      case DeliveryTaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  static DeliveryTaskStatus fromString(String? val) {
    switch (val) {
      case 'accepted':
        return DeliveryTaskStatus.accepted;
      case 'arrived_at_store':
        return DeliveryTaskStatus.arrivedAtStore;
      case 'picked_up':
        return DeliveryTaskStatus.pickedUp;
      case 'in_transit':
      case 'out_for_delivery':
        return DeliveryTaskStatus.inTransit;
      case 'delivered':
        return DeliveryTaskStatus.delivered;
      case 'cancelled':
        return DeliveryTaskStatus.cancelled;
      case 'pending':
      default:
        return DeliveryTaskStatus.pending;
    }
  }

  String toDbString() {
    switch (this) {
      case DeliveryTaskStatus.accepted:
        return 'accepted';
      case DeliveryTaskStatus.arrivedAtStore:
        return 'arrived_at_store';
      case DeliveryTaskStatus.pickedUp:
        return 'picked_up';
      case DeliveryTaskStatus.inTransit:
        return 'out_for_delivery';
      case DeliveryTaskStatus.delivered:
        return 'delivered';
      case DeliveryTaskStatus.cancelled:
        return 'cancelled';
      case DeliveryTaskStatus.pending:
        return 'pending';
    }
  }
}

class DeliveryTaskItem {
  final String title;
  final String size;
  final String color;
  final int quantity;
  final double price;

  const DeliveryTaskItem({
    required this.title,
    required this.size,
    required this.color,
    required this.quantity,
    required this.price,
  });

  factory DeliveryTaskItem.fromMap(Map<String, dynamic> map) {
    return DeliveryTaskItem(
      title: map['product_title'] ?? map['title'] ?? 'Fashion Item',
      size: map['size'] ?? 'M',
      color: map['color'] ?? 'Standard',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      price: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DeliveryTaskModel {
  final String id;
  final String orderId;
  final String orderNumber;
  final String? deliveryPartnerId;
  final DeliveryTaskStatus status;
  
  // Boutique / Pickup details
  final String shopId;
  final String shopName;
  final String shopAddress;
  final String shopPhone;
  final double shopLat;
  final double shopLng;
  final double distanceToShopKm;

  // Customer / Drop-off details
  final String customerName;
  final String customerPhone;
  final String dropAddress;
  final String? landmark;
  final double dropLat;
  final double dropLng;
  final double distanceToCustomerKm;

  // Financials & Payment Mode
  final double deliveryPayout;
  final double orderTotalAmount;
  final bool isCod;
  final double codCashToCollect;

  // Items & Verification
  final List<DeliveryTaskItem> items;
  final String deliveryOtp; // 4-digit OTP matching orders.delivery_otp
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  const DeliveryTaskModel({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    this.deliveryPartnerId,
    required this.status,
    required this.shopId,
    required this.shopName,
    required this.shopAddress,
    required this.shopPhone,
    required this.shopLat,
    required this.shopLng,
    required this.distanceToShopKm,
    required this.customerName,
    required this.customerPhone,
    required this.dropAddress,
    this.landmark,
    required this.dropLat,
    required this.dropLng,
    required this.distanceToCustomerKm,
    required this.deliveryPayout,
    required this.orderTotalAmount,
    required this.isCod,
    required this.codCashToCollect,
    required this.items,
    required this.deliveryOtp,
    this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  double get totalDistanceKm => distanceToShopKm + distanceToCustomerKm;

  bool get isActive =>
      status == DeliveryTaskStatus.accepted ||
      status == DeliveryTaskStatus.arrivedAtStore ||
      status == DeliveryTaskStatus.pickedUp ||
      status == DeliveryTaskStatus.inTransit;

  bool get isCompleted => status == DeliveryTaskStatus.delivered;

  int get progressStepIndex {
    switch (status) {
      case DeliveryTaskStatus.pending:
      case DeliveryTaskStatus.accepted:
        return 0; // Heading to shop
      case DeliveryTaskStatus.arrivedAtStore:
        return 1; // At boutique
      case DeliveryTaskStatus.pickedUp:
      case DeliveryTaskStatus.inTransit:
        return 2; // On the way to customer
      case DeliveryTaskStatus.delivered:
        return 3; // Delivered
      case DeliveryTaskStatus.cancelled:
        return -1;
    }
  }

  DeliveryTaskModel copyWith({
    String? id,
    String? orderId,
    String? orderNumber,
    String? deliveryPartnerId,
    DeliveryTaskStatus? status,
    String? shopId,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    double? shopLat,
    double? shopLng,
    double? distanceToShopKm,
    String? customerName,
    String? customerPhone,
    String? dropAddress,
    String? landmark,
    double? dropLat,
    double? dropLng,
    double? distanceToCustomerKm,
    double? deliveryPayout,
    double? orderTotalAmount,
    bool? isCod,
    double? codCashToCollect,
    List<DeliveryTaskItem>? items,
    String? deliveryOtp,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
  }) {
    return DeliveryTaskModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      deliveryPartnerId: deliveryPartnerId ?? this.deliveryPartnerId,
      status: status ?? this.status,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      shopPhone: shopPhone ?? this.shopPhone,
      shopLat: shopLat ?? this.shopLat,
      shopLng: shopLng ?? this.shopLng,
      distanceToShopKm: distanceToShopKm ?? this.distanceToShopKm,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      dropAddress: dropAddress ?? this.dropAddress,
      landmark: landmark ?? this.landmark,
      dropLat: dropLat ?? this.dropLat,
      dropLng: dropLng ?? this.dropLng,
      distanceToCustomerKm: distanceToCustomerKm ?? this.distanceToCustomerKm,
      deliveryPayout: deliveryPayout ?? this.deliveryPayout,
      orderTotalAmount: orderTotalAmount ?? this.orderTotalAmount,
      isCod: isCod ?? this.isCod,
      codCashToCollect: codCashToCollect ?? this.codCashToCollect,
      items: items ?? this.items,
      deliveryOtp: deliveryOtp ?? this.deliveryOtp,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  factory DeliveryTaskModel.fromMap(Map<String, dynamic> map) {
    final order = map['order'] as Map<String, dynamic>? ?? {};
    final shop = order['shop'] as Map<String, dynamic>? ?? {};
    final address = order['delivery_address'] as Map<String, dynamic>? ?? {};
    final rawItems = (order['order_items'] as List?) ?? [];

    final isCod = (order['payment_method'] == 'cod') || (map['is_cod'] == true);
    final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;

    return DeliveryTaskModel(
      id: map['id'] ?? '',
      orderId: map['order_id'] ?? order['id'] ?? '',
      orderNumber: order['order_number'] ?? 'PRD-ORD',
      deliveryPartnerId: map['delivery_partner_id'],
      status: DeliveryTaskStatus.fromString(map['status'] ?? order['status']),
      shopId: shop['id'] ?? order['shop_id'] ?? '',
      shopName: shop['name'] ?? 'Local Boutique',
      shopAddress: shop['address_line1'] ?? 'Boutique Store Address',
      shopPhone: shop['phone'] ?? '9829000000',
      shopLat: (shop['latitude'] as num?)?.toDouble() ?? 26.9124,
      shopLng: (shop['longitude'] as num?)?.toDouble() ?? 75.7873,
      distanceToShopKm: (map['distance_to_shop_km'] as num?)?.toDouble() ?? 1.8,
      customerName: address['full_name'] ?? 'Customer',
      customerPhone: address['phone'] ?? '9876543210',
      dropAddress: address['address_line1'] ?? 'Delivery Address',
      landmark: address['landmark'],
      dropLat: (address['latitude'] as num?)?.toDouble() ?? 26.9200,
      dropLng: (address['longitude'] as num?)?.toDouble() ?? 75.8000,
      distanceToCustomerKm: (map['distance_to_customer_km'] as num?)?.toDouble() ?? 3.4,
      deliveryPayout: (map['delivery_fee'] as num?)?.toDouble() ?? (map['payout'] as num?)?.toDouble() ?? 75.0,
      orderTotalAmount: totalAmount,
      isCod: isCod,
      codCashToCollect: isCod ? totalAmount : 0.0,
      items: rawItems.map((item) => DeliveryTaskItem.fromMap(item as Map<String, dynamic>)).toList(),
      deliveryOtp: order['delivery_otp'] ?? map['delivery_otp'] ?? '1234',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
      acceptedAt: map['accepted_at'] != null ? DateTime.tryParse(map['accepted_at']) : null,
      pickedUpAt: map['picked_up_at'] != null ? DateTime.tryParse(map['picked_up_at']) : null,
      deliveredAt: map['delivered_at'] != null ? DateTime.tryParse(map['delivered_at']) : null,
    );
  }
}
