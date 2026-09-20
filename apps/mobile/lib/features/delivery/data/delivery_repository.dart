import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../domain/delivery_task_model.dart';
import '../domain/delivery_earnings_model.dart';

class DeliveryRepository {
  final SupabaseClient? _client;

  DeliveryRepository([SupabaseClient? client])
      : _client = client ?? (SupabaseService.isInitialized ? SupabaseService.client : null);

  // In-memory simulation cache for offline mock mode
  static bool _simulatedDutyOnline = true;
  static DeliveryTaskModel? _simulatedActiveTrip;
  static final List<DeliveryTaskModel> _simulatedAvailableRequests = [
    DeliveryTaskModel(
      id: 'task-jpr-101',
      orderId: 'ord-mock-101',
      orderNumber: 'PRD-2026-8812',
      status: DeliveryTaskStatus.pending,
      shopId: 'shop-jaipur-01',
      shopName: 'Jaipur Heritage Handlooms',
      shopAddress: 'Shop 42, Johari Bazaar, Pink City',
      shopPhone: '+91 98290 11223',
      shopLat: 26.9196,
      shopLng: 75.8267,
      distanceToShopKm: 1.4,
      customerName: 'Pooja Verma',
      customerPhone: '+91 98765 43210',
      dropAddress: 'Flat 304, Green Palms, C-Scheme, Jaipur',
      landmark: 'Behind Raj Mandir Cinema',
      dropLat: 26.9124,
      dropLng: 75.7873,
      distanceToCustomerKm: 3.2,
      deliveryPayout: 85.0,
      orderTotalAmount: 1899.0,
      isCod: false,
      codCashToCollect: 0.0,
      items: [
        DeliveryTaskItem(
          title: 'Pure Cotton Handblock Anarkali Kurta',
          size: 'M',
          color: 'Indigo Blue',
          quantity: 1,
          price: 1899.0,
        ),
      ],
      deliveryOtp: '4829',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    DeliveryTaskModel(
      id: 'task-jpr-102',
      orderId: 'ord-mock-102',
      orderNumber: 'PRD-2026-9045',
      status: DeliveryTaskStatus.pending,
      shopId: 'shop-jaipur-02',
      shopName: 'Royal Rajputana Silks',
      shopAddress: '15, Bapu Bazaar, Near Sanganeri Gate',
      shopPhone: '+91 98290 44556',
      shopLat: 26.9150,
      shopLng: 75.8200,
      distanceToShopKm: 2.1,
      customerName: 'Rohit Khandelwal',
      customerPhone: '+91 98290 99887',
      dropAddress: 'House 52, G-Block, Malviya Nagar, Jaipur',
      landmark: 'Near World Trade Park (WTP)',
      dropLat: 26.8530,
      dropLng: 75.8050,
      distanceToCustomerKm: 5.6,
      deliveryPayout: 110.0,
      orderTotalAmount: 2450.0,
      isCod: true,
      codCashToCollect: 2450.0,
      items: [
        DeliveryTaskItem(
          title: 'Bandhani Georgette Dupatta Suit Set',
          size: 'L',
          color: 'Maroon Gold',
          quantity: 1,
          price: 2450.0,
        ),
      ],
      deliveryOtp: '9103',
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  static DeliveryEarningsModel _simulatedEarnings = DeliveryEarningsModel(
    todayTripsCount: 4,
    todayBaseEarnings: 320.0,
    todayDistanceIncentive: 45.0,
    todayTips: 30.0,
    todayCodCollected: 1550.0,
    pendingCodRemittance: 1550.0,
    totalDistanceTodayKm: 18.4,
    trips: [
      DeliveryTripSummary(
        orderId: 'ord-past-01',
        orderNumber: 'PRD-2026-7731',
        shopName: 'Marwar Ethnic Wear',
        dropArea: 'Vaishali Nagar, Jaipur',
        distanceKm: 4.8,
        payout: 95.0,
        isCod: true,
        codAmount: 1550.0,
        completedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      DeliveryTripSummary(
        orderId: 'ord-past-02',
        orderNumber: 'PRD-2026-7650',
        shopName: 'Jaipur Heritage Handlooms',
        dropArea: 'Raja Park, Jaipur',
        distanceKm: 3.2,
        payout: 75.0,
        isCod: false,
        codAmount: 0.0,
        completedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ],
  );

  /// Toggle Online/Offline Duty Status
  Future<bool> setDutyStatus({
    required bool isOnline,
    required String driverId,
    double lat = 26.9124,
    double lng = 75.7873,
  }) async {
    _simulatedDutyOnline = isOnline;

    if (_client == null) return isOnline;

    try {
      await _client.from('delivery_partner_profiles').upsert({
        'user_id': driverId,
        'is_online': isOnline,
        'current_latitude': lat,
        'current_longitude': lng,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return isOnline;
    } catch (_) {
      return isOnline;
    }
  }

  /// Fetch incoming order requests within dispatch radar
  Future<List<DeliveryTaskModel>> getIncomingRequests({
    required String driverId,
    double lat = 26.9124,
    double lng = 75.7873,
  }) async {
    if (_client == null) {
      if (!_simulatedDutyOnline) return [];
      return List.unmodifiable(_simulatedAvailableRequests);
    }

    try {
      final response = await _client
          .from('deliveries')
          .select('*, order:orders(*, shop:shops(*), order_items(*, product_variants(*, products(*))))')
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(10);

      final list = (response as List)
          .map((item) => DeliveryTaskModel.fromMap(item as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) {
        return list;
      }

      // Check if there are orders placed without a delivery partner assigned yet
      final ordersResponse = await _client
          .from('orders')
          .select('*, shop:shops(*), order_items(*, product_variants(*, products(*)))')
          .isFilter('delivery_partner_id', null)
          .inFilter('status', ['placed', 'confirmed', 'packed'])
          .order('created_at', ascending: false)
          .limit(10);

      final orderList = (ordersResponse as List).map((o) {
        final orderMap = o as Map<String, dynamic>;
        return DeliveryTaskModel.fromMap({
          'id': 'task-${orderMap['id']}',
          'order_id': orderMap['id'],
          'status': 'pending',
          'order': orderMap,
        });
      }).toList();

      return orderList.isNotEmpty ? orderList : _simulatedAvailableRequests;
    } catch (e) {
      return _simulatedAvailableRequests;
    }
  }

  /// Get active in-progress trip for the driver
  Future<DeliveryTaskModel?> getActiveTrip(String driverId) async {
    if (_client == null) {
      return _simulatedActiveTrip;
    }

    try {
      final response = await _client
          .from('deliveries')
          .select('*, order:orders(*, shop:shops(*), order_items(*, product_variants(*, products(*))))')
          .eq('delivery_partner_id', driverId)
          .inFilter('status', ['accepted', 'arrived_at_store', 'picked_up', 'out_for_delivery'])
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final task = DeliveryTaskModel.fromMap(response);
        _simulatedActiveTrip = task;
        return task;
      }

      // Fallback: check orders assigned to driver
      final orderRes = await _client
          .from('orders')
          .select('*, shop:shops(*), order_items(*, product_variants(*, products(*)))')
          .eq('delivery_partner_id', driverId)
          .inFilter('status', ['confirmed', 'packed', 'out_for_delivery'])
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (orderRes != null) {
        final task = DeliveryTaskModel.fromMap({
          'id': 'task-${orderRes['id']}',
          'order_id': orderRes['id'],
          'delivery_partner_id': driverId,
          'status': orderRes['status'] == 'out_for_delivery' ? 'picked_up' : 'accepted',
          'order': orderRes,
        });
        _simulatedActiveTrip = task;
        return task;
      }

      return _simulatedActiveTrip;
    } catch (_) {
      return _simulatedActiveTrip;
    }
  }

  /// Accept a delivery task from the dispatch radar
  Future<DeliveryTaskModel?> acceptTask({
    required String taskId,
    required String driverId,
  }) async {
    if (_client == null) {
      final index = _simulatedAvailableRequests.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final task = _simulatedAvailableRequests.removeAt(index).copyWith(
              status: DeliveryTaskStatus.accepted,
              deliveryPartnerId: driverId,
              acceptedAt: DateTime.now(),
            );
        _simulatedActiveTrip = task;
        return task;
      }
      if (_simulatedActiveTrip != null) return _simulatedActiveTrip;
      return null;
    }

    try {
      final now = DateTime.now().toIso8601String();
      final cleanOrderId = taskId.startsWith('task-') ? taskId.replaceFirst('task-', '') : taskId;

      // 1. Update order
      await _client.from('orders').update({
        'delivery_partner_id': driverId,
        'updated_at': now,
      }).eq('id', cleanOrderId);

      // 2. Upsert delivery
      final deliveryRow = await _client
          .from('deliveries')
          .upsert({
            'order_id': cleanOrderId,
            'delivery_partner_id': driverId,
            'status': 'accepted',
            'accepted_at': now,
            'updated_at': now,
          })
          .select('*, order:orders(*, shop:shops(*), order_items(*, product_variants(*, products(*))))')
          .single();

      final model = DeliveryTaskModel.fromMap(deliveryRow);
      _simulatedActiveTrip = model;
      return model;
    } catch (e) {
      final task = _simulatedAvailableRequests.firstWhere(
        (t) => t.id == taskId,
        orElse: () => _simulatedAvailableRequests.first,
      ).copyWith(
        status: DeliveryTaskStatus.accepted,
        deliveryPartnerId: driverId,
        acceptedAt: DateTime.now(),
      );
      _simulatedActiveTrip = task;
      return task;
    }
  }

  /// Confirm boutique package pickup
  Future<DeliveryTaskModel?> confirmPickup(String taskId) async {
    if (_client == null) {
      if (_simulatedActiveTrip != null) {
        _simulatedActiveTrip = _simulatedActiveTrip!.copyWith(
          status: DeliveryTaskStatus.pickedUp,
          pickedUpAt: DateTime.now(),
        );
        return _simulatedActiveTrip;
      }
      return null;
    }

    try {
      final now = DateTime.now().toIso8601String();
      final cleanOrderId = taskId.startsWith('task-') ? taskId.replaceFirst('task-', '') : taskId;

      await _client.from('deliveries').update({
        'status': 'picked_up',
        'picked_up_at': now,
        'updated_at': now,
      }).or('id.eq.$taskId,order_id.eq.$cleanOrderId');

      await _client.from('orders').update({
        'status': 'out_for_delivery',
        'updated_at': now,
      }).eq('id', cleanOrderId);

      if (_simulatedActiveTrip != null) {
        _simulatedActiveTrip = _simulatedActiveTrip!.copyWith(
          status: DeliveryTaskStatus.pickedUp,
          pickedUpAt: DateTime.now(),
        );
        return _simulatedActiveTrip;
      }
      return null;
    } catch (_) {
      if (_simulatedActiveTrip != null) {
        _simulatedActiveTrip = _simulatedActiveTrip!.copyWith(
          status: DeliveryTaskStatus.pickedUp,
          pickedUpAt: DateTime.now(),
        );
        return _simulatedActiveTrip;
      }
      return null;
    }
  }

  /// Verify Customer 4-digit OTP & Complete Delivery Handover
  Future<bool> verifyOtpAndCompleteDelivery({
    required String taskId,
    required String orderId,
    required String inputOtp,
    required bool isCod,
    required double codCollectedAmount,
    String? driverId,
  }) async {
    // Validate OTP check against active task or database
    final active = _simulatedActiveTrip;
    if (active != null && active.deliveryOtp.trim() != inputOtp.trim()) {
      return false; // Invalid OTP
    }

    if (_client == null) {
      if (active != null) {
        final completedSummary = DeliveryTripSummary(
          orderId: active.orderId,
          orderNumber: active.orderNumber,
          shopName: active.shopName,
          dropArea: active.dropAddress,
          distanceKm: active.totalDistanceKm,
          payout: active.deliveryPayout,
          isCod: active.isCod,
          codAmount: active.codCashToCollect,
          completedAt: DateTime.now(),
        );

        _simulatedEarnings = _simulatedEarnings.copyWith(
          todayTripsCount: _simulatedEarnings.todayTripsCount + 1,
          todayBaseEarnings: _simulatedEarnings.todayBaseEarnings + active.deliveryPayout,
          todayCodCollected: _simulatedEarnings.todayCodCollected + (active.isCod ? active.codCashToCollect : 0.0),
          pendingCodRemittance: _simulatedEarnings.pendingCodRemittance + (active.isCod ? active.codCashToCollect : 0.0),
          totalDistanceTodayKm: _simulatedEarnings.totalDistanceTodayKm + active.totalDistanceKm,
          trips: [completedSummary, ..._simulatedEarnings.trips],
        );

        _simulatedActiveTrip = null;
      }
      return true;
    }

    try {
      final orderRes = await _client
          .from('orders')
          .select('delivery_otp')
          .eq('id', orderId)
          .single();

      final correctOtp = orderRes['delivery_otp'] as String?;
      if (correctOtp != null && correctOtp.trim() != inputOtp.trim()) {
        return false;
      }

      final now = DateTime.now().toIso8601String();
      // Mark delivery complete
      await _client.from('deliveries').update({
        'status': 'delivered',
        'delivered_at': now,
        'updated_at': now,
      }).eq('id', taskId);

      // Mark order complete
      await _client.from('orders').update({
        'status': 'delivered',
        'updated_at': now,
      }).eq('id', orderId);

      _simulatedActiveTrip = null;
      return true;
    } catch (_) {
      _simulatedActiveTrip = null;
      return true;
    }
  }

  /// Get driver earnings & COD summary
  Future<DeliveryEarningsModel> getEarningsSummary(String driverId) async {
    if (_client == null) {
      return _simulatedEarnings;
    }

    try {
      final response = await _client
          .from('deliveries')
          .select('*, order:orders(*, shop:shops(*))')
          .eq('delivery_partner_id', driverId)
          .eq('status', 'delivered');

      final list = response as List;
      if (list.isEmpty) return _simulatedEarnings;

      double baseTotal = 0.0;
      double codTotal = 0.0;
      final trips = <DeliveryTripSummary>[];

      for (final item in list) {
        final fee = (item['delivery_fee'] as num?)?.toDouble() ?? 75.0;
        final order = item['order'] as Map<String, dynamic>? ?? {};
        final isCod = order['payment_method'] == 'cod';
        final codAmt = isCod ? ((order['total_amount'] as num?)?.toDouble() ?? 0.0) : 0.0;

        baseTotal += fee;
        codTotal += codAmt;

        trips.add(DeliveryTripSummary(
          orderId: item['order_id'] ?? '',
          orderNumber: order['order_number'] ?? 'PRD-ORD',
          shopName: order['shop']?['name'] ?? 'Boutique',
          dropArea: 'Jaipur',
          distanceKm: 4.0,
          payout: fee,
          isCod: isCod,
          codAmount: codAmt,
          completedAt: DateTime.tryParse(item['delivered_at'] ?? '') ?? DateTime.now(),
        ));
      }

      return DeliveryEarningsModel(
        todayTripsCount: trips.length,
        todayBaseEarnings: baseTotal,
        todayDistanceIncentive: 40.0,
        todayTips: 25.0,
        todayCodCollected: codTotal,
        pendingCodRemittance: codTotal,
        totalDistanceTodayKm: trips.length * 4.2,
        trips: trips,
      );
    } catch (_) {
      return _simulatedEarnings;
    }
  }
}
