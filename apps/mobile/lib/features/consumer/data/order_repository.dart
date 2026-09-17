import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/network/supabase_client.dart';
import '../domain/address_model.dart';
import '../domain/cart_item_model.dart';
import '../domain/order_model.dart';

class OrderRepository {
  static final List<AddressModel> _mockAddresses = [
    const AddressModel(
      id: 'addr-01',
      userId: 'user-01',
      fullName: 'Aarav Sharma',
      phone: '9829012345',
      addressLine1: 'Flat 402, Royal Heritage Apts',
      addressLine2: 'Near Central Park, C-Scheme',
      landmark: 'Statue Circle',
      city: 'Jaipur',
      state: 'Rajasthan',
      pincode: '302001',
      latitude: 26.9124,
      longitude: 75.7873,
      isDefault: true,
    ),
    const AddressModel(
      id: 'addr-02',
      userId: 'user-01',
      fullName: 'Aarav Sharma (Office)',
      phone: '9829012345',
      addressLine1: 'B-12, World Trade Park, Malviya Nagar',
      landmark: 'Jawahar Circle',
      city: 'Jaipur',
      state: 'Rajasthan',
      pincode: '302017',
      latitude: 26.8530,
      longitude: 75.8051,
      isDefault: false,
    ),
  ];

  static final List<OrderModel> _mockOrders = [
    OrderModel(
      id: 'ord-mock-101',
      orderNumber: 'PRD-JAIP-9281',
      consumerId: 'user-01',
      shopId: 'shop-jaipur-01',
      shopName: 'Jaipur Heritage Handlooms',
      items: [
        const OrderItemModel(
          id: 'item-01',
          productId: 'prod-01',
          variantId: 'var-01',
          productTitle: 'Handblock Printed Anarkali Kurta Set',
          size: 'M',
          color: 'Indigo Blue',
          imageUrl: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600',
          unitPrice: 1850.0,
          quantity: 1,
        ),
      ],
      subtotal: 1850.0,
      deliveryFee: 49.0,
      platformFee: 10.0,
      totalAmount: 1909.0,
      status: OrderStatus.outForDelivery,
      paymentMethod: PaymentMethod.razorpay,
      paymentStatus: PaymentStatus.paid,
      deliveryAddress: _mockAddresses.first,
      deliveryOtp: '7492',
      deliveryPartnerName: 'Ramesh Singh (Electric Scooter)',
      deliveryPartnerPhone: '+91 98765 43210',
      deliveryPartnerLat: 26.9150,
      deliveryPartnerLng: 75.7890,
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      deliveredAt: null,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Addresses CRUD
  // ---------------------------------------------------------------------------

  Future<List<AddressModel>> getAddresses(String userId) async {
    final client = SupabaseService.client;
    if (client == null) {
      return List.from(_mockAddresses);
    }

    try {
      final res = await client
          .from('delivery_addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false);

      return (res as List)
          .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[OrderRepository] Error getting addresses: $e');
      return List.from(_mockAddresses);
    }
  }

  Future<AddressModel> saveAddress(AddressModel address) async {
    final client = SupabaseService.client;
    if (client == null) {
      final idx = _mockAddresses.indexWhere((a) => a.id == address.id);
      if (idx >= 0) {
        _mockAddresses[idx] = address;
      } else {
        final newAddr = address.copyWith(id: 'addr-${DateTime.now().millisecondsSinceEpoch}');
        _mockAddresses.insert(0, newAddr);
        return newAddr;
      }
      return address;
    }

    try {
      final data = await client
          .from('delivery_addresses')
          .upsert(address.toJson())
          .select()
          .single();
      return AddressModel.fromJson(data);
    } catch (e) {
      debugPrint('[OrderRepository] Error saving address: $e');
      return address;
    }
  }

  // ---------------------------------------------------------------------------
  // Order Placement
  // ---------------------------------------------------------------------------

  Future<OrderModel> placeOrder({
    required String consumerId,
    required List<CartItemModel> cartItems,
    required AddressModel address,
    required PaymentMethod paymentMethod,
    required double subtotal,
    required double deliveryFee,
    required double platformFee,
    required double totalAmount,
  }) async {
    final client = SupabaseService.client;
    final randomOtp = (1000 + Random().nextInt(9000)).toString();
    final randomSuffix = (1000 + Random().nextInt(9000)).toString();
    final orderNum = 'PRD-${DateTime.now().year}-$randomSuffix';

    final orderItems = cartItems
        .map((c) => OrderItemModel(
              id: 'item-${DateTime.now().millisecondsSinceEpoch}-${c.variantId}',
              productId: c.productId,
              variantId: c.variantId,
              productTitle: c.productTitle,
              size: c.size,
              color: c.color,
              imageUrl: c.imageUrl,
              unitPrice: c.price,
              quantity: c.quantity,
              bargainId: c.bargainId,
            ))
        .toList();

    final shopId = cartItems.isNotEmpty ? cartItems.first.shopId : 'shop-jaipur-01';
    final shopName = cartItems.isNotEmpty ? cartItems.first.shopName : 'Local Boutique';

    final newOrder = OrderModel(
      id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: orderNum,
      consumerId: consumerId,
      shopId: shopId,
      shopName: shopName,
      items: orderItems,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      platformFee: platformFee,
      totalAmount: totalAmount,
      status: paymentMethod == PaymentMethod.cod ? OrderStatus.confirmed : OrderStatus.pending,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod == PaymentMethod.cod ? PaymentStatus.pending : PaymentStatus.paid,
      deliveryAddress: address,
      deliveryOtp: randomOtp,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      deliveredAt: null,
    );

    if (client == null) {
      _mockOrders.insert(0, newOrder);
      return newOrder;
    }

    try {
      // 1. Insert order
      final orderRes = await client.from('orders').insert({
        'order_number': orderNum,
        'consumer_id': consumerId,
        'shop_id': shopId,
        'status': paymentMethod == PaymentMethod.cod ? 'confirmed' : 'pending',
        'payment_method': paymentMethod.name,
        'payment_status': paymentMethod == PaymentMethod.cod ? 'pending' : 'paid',
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'platform_fee': platformFee,
        'total_amount': totalAmount,
        'delivery_address': address.toJson(),
        'delivery_otp': randomOtp,
      }).select().single();

      final orderId = orderRes['id'] as String;

      // 2. Insert order items
      final itemsToInsert = cartItems.map((c) => {
        'order_id': orderId,
        'product_id': c.productId,
        'variant_id': c.variantId,
        'unit_price': c.price,
        'quantity': c.quantity,
        'bargain_id': c.bargainId,
      }).toList();

      await client.from('order_items').insert(itemsToInsert);

      // 3. Clear cart
      await client.from('cart_items').delete().eq('consumer_id', consumerId);

      return newOrder.copyWith(id: orderId);
    } catch (e) {
      debugPrint('[OrderRepository] Error placing order: $e');
      _mockOrders.insert(0, newOrder);
      return newOrder;
    }
  }

  // ---------------------------------------------------------------------------
  // Order Queries
  // ---------------------------------------------------------------------------

  Future<List<OrderModel>> getConsumerOrders(String consumerId) async {
    final client = SupabaseService.client;
    if (client == null) {
      return List.from(_mockOrders);
    }

    try {
      final res = await client
          .from('orders')
          .select('*, order_items(*, products(title), product_variants(size, color)), shops(name)')
          .eq('consumer_id', consumerId)
          .order('created_at', ascending: false);

      return (res as List)
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[OrderRepository] Error getting consumer orders: $e');
      return List.from(_mockOrders);
    }
  }

  Future<List<OrderModel>> getSellerOrders(String sellerId) async {
    final client = SupabaseService.client;
    if (client == null) {
      return List.from(_mockOrders);
    }

    try {
      final res = await client
          .from('orders')
          .select('*, order_items(*, products(title), product_variants(size, color)), shops(name)')
          .order('created_at', ascending: false);

      return (res as List)
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[OrderRepository] Error getting seller orders: $e');
      return List.from(_mockOrders);
    }
  }

  Future<OrderModel?> getOrderDetails(String orderId) async {
    final client = SupabaseService.client;
    if (client == null) {
      try {
        return _mockOrders.firstWhere((o) => o.id == orderId);
      } catch (_) {
        return _mockOrders.isNotEmpty ? _mockOrders.first : null;
      }
    }

    try {
      final res = await client
          .from('orders')
          .select('*, order_items(*, products(title), product_variants(size, color)), shops(name)')
          .eq('id', orderId)
          .maybeSingle();

      return res != null ? OrderModel.fromJson(res) : null;
    } catch (e) {
      debugPrint('[OrderRepository] Error getting order details: $e');
      return _mockOrders.isNotEmpty ? _mockOrders.first : null;
    }
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final client = SupabaseService.client;
    if (client == null) {
      final idx = _mockOrders.indexWhere((o) => o.id == orderId);
      if (idx >= 0) {
        _mockOrders[idx] = _mockOrders[idx].copyWith(status: newStatus);
        return true;
      }
      return false;
    }

    try {
      await client
          .from('orders')
          .update({'status': newStatus.name, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', orderId);
      return true;
    } catch (e) {
      debugPrint('[OrderRepository] Error updating order status: $e');
      return false;
    }
  }
}
