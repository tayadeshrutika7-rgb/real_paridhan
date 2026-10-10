import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../domain/delivery_task_model.dart';
import '../domain/delivery_earnings_model.dart';
import '../domain/delivery_profile_model.dart';
import '../../admin/data/admin_repository.dart';

class DeliveryRepository {
  final SupabaseClient? _client;

  DeliveryRepository([SupabaseClient? client])
      : _client = client ?? (SupabaseService.isInitialized ? SupabaseService.client : null);

  // In-memory simulation cache for offline mock mode
  static bool _simulatedDutyOnline = true;
  static String _simulatedVerificationStatus = 'verified';
  static DeliveryTaskModel? _simulatedActiveTrip;
  static DeliveryProfileModel _simulatedProfile = const DeliveryProfileModel(
    id: '00000000-0000-0000-0000-000000000003',
  );

  static const _kDriverCodRemittancesKey = 'paridhan_driver_cod_remittances_v1';
  static final List<DeliveryCodRemittanceItem> _locallySubmittedRemittances = [];

  static Future<List<DeliveryCodRemittanceItem>> getStoredRemittances() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_kDriverCodRemittancesKey);
      if (str != null && str.isNotEmpty) {
        final list = (jsonDecode(str) as List?) ?? [];
        return list
            .map((m) => DeliveryCodRemittanceItem.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}
    return List.from(_locallySubmittedRemittances);
  }

  static Future<void> saveStoredRemittances(List<DeliveryCodRemittanceItem> list) async {
    _locallySubmittedRemittances.clear();
    _locallySubmittedRemittances.addAll(list);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDriverCodRemittancesKey, jsonEncode(list.map((e) => e.toMap()).toList()));
    } catch (_) {}
  }

  static void setSimulatedVerificationStatus(String status) {
    _simulatedVerificationStatus = status;
    _simulatedProfile = _simulatedProfile.copyWith(verificationStatus: status);
  }

  Future<String> getDriverVerificationStatus(String driverId) async {
    if (_client == null) return _simulatedVerificationStatus;

    try {
      final res = await _client
          .from('delivery_partner_profiles')
          .select('verification_status')
          .eq('id', driverId)
          .maybeSingle();

      return res?['verification_status'] as String? ?? _simulatedVerificationStatus;
    } catch (_) {
      return _simulatedVerificationStatus;
    }
  }

  /// Fetch full driver profile including bank details, UPI, and Aadhaar
  Future<DeliveryProfileModel> getDriverProfile(String driverId) async {
    if (_client == null) {
      return _simulatedProfile;
    }

    try {
      final res = await _client
          .from('delivery_partner_profiles')
          .select('*, profiles:id(full_name, phone, email)')
          .eq('id', driverId)
          .maybeSingle();

      if (res != null) {
        final profile = DeliveryProfileModel.fromMap(res as Map<String, dynamic>);
        _simulatedProfile = profile;
        _simulatedVerificationStatus = profile.verificationStatus;
        return profile;
      }
      return _simulatedProfile;
    } catch (_) {
      return _simulatedProfile;
    }
  }

  /// Update driver profile, vehicle, and submit Bank / UPI / Aadhaar KYC for Admin Verification
  Future<bool> updateDriverProfileAndKyc(DeliveryProfileModel profile) async {
    _simulatedProfile = profile.copyWith(verificationStatus: 'pending');
    _simulatedVerificationStatus = 'pending';
    _simulatedDutyOnline = false; // Cannot be online while pending

    if (_client == null) {
      return true;
    }

    try {
      final now = DateTime.now().toIso8601String();

      // 1. Update delivery_partner_profiles with bank details JSONB
      await _client.from('delivery_partner_profiles').upsert({
        'id': profile.id,
        'vehicle_type': profile.vehicleType,
        'vehicle_number': profile.vehicleNumber,
        'driving_license_url': profile.drivingLicenseUrl,
        'verification_status': 'pending', // Resubmission requires Admin review
        'bank_account_details': profile.toBankDetailsJson(),
        'updated_at': now,
      });

      // 2. Update profiles table
      try {
        await _client.from('profiles').update({
          'full_name': profile.fullName,
          'phone': profile.phone,
          'updated_at': now,
        }).eq('id', profile.id);
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('[DeliveryRepository] updateDriverProfileAndKyc error: $e');
      return true;
    }
  }
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

  /// Reset simulated in-memory state (useful for tests)
  static void resetSimulatedState() {
    _simulatedDutyOnline = true;
    _simulatedVerificationStatus = 'verified';
    _simulatedProfile = _simulatedProfile.copyWith(verificationStatus: 'verified');
    _simulatedActiveTrip = null;
    _simulatedEarnings = DeliveryEarningsModel(
      todayTripsCount: 4,
      todayBaseEarnings: 320.0,
      todayDistanceIncentive: 45.0,
      todayTips: 30.0,
      todayCodCollected: 1550.0,
      pendingCodRemittance: 1550.0,
      totalDistanceTodayKm: 18.4,
      todayPenalties: 0.0,
      penaltiesCount: 0,
      penalties: const [],
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
          completedAt: DateTime.now().subtract(const Duration(hours: 2)),
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
  }

  /// Toggle Online/Offline Duty Status
  Future<bool> setDutyStatus({
    required bool isOnline,
    required String driverId,
    double lat = 26.9124,
    double lng = 75.7873,
  }) async {
    if (isOnline) {
      final vStatus = await getDriverVerificationStatus(driverId);
      if (vStatus != 'verified' && vStatus != 'approved') {
        _simulatedDutyOnline = false;
        return false; // Cannot go online without Admin approval!
      }
    }

    _simulatedDutyOnline = isOnline;

    if (_client == null) return isOnline;

    try {
      await _client.from('delivery_partner_profiles').upsert({
        'id': driverId,
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
  /// STRICT: Without Admin approval, delivery person CANNOT get or accept orders!
  Future<List<DeliveryTaskModel>> getIncomingRequests({
    required String driverId,
    double lat = 26.9124,
    double lng = 75.7873,
  }) async {
    final vStatus = await getDriverVerificationStatus(driverId);
    if (vStatus != 'verified' && vStatus != 'approved') {
      return []; // Unapproved driver cannot receive orders
    }

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

      return orderList;
    } catch (e) {
      return [];
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

      return null;
    } catch (_) {
      return null;
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
        final task = _simulatedAvailableRequests[index].copyWith(
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
  /// STRICT: Only confirms delivery when the delivery partner enters the exact matching OTP
  Future<bool> verifyOtpAndCompleteDelivery({
    required String taskId,
    required String orderId,
    required String inputOtp,
    required bool isCod,
    required double codCollectedAmount,
    String? driverId,
  }) async {
    final cleanOrderId = taskId.startsWith('task-') ? taskId.replaceFirst('task-', '') : orderId;

    // In-memory / Mock mode
    final active = _simulatedActiveTrip;
    if (active != null && active.deliveryOtp.trim() != inputOtp.trim()) {
      debugPrint('[DeliveryRepository] Mock OTP mismatch: Expected "${active.deliveryOtp}", Got "$inputOtp"');
      return false; // Invalid OTP
    }

    if (_client == null) {
      if (active == null) {
        // If no active trip, check if any task in simulated requests has matching OTP
        final matchingReq = _simulatedAvailableRequests.where((t) => t.id == taskId || t.orderId == orderId).firstOrNull;
        if (matchingReq != null && matchingReq.deliveryOtp.trim() != inputOtp.trim()) {
          return false;
        }
      }

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

    // Real Supabase verification
    try {
      // 1. Fetch order's permanent delivery_otp
      var orderRes = await _client
          .from('orders')
          .select('id, delivery_otp, status')
          .eq('id', cleanOrderId)
          .maybeSingle();

      if (orderRes == null) {
        orderRes = await _client
            .from('orders')
            .select('id, delivery_otp, status')
            .eq('id', orderId)
            .maybeSingle();
      }

      String? correctOtp = orderRes?['delivery_otp']?.toString().trim();

      // 2. Fallback: check deliveries table if not found on orders
      if (correctOtp == null || correctOtp.isEmpty) {
        final delivRes = await _client
            .from('deliveries')
            .select('delivery_otp')
            .or('id.eq.$taskId,order_id.eq.$cleanOrderId,order_id.eq.$orderId')
            .maybeSingle();
        correctOtp = delivRes?['delivery_otp']?.toString().trim();
      }

      // 3. Fallback: check active in-memory task
      if ((correctOtp == null || correctOtp.isEmpty) && active != null) {
        correctOtp = active.deliveryOtp.trim();
      }

      // STRICT VALIDATION: OTP must be present and must strictly match
      if (correctOtp == null || correctOtp.isEmpty || correctOtp != inputOtp.trim()) {
        debugPrint('[DeliveryRepository] OTP verification failed: Expected "$correctOtp", Got "${inputOtp.trim()}"');
        return false; // Handover rejected!
      }

      final now = DateTime.now().toIso8601String();

      // 4. Mark delivery record as delivered
      await _client.from('deliveries').update({
        'status': 'delivered',
        'delivered_at': now,
        'updated_at': now,
      }).or('id.eq.$taskId,order_id.eq.$cleanOrderId,order_id.eq.$orderId');

      // 5. Mark order record as delivered
      await _client.from('orders').update({
        'status': 'delivered',
        'delivered_at': now,
        if (isCod) 'cod_collected': true,
        if (isCod) 'payment_status': 'paid',
        'updated_at': now,
      }).or('id.eq.$cleanOrderId,id.eq.$orderId');

      _simulatedActiveTrip = null;
      return true;
    } catch (e) {
      debugPrint('[DeliveryRepository] Error during OTP verification: $e');
      return false; // Error must NEVER confirm delivery!
    }
  }

  /// Reject Delivery due to Personal Emergency / Breakdown
  /// Charges ₹100 cancellation penalty on the delivery partner
  Future<bool> rejectDeliveryEmergency({
    required String taskId,
    required String orderId,
    required String driverId,
    String? orderNumber,
    String reason = 'Personal Emergency / Vehicle Breakdown',
  }) async {
    const penaltyAmount = 100.0;
    final ordNum = orderNumber ?? _simulatedActiveTrip?.orderNumber ?? 'PRD-ORD';

    // 1. Record simulated penalty
    final penaltyItem = DeliveryPenaltyItem(
      orderId: orderId,
      orderNumber: ordNum,
      amount: penaltyAmount,
      reason: reason,
      chargedAt: DateTime.now(),
    );

    _simulatedEarnings = _simulatedEarnings.copyWith(
      todayPenalties: _simulatedEarnings.todayPenalties + penaltyAmount,
      penaltiesCount: _simulatedEarnings.penaltiesCount + 1,
      penalties: [penaltyItem, ..._simulatedEarnings.penalties],
    );

    _simulatedActiveTrip = null;

    if (_client == null) {
      return true;
    }

    try {
      final now = DateTime.now().toIso8601String();
      final cleanOrderId = taskId.startsWith('task-') ? taskId.replaceFirst('task-', '') : taskId;

      // Update delivery record
      await _client.from('deliveries').update({
        'status': 'cancelled',
        'rejection_type': 'emergency',
        'rejection_reason': reason,
        'penalty_charged': penaltyAmount,
        'rejected_at': now,
        'updated_at': now,
      }).or('id.eq.$taskId,order_id.eq.$cleanOrderId');

      // Record in delivery_penalties table
      try {
        await _client.from('delivery_penalties').insert({
          'delivery_partner_id': driverId,
          'order_id': cleanOrderId,
          'amount': penaltyAmount,
          'reason': reason,
        });
      } catch (_) {}

      // Reset order back to confirmed so another driver can pick it up
      await _client.from('orders').update({
        'delivery_partner_id': null,
        'status': 'confirmed',
        'updated_at': now,
      }).eq('id', cleanOrderId);

      return true;
    } catch (_) {
      return true;
    }
  }

  /// Report Delivery Attempt Failed because Customer was Not Available
  /// Does NOT charge any penalty to the delivery partner
  Future<bool> reportCustomerUnavailable({
    required String taskId,
    required String orderId,
    required String driverId,
    String notes = 'Customer not reachable / door locked',
  }) async {
    _simulatedActiveTrip = null;

    if (_client == null) {
      return true;
    }

    try {
      final now = DateTime.now().toIso8601String();
      final cleanOrderId = taskId.startsWith('task-') ? taskId.replaceFirst('task-', '') : taskId;

      // Update delivery record
      await _client.from('deliveries').update({
        'status': 'customer_unavailable',
        'rejection_type': 'customer_unavailable',
        'rejection_reason': notes,
        'rejected_at': now,
        'updated_at': now,
      }).or('id.eq.$taskId,order_id.eq.$cleanOrderId');

      // Flag order with customer_unavailable so seller & admin can see and cancel if needed
      await _client.from('orders').update({
        'customer_unavailable': true,
        'delivery_issue': 'customer_not_available',
        'delivery_issue_notes': notes,
        'delivery_attempted_at': now,
        'updated_at': now,
      }).eq('id', cleanOrderId);

      return true;
    } catch (_) {
      return true;
    }
  }

  /// Get driver earnings & COD summary including penalties and remittances
  Future<DeliveryEarningsModel> getEarningsSummary(String driverId) async {
    final storedRemittances = await getStoredRemittances();
    final driverRemittances = storedRemittances
        .where((r) => r.driverId == driverId || r.driverId.isEmpty || driverId == '00000000-0000-0000-0000-000000000003')
        .toList();
    final totalRemitted = driverRemittances.fold<double>(0.0, (acc, r) => acc + r.amount);

    if (_client == null) {
      await AdminRepository.loadPersistedStatus();
      final paidSalaryEntry = AdminRepository.locallyPaidDriverSalaries.entries.firstWhere(
        (e) => e.key.startsWith('${driverId}_') || e.value['driver_id'] == driverId,
        orElse: () => const MapEntry('', {}),
      );
      final isPaid = paidSalaryEntry.key.isNotEmpty;
      final accruedSalary = _simulatedEarnings.todayNetEarnings;
      final pendingCod = (_simulatedEarnings.todayCodCollected - totalRemitted).clamp(0.0, double.infinity);

      return _simulatedEarnings.copyWith(
        pendingCodRemittance: pendingCod,
        remittances: driverRemittances,
        monthlySalaryStatus: isPaid ? 'Paid' : 'Pending',
        monthlySalaryAmount: isPaid
            ? ((paidSalaryEntry.value['amount'] as num?)?.toDouble() ?? accruedSalary)
            : accruedSalary,
        monthlySalaryRef: paidSalaryEntry.value['ref']?.toString(),
        monthlySalaryMethod: paidSalaryEntry.value['method']?.toString(),
        monthlySalaryPaidAt: paidSalaryEntry.value['paidAt'] != null
            ? DateTime.tryParse(paidSalaryEntry.value['paidAt'].toString())
            : null,
        monthlySalaryTripsCount: _simulatedEarnings.todayTripsCount,
      );
    }

    try {
      final response = await _client
          .from('deliveries')
          .select('*, order:orders(*, shop:shops(*))')
          .eq('delivery_partner_id', driverId)
          .eq('status', 'delivered');

      final list = (response as List?) ?? [];

      double baseTotal = 0.0;
      double codTotal = 0.0;
      double totalDistance = 0.0;
      final trips = <DeliveryTripSummary>[];

      for (final item in list) {
        final order = item['order'] as Map<String, dynamic>? ?? {};
        final payout = (item['delivery_payout'] as num?)?.toDouble() ??
            (item['delivery_fee'] as num?)?.toDouble() ??
            (order['delivery_fee'] as num?)?.toDouble() ??
            0.0;
        final dist = (item['distance_km'] as num?)?.toDouble() ?? 2.5;
        final isCod = order['payment_method'] == 'cod';
        final codAmt = isCod ? ((order['total_amount'] as num?)?.toDouble() ?? 0.0) : 0.0;

        baseTotal += payout;
        codTotal += codAmt;
        totalDistance += dist;

        trips.add(DeliveryTripSummary(
          orderId: item['order_id'] ?? '',
          orderNumber: order['order_number'] ?? 'PRD-ORD',
          shopName: order['shop']?['name'] ?? 'Boutique',
          dropArea: 'Jaipur',
          distanceKm: dist,
          payout: payout,
          isCod: isCod,
          codAmount: codAmt,
          completedAt: DateTime.tryParse(item['delivered_at'] ?? '') ?? DateTime.now(),
        ));
      }

      // Fetch real penalties for this driver from Supabase
      double totalPenalties = 0.0;
      final penalties = <DeliveryPenaltyItem>[];
      try {
        final penRes = await _client
            .from('delivery_penalties')
            .select('*, order:orders(order_number)')
            .eq('delivery_partner_id', driverId);

        if (penRes is List && penRes.isNotEmpty) {
          for (final p in penRes) {
            final amt = (p['amount'] as num?)?.toDouble() ?? 100.0;
            totalPenalties += amt;
            penalties.add(DeliveryPenaltyItem(
              orderId: p['order_id'] ?? '',
              orderNumber: p['order']?['order_number'] ?? 'PRD-ORD',
              amount: amt,
              reason: p['reason'] ?? 'Emergency Rejection / Cancellation',
              chargedAt: DateTime.tryParse(p['created_at'] ?? '') ?? DateTime.now(),
            ));
          }
        }
      } catch (_) {}

      // Fetch real salary ledger record for this driver from Supabase & Admin cache
      Map<String, dynamic>? salaryRecord;
      try {
        final profRes = await _client
            .from('delivery_partner_profiles')
            .select('bank_account_details')
            .eq('id', driverId)
            .maybeSingle();
        if (profRes != null && profRes['bank_account_details'] is Map) {
          final bad = profRes['bank_account_details'] as Map;
          if (bad['salary_record'] is Map) {
            salaryRecord = Map<String, dynamic>.from(bad['salary_record'] as Map);
          }
        }
      } catch (_) {}

      await AdminRepository.loadPersistedStatus();
      final paidSalaryEntry = AdminRepository.locallyPaidDriverSalaries.entries.firstWhere(
        (e) => e.key.startsWith('${driverId}_') || e.value['driver_id'] == driverId,
        orElse: () => const MapEntry('', {}),
      );

      final isPaid = (salaryRecord != null && salaryRecord['status']?.toString().toLowerCase() == 'paid') ||
          paidSalaryEntry.key.isNotEmpty;

      final salaryMonth = salaryRecord?['month']?.toString() ??
          paidSalaryEntry.value['month']?.toString() ??
          'October 2026';
      final netAccrued = (baseTotal - totalPenalties).clamp(0.0, double.infinity);
      final salaryAmount = isPaid
          ? ((salaryRecord?['amount'] as num?)?.toDouble() ??
              (paidSalaryEntry.value['amount'] as num?)?.toDouble() ??
              netAccrued)
          : netAccrued;
      final salaryRef = salaryRecord?['ref']?.toString() ?? paidSalaryEntry.value['ref']?.toString();
      final salaryMethod = salaryRecord?['method']?.toString() ?? paidSalaryEntry.value['method']?.toString();
      final salaryPaidAt = salaryRecord?['paid_at'] != null
          ? DateTime.tryParse(salaryRecord!['paid_at'].toString())
          : (paidSalaryEntry.value['paidAt'] != null
              ? DateTime.tryParse(paidSalaryEntry.value['paidAt'].toString())
              : null);

      final pendingCod = (codTotal - totalRemitted).clamp(0.0, double.infinity);

      return DeliveryEarningsModel(
        todayTripsCount: trips.length,
        todayBaseEarnings: baseTotal,
        todayDistanceIncentive: 0.0,
        todayTips: 0.0,
        todayPenalties: totalPenalties,
        penaltiesCount: penalties.length,
        todayCodCollected: codTotal,
        pendingCodRemittance: pendingCod,
        totalDistanceTodayKm: totalDistance,
        trips: trips,
        penalties: penalties,
        remittances: driverRemittances,
        monthlySalaryMonth: salaryMonth,
        monthlySalaryStatus: isPaid ? 'Paid' : 'Pending',
        monthlySalaryAmount: salaryAmount,
        monthlySalaryRef: salaryRef,
        monthlySalaryMethod: salaryMethod,
        monthlySalaryPaidAt: salaryPaidAt,
        monthlySalaryTripsCount: trips.length,
      );
    } catch (_) {
      return const DeliveryEarningsModel();
    }
  }

  /// Remit physical COD cash back to Admin
  Future<bool> submitCodRemittance({
    required String driverId,
    required String driverName,
    required double amount,
    required String paymentMethod,
    required String reference,
    String? notes,
    List<String>? orderIds,
    List<String>? orderNumbers,
  }) async {
    final now = DateTime.now();
    final remittanceItem = DeliveryCodRemittanceItem(
      id: 'rem-${now.millisecondsSinceEpoch}',
      driverId: driverId,
      driverName: driverName,
      amount: amount,
      status: 'pending', // Pending Admin Verification
      paymentMethod: paymentMethod,
      reference: reference,
      notes: notes,
      createdAt: now,
      orderIds: orderIds ?? const [],
      orderNumbers: orderNumbers ?? const [],
    );

    final stored = await getStoredRemittances();
    stored.insert(0, remittanceItem);
    await saveStoredRemittances(stored);

    // Update in-memory simulated state
    final remittedSum = stored
        .where((r) => r.driverId == driverId || driverId.isEmpty || driverId == '00000000-0000-0000-0000-000000000003')
        .fold<double>(0.0, (acc, r) => acc + r.amount);
    final remainingPending = (_simulatedEarnings.todayCodCollected - remittedSum).clamp(0.0, double.infinity);

    _simulatedEarnings = _simulatedEarnings.copyWith(
      pendingCodRemittance: remainingPending,
      remittances: stored
          .where((r) => r.driverId == driverId || driverId.isEmpty || driverId == '00000000-0000-0000-0000-000000000003')
          .toList(),
    );

    // Push to Supabase if connected
    if (_client != null) {
      try {
        await _client.from('cod_remittance').insert({
          'delivery_partner_id': driverId.isNotEmpty ? driverId : null,
          'amount': amount,
          'status': 'pending',
          if (orderIds != null && orderIds.isNotEmpty) 'order_id': orderIds.first,
        });
      } catch (e) {
        debugPrint('[DeliveryRepository] Supabase cod_remittance insert error: $e');
      }

      try {
        await _client.from('admin_audit_logs').insert({
          'admin_name': driverName,
          'action': 'COD_REMITTANCE_SUBMITTED',
          'target_type': 'delivery_partner',
          'target_id': driverId,
          'details': 'Rider submitted COD remittance ₹$amount via $paymentMethod (Ref: $reference)',
        });
      } catch (_) {}
    }

    return true;
  }
}
