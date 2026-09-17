import 'address_model.dart';

enum OrderStatus {
  pending,
  confirmed,
  readyForPickup,
  pickedUp,
  outForDelivery,
  delivered,
  cancelled,
  returned,
}

enum PaymentMethod {
  razorpay,
  cod,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}

class OrderItemModel {
  final String id;
  final String productId;
  final String variantId;
  final String productTitle;
  final String size;
  final String color;
  final String imageUrl;
  final double unitPrice;
  final int quantity;
  final String? bargainId;

  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.variantId,
    required this.productTitle,
    required this.size,
    required this.color,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    this.bargainId,
  });

  double get totalPrice => unitPrice * quantity;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      variantId: json['variant_id'] as String? ?? '',
      productTitle: json['product_title'] as String? ?? json['products']?['title'] as String? ?? 'Garment Item',
      size: json['size'] as String? ?? json['product_variants']?['size'] as String? ?? 'Free Size',
      color: json['color'] as String? ?? json['product_variants']?['color'] as String? ?? 'Standard',
      imageUrl: json['image_url'] as String? ?? 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
      bargainId: json['bargain_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'variant_id': variantId,
      'product_title': productTitle,
      'size': size,
      'color': color,
      'image_url': imageUrl,
      'unit_price': unitPrice,
      'quantity': quantity,
      'bargain_id': bargainId,
    };
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String consumerId;
  final String shopId;
  final String shopName;
  final List<OrderItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double platformFee;
  final double discount;
  final double totalAmount;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final AddressModel deliveryAddress;
  final String deliveryOtp;
  final String? deliveryPartnerName;
  final String? deliveryPartnerPhone;
  final double? deliveryPartnerLat;
  final double? deliveryPartnerLng;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deliveredAt;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.consumerId,
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.subtotal,
    this.deliveryFee = 49.0,
    this.platformFee = 10.0,
    this.discount = 0.0,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    this.paymentMethod = PaymentMethod.razorpay,
    this.paymentStatus = PaymentStatus.pending,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.deliveryAddress,
    required this.deliveryOtp,
    this.deliveryPartnerName,
    this.deliveryPartnerPhone,
    this.deliveryPartnerLat,
    this.deliveryPartnerLng,
    required this.createdAt,
    required this.updatedAt,
    this.deliveredAt,
  });

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed by Boutique';
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.returned:
        return 'Returned';
    }
  }

  int get statusStepIndex {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.readyForPickup:
        return 2;
      case OrderStatus.pickedUp:
      case OrderStatus.outForDelivery:
        return 3;
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
      case OrderStatus.returned:
        return -1;
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? 'pending';
    final rawPayMethod = json['payment_method'] as String? ?? 'razorpay';
    final rawPayStatus = json['payment_status'] as String? ?? 'pending';

    final itemsData = json['order_items'] as List<dynamic>? ?? [];
    final itemsList = itemsData
        .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    AddressModel address;
    if (json['delivery_address'] != null && json['delivery_address'] is Map) {
      address = AddressModel.fromJson(json['delivery_address'] as Map<String, dynamic>);
    } else {
      address = const AddressModel(
        id: 'addr-default',
        userId: '',
        fullName: 'Customer',
        phone: '9876543210',
        addressLine1: 'Johari Bazaar',
        pincode: '302001',
      );
    }

    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? 'PRD-${json['id'].toString().substring(0, 8).toUpperCase()}',
      consumerId: json['consumer_id'] as String? ?? '',
      shopId: json['shop_id'] as String? ?? '',
      shopName: json['shop_name'] as String? ?? json['shops']?['name'] as String? ?? 'Local Boutique',
      items: itemsList,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 49.0,
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 10.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == rawStatus.replaceAll('_', '').toLowerCase(),
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name.toLowerCase() == rawPayMethod.toLowerCase(),
        orElse: () => PaymentMethod.razorpay,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == rawPayStatus.toLowerCase(),
        orElse: () => PaymentStatus.pending,
      ),
      razorpayOrderId: json['razorpay_order_id'] as String?,
      razorpayPaymentId: json['razorpay_payment_id'] as String?,
      deliveryAddress: address,
      deliveryOtp: json['delivery_otp'] as String? ?? '4829',
      deliveryPartnerName: json['delivery_partner_name'] as String?,
      deliveryPartnerPhone: json['delivery_partner_phone'] as String?,
      deliveryPartnerLat: (json['delivery_partner_lat'] as num?)?.toDouble(),
      deliveryPartnerLng: (json['delivery_partner_lng'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'consumer_id': consumerId,
      'shop_id': shopId,
      'shop_name': shopName,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'platform_fee': platformFee,
      'discount': discount,
      'total_amount': totalAmount,
      'status': status.name,
      'payment_method': paymentMethod.name,
      'payment_status': paymentStatus.name,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'delivery_address': deliveryAddress.toJson(),
      'delivery_otp': deliveryOtp,
      'delivery_partner_name': deliveryPartnerName,
      'delivery_partner_phone': deliveryPartnerPhone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? consumerId,
    String? shopId,
    String? shopName,
    List<OrderItemModel>? items,
    double? subtotal,
    double? deliveryFee,
    double? platformFee,
    double? discount,
    double? totalAmount,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    AddressModel? deliveryAddress,
    String? deliveryOtp,
    String? deliveryPartnerName,
    String? deliveryPartnerPhone,
    double? deliveryPartnerLat,
    double? deliveryPartnerLng,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deliveredAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      consumerId: consumerId ?? this.consumerId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      platformFee: platformFee ?? this.platformFee,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryOtp: deliveryOtp ?? this.deliveryOtp,
      deliveryPartnerName: deliveryPartnerName ?? this.deliveryPartnerName,
      deliveryPartnerPhone: deliveryPartnerPhone ?? this.deliveryPartnerPhone,
      deliveryPartnerLat: deliveryPartnerLat ?? this.deliveryPartnerLat,
      deliveryPartnerLng: deliveryPartnerLng ?? this.deliveryPartnerLng,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}
