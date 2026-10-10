import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../domain/admin_metrics_model.dart';
import '../../seller/data/seller_repository.dart';

class AdminRepository {
  final SupabaseClient? _client;

  AdminRepository([SupabaseClient? client])
      : _client = client ?? (SupabaseService.isInitialized ? SupabaseService.client : null) {
    if (_simulatedBoutiques.isEmpty) {
      _initSimulatedBoutiques();
    }
  }

  // Persistent status tracking across browser reloads & sessions
  static final Set<String> _locallyApprovedShopIds = {};
  static final Set<String> _locallyRejectedShopIds = {};
  static final Set<String> _locallyApprovedDriverIds = {};
  static final Set<String> _locallyRejectedDriverIds = {};
  static final Map<String, Map<String, dynamic>> _locallyPaidOrderPayouts = {};
  static final Map<String, Map<String, dynamic>> _locallyPaidDriverSalaries = {};

  static const _kApprovedShopsKey = 'paridhan_approved_shop_ids';
  static const _kRejectedShopsKey = 'paridhan_rejected_shop_ids';
  static const _kApprovedDriversKey = 'paridhan_approved_driver_ids';
  static const _kRejectedDriversKey = 'paridhan_rejected_driver_ids';
  static const _kPaidOrderPayoutsKey = 'paridhan_paid_order_payouts_map';
  static const _kPaidDriverSalariesKey = 'paridhan_paid_driver_salaries_map';

  static void resetLocallyCachedStatus() {
    _locallyApprovedShopIds.clear();
    _locallyRejectedShopIds.clear();
    _locallyApprovedDriverIds.clear();
    _locallyRejectedDriverIds.clear();
    _locallyPaidOrderPayouts.clear();
    _locallyPaidDriverSalaries.clear();
    _initSimulatedBoutiques();
  }

  static void clearLocallyCachedStatusForShop(String shopId, [String? sellerId, String? shopName]) {
    _locallyApprovedShopIds.remove(shopId);
    _locallyRejectedShopIds.remove(shopId);
    if (sellerId != null && sellerId.isNotEmpty) {
      _locallyApprovedShopIds.remove(sellerId);
      _locallyRejectedShopIds.remove(sellerId);
    }
    if (shopName != null && shopName.isNotEmpty) {
      _locallyApprovedShopIds.remove(shopName);
      _locallyRejectedShopIds.remove(shopName);
    }
    _persistStatus();
  }

  static Future<void> _loadPersistedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final approvedShops = prefs.getStringList(_kApprovedShopsKey) ?? [];
      final rejectedShops = prefs.getStringList(_kRejectedShopsKey) ?? [];
      final approvedDrivers = prefs.getStringList(_kApprovedDriversKey) ?? [];
      final rejectedDrivers = prefs.getStringList(_kRejectedDriversKey) ?? [];

      _locallyApprovedShopIds.addAll(approvedShops);
      _locallyRejectedShopIds.addAll(rejectedShops);
      _locallyApprovedDriverIds.addAll(approvedDrivers);
      _locallyRejectedDriverIds.addAll(rejectedDrivers);

      final payoutsJson = prefs.getString(_kPaidOrderPayoutsKey);
      if (payoutsJson != null && payoutsJson.isNotEmpty) {
        final decoded = jsonDecode(payoutsJson) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _locallyPaidOrderPayouts[key] = value;
          }
        });
      }

      final salariesJson = prefs.getString(_kPaidDriverSalariesKey);
      if (salariesJson != null && salariesJson.isNotEmpty) {
        final decoded = jsonDecode(salariesJson) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _locallyPaidDriverSalaries[key] = value;
          }
        });
      }
    } catch (_) {}
  }

  static Future<void> _persistStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kApprovedShopsKey, _locallyApprovedShopIds.toList());
      await prefs.setStringList(_kRejectedShopsKey, _locallyRejectedShopIds.toList());
      await prefs.setStringList(_kApprovedDriversKey, _locallyApprovedDriverIds.toList());
      await prefs.setStringList(_kRejectedDriversKey, _locallyRejectedDriverIds.toList());
      await prefs.setString(_kPaidOrderPayoutsKey, jsonEncode(_locallyPaidOrderPayouts));
      await prefs.setString(_kPaidDriverSalariesKey, jsonEncode(_locallyPaidDriverSalaries));
    } catch (_) {}
  }

  // In-memory simulation cache for robust offline and test execution
  static final List<BoutiqueVerificationItem> _simulatedBoutiques = [];

  static void _initSimulatedBoutiques() {
    _simulatedBoutiques.clear();
    _simulatedBoutiques.addAll([
      BoutiqueVerificationItem(
        id: 'shop-kyc-01',
        shopName: 'Sanganeri Block Studio',
        ownerName: 'Sunita Meena',
        ownerEmail: 'sunita@sanganeriblocks.in',
        ownerPhone: '+91 98290 55443',
        gstin: '08ABCDE1234F1Z5',
        address: 'Plot 48, Industrial Area, Sanganer, Jaipur',
        cityZone: 'Sanganer Print Hub',
        bannerUrl: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600',
        bankAccountNumber: '50100456789012',
        bankIfsc: 'HDFC0001234',
        bankName: 'HDFC Bank, Sanganer Branch',
        panNumber: 'ABCDE1234F',
        aadhaarNumber: '987654321098',
        businessRegNumber: 'RJ-JP-2024-8842',
        submittedDocuments: const [
          'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600',
          'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600',
        ],
        status: KycStatus.pending,
        submittedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      BoutiqueVerificationItem(
        id: 'shop-kyc-02',
        shopName: 'Royal Rajputana Silks',
        ownerName: 'Manish Singh Rathore',
        ownerEmail: 'manish@royalrajputana.com',
        ownerPhone: '+91 98290 88776',
        gstin: '08XYZAB5678C1Z2',
        address: '15, Bapu Bazaar, Near Sanganeri Gate, Jaipur',
        cityZone: 'Pink City / Bapu Bazaar',
        bannerUrl: 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600',
        bankAccountNumber: '91882908877634',
        bankIfsc: 'SBIN0000456',
        bankName: 'State Bank of India, Bapu Bazaar',
        panNumber: 'XYZAB5678C',
        aadhaarNumber: '876543210987',
        businessRegNumber: 'RJ-JP-2023-1120',
        submittedDocuments: const [
          'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600',
        ],
        status: KycStatus.pending,
        submittedAt: DateTime.now().subtract(const Duration(hours: 9)),
      ),
      BoutiqueVerificationItem(
        id: 'shop-kyc-03',
        shopName: 'Jaipur Heritage Handlooms',
        ownerName: 'Vikram Joshi',
        ownerEmail: 'seller@paridhan.local',
        ownerPhone: '+91 98290 11223',
        gstin: '08AABCT3524Q1Z8',
        address: 'Shop 42, Johari Bazaar, Pink City, Jaipur',
        cityZone: 'Pink City / Johari Bazaar',
        bannerUrl: 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600',
        bankAccountNumber: '00123456789011',
        bankIfsc: 'ICIC0000123',
        bankName: 'ICICI Bank, Johari Bazaar',
        panNumber: 'AABCT3524Q',
        aadhaarNumber: '765432109876',
        businessRegNumber: 'RJ-JP-2022-9901',
        submittedDocuments: const [
          'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600',
        ],
        status: KycStatus.approved,
        submittedAt: DateTime.now().subtract(const Duration(days: 12)),
        verifiedAt: DateTime.now().subtract(const Duration(days: 11)),
      ),
    ]);
  }

  static final List<AdminCustomerItem> _simulatedCustomers = [
    AdminCustomerItem(
      id: 'cust-01',
      name: 'Pooja Verma',
      email: 'pooja.verma@gmail.com',
      phone: '+91 98291 11223',
      registeredAt: DateTime.now().subtract(const Duration(days: 45)),
      totalOrders: 14,
      totalSpending: 28450.0,
      refundsCount: 1,
      accountStatus: 'active',
      lastActivity: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AdminCustomerItem(
      id: 'cust-02',
      name: 'Neha Goyal',
      email: 'neha.goyal@outlook.com',
      phone: '+91 98292 33445',
      registeredAt: DateTime.now().subtract(const Duration(days: 30)),
      totalOrders: 8,
      totalSpending: 16800.0,
      refundsCount: 0,
      accountStatus: 'active',
      lastActivity: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    AdminCustomerItem(
      id: 'cust-03',
      name: 'Ananya Sharma',
      email: 'ananya.s@gmail.com',
      phone: '+91 98293 55667',
      registeredAt: DateTime.now().subtract(const Duration(days: 15)),
      totalOrders: 6,
      totalSpending: 11200.0,
      refundsCount: 0,
      accountStatus: 'active',
      lastActivity: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AdminCustomerItem(
      id: 'cust-04',
      name: 'Rohan Mathur',
      email: 'rohan.m@yahoo.com',
      phone: '+91 98294 77889',
      registeredAt: DateTime.now().subtract(const Duration(days: 5)),
      totalOrders: 2,
      totalSpending: 4200.0,
      refundsCount: 0,
      accountStatus: 'active',
      lastActivity: DateTime.now().subtract(const Duration(hours: 8)),
    ),
  ];

  static final List<AdminDeliveryPartnerItem> _simulatedFleet = [
    const AdminDeliveryPartnerItem(
      id: 'driver-01',
      name: 'Ramesh Kumawat',
      phone: '+91 98290 88123',
      vehicleType: 'Electric Scooter (EV)',
      vehicleNumber: 'RJ 14 EV 4421',
      isOnDuty: true,
      verificationStatus: 'verified',
      ordersDelivered: 184,
      totalEarnings: 12880.0,
      rating: 4.9,
      successRate: 99.1,
    ),
    const AdminDeliveryPartnerItem(
      id: 'driver-02',
      name: 'Deepak Saini',
      phone: '+91 98290 44556',
      vehicleType: 'Motorcycle',
      vehicleNumber: 'RJ 14 MK 9988',
      isOnDuty: true,
      verificationStatus: 'verified',
      ordersDelivered: 142,
      totalEarnings: 9940.0,
      rating: 4.8,
      successRate: 98.4,
    ),
    const AdminDeliveryPartnerItem(
      id: 'driver-03',
      name: 'Karan Meena',
      phone: '+91 98290 77665',
      vehicleType: 'Electric Scooter (EV)',
      vehicleNumber: 'RJ 14 EV 1209',
      isOnDuty: false,
      verificationStatus: 'verified',
      ordersDelivered: 96,
      totalEarnings: 6720.0,
      rating: 4.7,
      successRate: 97.2,
    ),
  ];

  static final List<AdminOrderItem> _simulatedOrders = [
    AdminOrderItem(
      id: 'PRD-2026-8812',
      consumerName: 'Pooja Verma',
      consumerPhone: '+91 98291 11223',
      shopName: 'Jaipur Heritage Handlooms',
      productTitles: 'Pure Silk & Zari Handloom Saree',
      itemCount: 1,
      subtotal: 3499.0,
      deliveryFee: 40.0,
      commissionAmount: 104.97,
      sellerPayout: 3394.03,
      total: 3549.0,
      paymentMethod: 'razorpay',
      paymentStatus: 'paid',
      orderStatus: 'out_for_delivery',
      deliveryPartnerName: 'Ramesh Kumawat',
      deliveryAddress: 'B-24, Tilak Nagar, Jaipur - 302004',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AdminOrderItem(
      id: 'PRD-2026-7650',
      consumerName: 'Neha Goyal',
      consumerPhone: '+91 98292 33445',
      shopName: 'Royal Rajputana Silks',
      productTitles: 'Bandhani Georgette Kurti Set',
      itemCount: 2,
      subtotal: 2199.0,
      deliveryFee: 30.0,
      commissionAmount: 65.97,
      sellerPayout: 2133.03,
      total: 2239.0,
      paymentMethod: 'razorpay',
      paymentStatus: 'paid',
      orderStatus: 'confirmed',
      deliveryPartnerName: 'Deepak Saini',
      deliveryAddress: '42, C-Scheme, Ashok Nagar, Jaipur - 302001',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    AdminOrderItem(
      id: 'PRD-2026-6541',
      consumerName: 'Ananya Sharma',
      consumerPhone: '+91 98293 55667',
      shopName: 'Sanganeri Block Studio',
      productTitles: 'Handblock Anarkali Cotton Suit',
      itemCount: 1,
      subtotal: 1899.0,
      deliveryFee: 30.0,
      commissionAmount: 56.97,
      sellerPayout: 1842.03,
      total: 1939.0,
      paymentMethod: 'cod',
      paymentStatus: 'paid',
      orderStatus: 'delivered',
      deliveryPartnerName: 'Ramesh Kumawat',
      deliveryAddress: '108, Malviya Nagar, Near WTP, Jaipur - 302017',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static final List<DisputeTicket> _simulatedDisputes = [
    DisputeTicket(
      id: 'disp-01',
      orderNumber: 'PRD-2026-8812',
      consumerName: 'Pooja Verma',
      boutiqueName: 'Jaipur Heritage Handlooms',
      issueReason: 'Size M too loose, requested instant store exchange handover',
      amount: 1899.0,
      isResolved: false,
      status: 'investigating',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    DisputeTicket(
      id: 'disp-02',
      orderNumber: 'PRD-2026-7650',
      consumerName: 'Neha Goyal',
      boutiqueName: 'Royal Rajputana Silks',
      issueReason: 'Counter offer agreed in chat but checkout price displayed full MRP',
      amount: 1550.0,
      isResolved: true,
      status: 'resolved',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DisputeTicket(
      id: 'disp-03',
      orderNumber: 'PRD-2026-5540',
      consumerName: 'Kavita Chawla',
      boutiqueName: 'Sanganeri Block Studio',
      issueReason: 'Defective stitching along border, refund claim filed',
      amount: 1299.0,
      isResolved: false,
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  static void resetSimulation() {
    _simulatedDisputes[0] = _simulatedDisputes[0].copyWith(isResolved: false, status: 'investigating');
    _simulatedDisputes[1] = _simulatedDisputes[1].copyWith(isResolved: true, status: 'resolved');
    _simulatedDisputes[2] = _simulatedDisputes[2].copyWith(isResolved: false, status: 'open');
  }

  static final List<AdminAuditLogItem> _simulatedAuditLogs = [
    AdminAuditLogItem(
      id: 'audit-01',
      adminName: 'Super Admin',
      action: 'KYC_APPROVED',
      entity: 'shop',
      entityId: 'shop-kyc-03',
      details: 'Approved KYC verification and activated Jaipur Heritage Handlooms.',
      previousValue: 'status: pending',
      newValue: 'status: approved, is_verified: true',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AdminAuditLogItem(
      id: 'audit-02',
      adminName: 'Super Admin',
      action: 'AD_APPROVED',
      entity: 'advertisement',
      entityId: 'ad-01',
      details: 'Approved Home Hero Carousel campaign for Jaipur Handlooms. Sent SMTP confirmation email.',
      previousValue: 'status: pending',
      newValue: 'status: live, expires_at: 15d',
      timestamp: DateTime.now().subtract(const Duration(hours: 7)),
    ),
    AdminAuditLogItem(
      id: 'audit-03',
      adminName: 'Super Admin',
      action: 'REFUND_RESOLVED',
      entity: 'return',
      entityId: 'disp-02',
      details: 'Resolved checkout discount pricing ticket for order PRD-2026-7650.',
      previousValue: 'is_resolved: false',
      newValue: 'is_resolved: true',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  /// Get comprehensive aggregated platform KPIs, financial records and data tables
  Future<AdminMetricsModel> getPlatformMetrics({String filterPeriod = 'This Month'}) async {
    await _loadPersistedStatus();

    final pendingList = _simulatedBoutiques.where((b) {
      if (_locallyApprovedShopIds.contains(b.id) || _locallyApprovedShopIds.contains(b.shopName)) return false;
      if (_locallyRejectedShopIds.contains(b.id) || _locallyRejectedShopIds.contains(b.shopName)) return false;
      return b.status == KycStatus.pending;
    }).toList();
    final approvedList = _simulatedBoutiques.where((b) => b.status == KycStatus.approved || _locallyApprovedShopIds.contains(b.id) || _locallyApprovedShopIds.contains(b.shopName)).toList();

    double commissionRate = 3.0;
    if (_client != null) {
      try {
        final cfgRes = await _client!.from('platform_config').select('value').eq('key', 'default_commission_rate').maybeSingle();
        if (cfgRes != null && cfgRes['value'] != null && cfgRes['value']['rate'] != null) {
          commissionRate = (cfgRes['value']['rate'] as num).toDouble();
        }
      } catch (_) {}
    }
    const defaultGmv = 184500.0;
    const defaultAdRevenue = 5097.0;
    const defaultDeliveryCharges = 4860.0;
    const defaultRefunds = 3449.0;
    const defaultGatewayCharges = defaultGmv * 0.02; // 2% payment gateway charge

    final zoneMetrics = [
      CityZoneMetric(
        zoneName: 'Pink City (Johari & Bapu Bazaar)',
        activeBoutiques: 18,
        totalOrders: 64,
        gmvAmount: 78200.0,
        platformRevenue: 78200.0 * (commissionRate / 100),
      ),
      CityZoneMetric(
        zoneName: 'C-Scheme & Civil Lines',
        activeBoutiques: 12,
        totalOrders: 42,
        gmvAmount: 49300.0,
        platformRevenue: 49300.0 * (commissionRate / 100),
      ),
      CityZoneMetric(
        zoneName: 'Sanganer Print Hub',
        activeBoutiques: 14,
        totalOrders: 35,
        gmvAmount: 34100.0,
        platformRevenue: 34100.0 * (commissionRate / 100),
      ),
      CityZoneMetric(
        zoneName: 'Malviya Nagar & WTP',
        activeBoutiques: 8,
        totalOrders: 21,
        gmvAmount: 22900.0,
        platformRevenue: 22900.0 * (commissionRate / 100),
      ),
    ];

    final inventoryItems = [
      const AdminProductInventoryItem(
        id: 'p-01',
        title: 'Sanganeri Handblock Cotton Anarkali',
        shopName: 'Sanganeri Block Studio',
        categoryName: 'Women Ethnic Kurtas',
        basePrice: 1899.0,
        totalVariants: 4,
        totalStock: 38,
        soldCount: 46,
        status: 'active',
      ),
      const AdminProductInventoryItem(
        id: 'p-02',
        title: 'Pure Silk Zari Banarasi Saree',
        shopName: 'Royal Rajputana Silks',
        categoryName: 'Sarees',
        basePrice: 4500.0,
        totalVariants: 3,
        totalStock: 4, // Low stock
        soldCount: 28,
        status: 'active',
      ),
      const AdminProductInventoryItem(
        id: 'p-03',
        title: 'Gota Patti Festive Lehenga Choli',
        shopName: 'Jaipur Heritage Handlooms',
        categoryName: 'Bridal & Lehengas',
        basePrice: 8900.0,
        totalVariants: 2,
        totalStock: 0, // Out of stock
        soldCount: 14,
        status: 'out_of_stock',
      ),
      const AdminProductInventoryItem(
        id: 'p-04',
        title: 'Jaipuri Bandhani Silk Dupatta',
        shopName: 'Royal Rajputana Silks',
        categoryName: 'Dupattas & Accessories',
        basePrice: 999.0,
        totalVariants: 5,
        totalStock: 52,
        soldCount: 65,
        status: 'active',
      ),
    ];

    final revenueTrends = [
      const AdminChartPoint(label: 'Mon', value: 24500.0, secondaryValue: 2450.0),
      const AdminChartPoint(label: 'Tue', value: 31200.0, secondaryValue: 3120.0),
      const AdminChartPoint(label: 'Wed', value: 28400.0, secondaryValue: 2840.0),
      const AdminChartPoint(label: 'Thu', value: 36800.0, secondaryValue: 3680.0),
      const AdminChartPoint(label: 'Fri', value: 42100.0, secondaryValue: 4210.0),
      const AdminChartPoint(label: 'Sat', value: 58900.0, secondaryValue: 5890.0),
      const AdminChartPoint(label: 'Sun', value: 64500.0, secondaryValue: 6450.0),
    ];

    final ordersTrends = [
      const AdminChartPoint(label: 'Mon', value: 18),
      const AdminChartPoint(label: 'Tue', value: 24),
      const AdminChartPoint(label: 'Wed', value: 22),
      const AdminChartPoint(label: 'Thu', value: 29),
      const AdminChartPoint(label: 'Fri', value: 34),
      const AdminChartPoint(label: 'Sat', value: 48),
      const AdminChartPoint(label: 'Sun', value: 52),
    ];

    final categorySales = [
      const AdminChartPoint(label: 'Kurtas & Suits', value: 68400.0),
      const AdminChartPoint(label: 'Sarees', value: 48200.0),
      const AdminChartPoint(label: 'Dupattas & Stoles', value: 36100.0),
      const AdminChartPoint(label: 'Bridal & Lehengas', value: 31800.0),
    ];

    final orderStatusDist = [
      const AdminChartPoint(label: 'Delivered', value: 112),
      const AdminChartPoint(label: 'Out for Delivery', value: 26),
      const AdminChartPoint(label: 'Confirmed', value: 16),
      const AdminChartPoint(label: 'Returned / Cancelled', value: 8),
    ];

    final paymentDist = [
      const AdminChartPoint(label: 'Razorpay UPI / Cards', value: 128),
      const AdminChartPoint(label: 'Cash on Delivery (COD)', value: 34),
    ];

    final sellersList = _simulatedBoutiques.map((b) {
      return AdminSellerItem(
        id: b.id,
        shopName: b.shopName,
        ownerName: b.ownerName,
        email: b.ownerEmail,
        phone: b.ownerPhone,
        address: b.address,
        cityZone: b.cityZone,
        gstin: b.gstin,
        status: b.status == KycStatus.approved ? 'verified' : 'pending',
        kycStatus: b.status,
        totalProducts: 18,
        totalOrders: 42,
        totalSales: 48600.0,
        commissionGenerated: 48600.0 * (commissionRate / 100),
        sellerEarnings: 48600.0 - (48600.0 * (commissionRate / 100)),
        registeredAt: b.submittedAt,
      );
    }).toList();

    if (_client == null) {
      final activeOrders = _simulatedOrders.map((o) {
        if (_locallyPaidOrderPayouts.containsKey(o.id)) {
          final paidMap = _locallyPaidOrderPayouts[o.id]!;
          return o.copyWith(
            sellerPayoutStatus: 'paid',
            sellerPayoutRef: paidMap['ref']?.toString(),
            sellerPaidAt: paidMap['paidAt'] != null ? DateTime.tryParse(paidMap['paidAt'].toString()) : null,
            sellerPaymentMethod: paidMap['method']?.toString(),
          );
        }
        return o;
      }).toList();

      final computedShopSettlements = _computeShopSettlements(
        _simulatedBoutiques,
        activeOrders,
        commissionRate,
      );

      final computedDeliverySalaries = _computeDeliverySalaries(
        _simulatedFleet,
        activeOrders,
      );

      return AdminMetricsModel(
        totalGmv: defaultGmv,
        platformCommissionRate: commissionRate,
        platformRevenue: defaultGmv * (commissionRate / 100),
        totalCommissionEarned: defaultGmv * (commissionRate / 100),
        totalDeliveryCharges: defaultDeliveryCharges,
        gatewayCharges: defaultGatewayCharges,
        totalRefundsAmount: defaultRefunds,
        totalAdRevenue: defaultAdRevenue,
        totalOrdersCount: 162,
        totalCustomersCount: _simulatedCustomers.length + 180,
        totalSellersCount: _simulatedBoutiques.length + 42,
        activeBoutiquesCount: approvedList.length + 42,
        pendingKycCount: pendingList.length,
        suspendedSellersCount: 0,
        onDutyDeliveryFleetCount: _simulatedFleet.where((d) => d.isOnDuty).length + 12,
        totalDeliveryPartnersCount: _simulatedFleet.length + 12,
        pendingOrdersCount: 6,
        openDisputesCount: _simulatedDisputes.where((d) => !d.isResolved).length,
        pendingBoutiques: pendingList,
        allBoutiques: _simulatedBoutiques,
        sellers: sellersList,
        customers: _simulatedCustomers,
        deliveryPartners: _simulatedFleet,
        orders: activeOrders,
        inventoryItems: inventoryItems,
        zoneMetrics: zoneMetrics,
        disputes: _simulatedDisputes,
        auditLogs: _simulatedAuditLogs,
        shopSettlements: computedShopSettlements,
        deliverySalaries: computedDeliverySalaries,
        revenueTrends: revenueTrends,
        ordersTrends: ordersTrends,
        categorySalesDistribution: categorySales,
        orderStatusDistribution: orderStatusDist,
        paymentMethodDistribution: paymentDist,
      );
    }

    // ─── 1. SHOPS / KYC (isolated – must not be lost if orders fail) ─────────
    List<BoutiqueVerificationItem> dbShops = [];
    List<BoutiqueVerificationItem> currentPending = [];
    List<BoutiqueVerificationItem> currentApproved = [];

    try {
      final shopsRes = await _client!.from('shops').select('*').order('updated_at', ascending: false);
      final Map<String, BoutiqueVerificationItem> uniqueShops = {};

      for (final m in (shopsRes as List)) {
        final item = BoutiqueVerificationItem.fromMap(m as Map<String, dynamic>);

        // If the live database row has status 'pending' or kyc_status 'pending', it is an active verification request!
        // Stale local storage approvals must never override live pending requests from the database.
        final isDbPending = (m['status'] == 'pending' || m['kyc_status'] == 'pending') && m['is_verified'] != true;
        if (isDbPending) {
          _locallyApprovedShopIds.remove(item.id);
          if (item.sellerId.isNotEmpty) _locallyApprovedShopIds.remove(item.sellerId);
          _locallyApprovedShopIds.remove(item.shopName);
        }

        final isApprovedLocal = !isDbPending && (_locallyApprovedShopIds.contains(item.id) ||
            (item.sellerId.isNotEmpty && _locallyApprovedShopIds.contains(item.sellerId)) ||
            _locallyApprovedShopIds.contains(item.shopName));
        final isRejectedLocal = _locallyRejectedShopIds.contains(item.id) ||
            (item.sellerId.isNotEmpty && _locallyRejectedShopIds.contains(item.sellerId)) ||
            _locallyRejectedShopIds.contains(item.shopName);

        final adjustedItem = isDbPending
            ? item.copyWith(status: KycStatus.pending)
            : (isApprovedLocal
                ? item.copyWith(status: KycStatus.approved, verifiedAt: DateTime.now())
                : (isRejectedLocal
                    ? item.copyWith(status: KycStatus.rejected, rejectionReason: item.rejectionReason ?? 'Rejected by Admin')
                    : item));

        final groupKey = item.sellerId.isNotEmpty ? item.sellerId : item.id;
        // Keep the newest updated record per seller
        if (!uniqueShops.containsKey(groupKey)) {
          uniqueShops[groupKey] = adjustedItem;
        }
      }

      dbShops = uniqueShops.values.toList();
      currentPending = dbShops.where((s) => s.status == KycStatus.pending).toList();
      currentApproved = dbShops.where((s) => s.status == KycStatus.approved).toList();
    } catch (e) {
      // Shop fetch failed – fall back to simulated data
      dbShops = List.from(_simulatedBoutiques);
      currentPending = _simulatedBoutiques.where((b) {
        if (_locallyApprovedShopIds.contains(b.id)) return false;
        if (_locallyRejectedShopIds.contains(b.id)) return false;
        return b.status == KycStatus.pending;
      }).toList();
      currentApproved = _simulatedBoutiques.where((b) =>
          b.status == KycStatus.approved || _locallyApprovedShopIds.contains(b.id)).toList();
    }

    // ─── 2. ORDERS ───────────────────────────────────────────────────────────
    double dbGmv = 0.0;
    double dbCommission = 0.0;
    double dbDeliveryFees = 0.0;
    final parsedOrders = <AdminOrderItem>[];
    try {
      final ordersRes = await _client!.from('orders').select('*').order('created_at', ascending: false);
      for (final o in (ordersRes as List)) {
        final amountRaw = (o['total_amount'] as num?)?.toDouble() ?? (o['total'] as num?)?.toDouble() ?? 0.0;
        final subtotal = (o['subtotal'] as num?)?.toDouble() ?? 0.0;
        final fee = (o['delivery_fee'] as num?)?.toDouble() ?? 0.0;
        final pFee = (o['platform_fee'] as num?)?.toDouble() ?? 10.0;
        final amount = amountRaw > 0 ? amountRaw : (subtotal + fee + pFee);

        final commRaw = (o['commission_amount'] as num?)?.toDouble() ?? 0.0;
        final comm = commRaw > 0 ? commRaw : (subtotal * (commissionRate / 100));

        dbGmv += amount;
        dbCommission += comm;
        dbDeliveryFees += fee;

        var orderItem = AdminOrderItem.fromMap(o as Map<String, dynamic>);
        if (_locallyPaidOrderPayouts.containsKey(orderItem.id)) {
          final paidMap = _locallyPaidOrderPayouts[orderItem.id]!;
          orderItem = orderItem.copyWith(
            sellerPayoutStatus: 'paid',
            sellerPayoutRef: paidMap['ref']?.toString(),
            sellerPaidAt: paidMap['paidAt'] != null ? DateTime.tryParse(paidMap['paidAt'].toString()) : null,
            sellerPaymentMethod: paidMap['method']?.toString(),
          );
        }
        parsedOrders.add(orderItem);
      }
    } catch (_) {}

    // ─── 3. ADVERTISEMENTS ───────────────────────────────────────────────────
    double dbAdRev = 0.0;
    try {
      final adsRes = await _client!.from('advertisements').select('budget, status');
      for (final a in (adsRes as List)) {
        if (a['status'] == 'approved' || a['status'] == 'live' || a['status'] == 'completed') {
          dbAdRev += (a['budget'] as num?)?.toDouble() ?? 0.0;
        }
      }
    } catch (_) {}

    // ─── 4. RETURNS / DISPUTES ───────────────────────────────────────────────
    double dbRefunds = 0.0;
    final parsedDisputes = <DisputeTicket>[];
    try {
      final retRes = await _client!.from('returns_refunds').select('*');
      for (final r in (retRes as List)) {
        final isRefundDone = r['status'] == 'refunded' || r['status'] == 'resolved';
        if (isRefundDone) dbRefunds += (r['refund_amount'] as num?)?.toDouble() ?? 0.0;
        parsedDisputes.add(DisputeTicket.fromMap(r as Map<String, dynamic>));
      }
    } catch (_) {}

    // ─── 5. AUDIT LOGS ───────────────────────────────────────────────────────
    final parsedLogs = <AdminAuditLogItem>[];
    try {
      final logsRes = await _client!.from('admin_audit_logs').select('*').order('created_at', ascending: false).limit(50);
      for (final l in (logsRes as List)) {
        parsedLogs.add(AdminAuditLogItem.fromMap(l as Map<String, dynamic>));
      }
    } catch (_) {}

    // ─── 6. LIVE PROFILES COUNT (CONSUMERS & RIDERS) ─────────────────────────
    int realConsumerCount = 0;
    int realDeliveryCount = 0;
    try {
      final profRes = await _client!.from('profiles').select('id, role');
      for (final p in (profRes as List)) {
        final role = p['role']?.toString().toLowerCase();
        if (role == 'consumer') realConsumerCount++;
        if (role == 'delivery') realDeliveryCount++;
      }
    } catch (_) {}

    // ─── 7. REAL BOUTIQUES REVENUE BREAKDOWN ─────────────────────────────────
    final liveSellersList = dbShops.map((b) {
      final shopOrders = parsedOrders.where((o) =>
          o.shopName.toLowerCase() == b.shopName.toLowerCase() ||
          o.id == b.id ||
          o.id == b.sellerId).toList();
      final totalShopOrders = shopOrders.length;
      final totalShopSales = shopOrders.fold<double>(0.0, (acc, curr) => acc + curr.total);
      final commGen = shopOrders.fold<double>(0.0, (acc, curr) => acc + curr.commissionAmount);
      final earnings = shopOrders.fold<double>(0.0, (acc, curr) => acc + curr.sellerPayout);

      return AdminSellerItem(
        id: b.id,
        shopName: b.shopName,
        ownerName: b.ownerName,
        email: b.ownerEmail,
        phone: b.ownerPhone,
        address: b.address,
        cityZone: b.cityZone,
        gstin: b.gstin,
        status: b.status == KycStatus.approved ? 'verified' : 'pending',
        kycStatus: b.status,
        totalProducts: 10,
        totalOrders: totalShopOrders,
        totalSales: totalShopSales,
        commissionGenerated: commGen,
        sellerEarnings: earnings,
        registeredAt: b.submittedAt,
      );
    }).toList();

    // ─── 8. REAL DYNAMIC CHART TRENDS (LAST 7 DAYS) ──────────────────────────
    final liveRevenueTrends = <AdminChartPoint>[];
    final liveOrdersTrends = <AdminChartPoint>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final dayLabel = '${d.day}/${d.month}';
      final dayOrders = parsedOrders.where((o) =>
          o.createdAt.year == d.year &&
          o.createdAt.month == d.month &&
          o.createdAt.day == d.day).toList();
      final dayOrderCount = dayOrders.length.toDouble();
      final dayRev = dayOrders.fold<double>(0.0, (acc, cur) => acc + cur.total);
      final dayComm = dayOrders.fold<double>(0.0, (acc, cur) => acc + cur.commissionAmount);

      liveOrdersTrends.add(AdminChartPoint(label: dayLabel, value: dayOrderCount));
      liveRevenueTrends.add(AdminChartPoint(label: dayLabel, value: dayRev, secondaryValue: dayComm));
    }

    final liveOrderStatusDist = [
      AdminChartPoint(label: 'Delivered', value: parsedOrders.where((o) => o.orderStatus == 'delivered').length.toDouble()),
      AdminChartPoint(label: 'Out for Delivery', value: parsedOrders.where((o) => o.orderStatus == 'out_for_delivery').length.toDouble()),
      AdminChartPoint(label: 'Confirmed / Packing', value: parsedOrders.where((o) => o.orderStatus == 'confirmed' || o.orderStatus == 'packed').length.toDouble()),
      AdminChartPoint(label: 'Placed / Pending', value: parsedOrders.where((o) => o.orderStatus == 'placed' || o.orderStatus == 'pending').length.toDouble()),
      AdminChartPoint(label: 'Cancelled / Returned', value: parsedOrders.where((o) => o.orderStatus == 'cancelled' || o.orderStatus == 'returned').length.toDouble()),
    ];

    final livePaymentDist = [
      AdminChartPoint(label: 'Razorpay UPI / Online', value: parsedOrders.where((o) => o.paymentMethod.toLowerCase() == 'razorpay').length.toDouble()),
      AdminChartPoint(label: 'Cash on Delivery (COD)', value: parsedOrders.where((o) => o.paymentMethod.toLowerCase() == 'cod').length.toDouble()),
    ];

    final computedShopSettlements = _computeShopSettlements(
      dbShops.isNotEmpty ? dbShops : _simulatedBoutiques,
      parsedOrders.isNotEmpty ? parsedOrders : _simulatedOrders,
      commissionRate,
    );
    final computedDeliverySalaries = _computeDeliverySalaries(
      _simulatedFleet,
      parsedOrders.isNotEmpty ? parsedOrders : _simulatedOrders,
    );

    return AdminMetricsModel(
      totalGmv: dbGmv,
      platformCommissionRate: commissionRate,
      platformRevenue: dbCommission,
      totalCommissionEarned: dbCommission,
      totalDeliveryCharges: dbDeliveryFees,
      gatewayCharges: dbGmv * 0.02,
      totalRefundsAmount: dbRefunds,
      totalAdRevenue: dbAdRev,
      totalOrdersCount: parsedOrders.length,
      totalCustomersCount: realConsumerCount > 0 ? realConsumerCount : parsedOrders.length,
      totalSellersCount: dbShops.length,
      activeBoutiquesCount: currentApproved.length,
      pendingKycCount: currentPending.length,
      suspendedSellersCount: dbShops.where((s) => s.status == KycStatus.rejected).length,
      onDutyDeliveryFleetCount: realDeliveryCount,
      totalDeliveryPartnersCount: realDeliveryCount,
      pendingOrdersCount: parsedOrders.where((o) => o.orderStatus == 'placed' || o.orderStatus == 'pending').length,
      openDisputesCount: parsedDisputes.where((d) => !d.isResolved).length,
      pendingBoutiques: currentPending,
      allBoutiques: dbShops,
      sellers: liveSellersList,
      customers: _simulatedCustomers,
      deliveryPartners: _simulatedFleet,
      orders: parsedOrders,
      inventoryItems: inventoryItems,
      zoneMetrics: zoneMetrics,
      disputes: parsedDisputes,
      auditLogs: parsedLogs,
      shopSettlements: computedShopSettlements,
      deliverySalaries: computedDeliverySalaries,
      revenueTrends: liveRevenueTrends,
      ordersTrends: liveOrdersTrends,
      categorySalesDistribution: categorySales,
      orderStatusDistribution: liveOrderStatusDist,
      paymentMethodDistribution: livePaymentDist,
    );
  }

  /// Approve, Reject, or Request Correction for Boutique KYC with Audit Trail
  Future<bool> updateBoutiqueKycStatus({
    required String boutiqueId,
    String? shopName,
    required KycStatus status,
    String? reason,
    String? verificationNotes,
    String adminName = 'Super Admin',
  }) async {
    await _loadPersistedStatus();

    if (status == KycStatus.approved) {
      _locallyApprovedShopIds.add(boutiqueId);
      if (shopName != null && shopName.isNotEmpty) {
        _locallyApprovedShopIds.add(shopName);
      }
      _locallyRejectedShopIds.remove(boutiqueId);
      if (shopName != null) _locallyRejectedShopIds.remove(shopName);
    } else if (status == KycStatus.rejected) {
      _locallyRejectedShopIds.add(boutiqueId);
      if (shopName != null && shopName.isNotEmpty) {
        _locallyRejectedShopIds.add(shopName);
      }
      _locallyApprovedShopIds.remove(boutiqueId);
      if (shopName != null) _locallyApprovedShopIds.remove(shopName);
    }

    final index = _simulatedBoutiques.indexWhere((b) => b.id == boutiqueId || b.shopName == boutiqueId || (shopName != null && b.shopName == shopName));
    if (index != -1) {
      final item = _simulatedBoutiques[index];
      if (status == KycStatus.approved) {
        _locallyApprovedShopIds.add(item.id);
        _locallyApprovedShopIds.add(item.shopName);
      } else if (status == KycStatus.rejected) {
        _locallyRejectedShopIds.add(item.id);
        _locallyRejectedShopIds.add(item.shopName);
      }
      _simulatedBoutiques[index] = item.copyWith(
        status: status,
        rejectionReason: reason,
        kycNotes: verificationNotes,
        verifiedAt: status == KycStatus.approved ? DateTime.now() : null,
      );
    }

    await _persistStatus();

    final isApproved = status == KycStatus.approved;
    final isRejected = status == KycStatus.rejected;
    final isCorrection = status == KycStatus.correctionRequested;
    // Valid PostgreSQL shop_status enum: 'pending', 'verified', 'rejected', 'suspended'
    final dbShopStatus = isApproved ? 'verified' : (isRejected ? 'rejected' : 'pending');
    // Valid PostgreSQL kyc_status enum: 'not_started', 'pending', 'verified', 'rejected'
    final dbKycStatus = isApproved ? 'verified' : (isRejected ? 'rejected' : 'pending');

    SellerRepository.updateMockShopStatus(
      status: dbShopStatus,
      kycStatus: dbKycStatus,
      reason: reason,
      notes: verificationNotes,
    );

    // Insert simulated audit log
    _simulatedAuditLogs.insert(
      0,
      AdminAuditLogItem(
        id: 'audit-${DateTime.now().millisecondsSinceEpoch}',
        adminName: adminName,
        action: status == KycStatus.approved
            ? 'KYC_APPROVED'
            : (status == KycStatus.rejected ? 'KYC_REJECTED' : 'KYC_CORRECTION_REQUESTED'),
        entity: 'shop_kyc',
        entityId: boutiqueId,
        details: 'Updated KYC status to "${status.label}". ${reason != null ? "Reason: $reason" : ""}',
        newValue: 'status: $dbShopStatus, kyc_status: $dbKycStatus',
        timestamp: DateTime.now(),
      ),
    );

    if (_client == null) return true;

    try {
      String? matchedSellerId;
      final updateMap = <String, dynamic>{
        'status': dbShopStatus,
        'is_verified': isApproved,
        'kyc_status': dbKycStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      try {
        final existing = await _client.from('shops').select('id, seller_id, name, description').eq('id', boutiqueId).maybeSingle();
        if (existing != null) {
          if (existing['seller_id'] != null) {
            matchedSellerId = existing['seller_id'].toString();
            if (isApproved) {
              _locallyApprovedShopIds.add(matchedSellerId);
            } else if (isRejected) {
              _locallyRejectedShopIds.add(matchedSellerId);
            }
            await _persistStatus();
          }

          String existingDesc = (existing['description'] as String?) ?? '';
          Map<String, dynamic> meta = {};
          if (existingDesc.contains('[KYC_META]:')) {
            final parts = existingDesc.split('[KYC_META]:');
            existingDesc = parts[0].trim();
            if (parts.length > 1) {
              try {
                meta = Map<String, dynamic>.from(jsonDecode(parts[1].trim()) as Map);
              } catch (_) {}
            }
          }
          if (reason != null && reason.isNotEmpty) meta['kyc_rejection_reason'] = reason;
          if (verificationNotes != null && verificationNotes.isNotEmpty) meta['kyc_notes'] = verificationNotes;
          if (isApproved) meta['kyc_verified_at'] = DateTime.now().toIso8601String();
          if (meta.isNotEmpty) {
            updateMap['description'] = existingDesc.isNotEmpty
                ? '$existingDesc\n[KYC_META]:${jsonEncode(meta)}'
                : '[KYC_META]:${jsonEncode(meta)}';
          }
        }
      } catch (_) {}

      try {
        await _client.from('shops').update(updateMap).eq('id', boutiqueId);
        if (matchedSellerId != null && matchedSellerId.isNotEmpty) {
          await _client.from('shops').update(updateMap).eq('seller_id', matchedSellerId);
        }
      } catch (e) {
        debugPrint('[AdminRepository] Error updating shop: $e');
      }

      // Record in Supabase audit logs table
      try {
        await _client.from('admin_audit_logs').insert({
          'admin_name': adminName,
          'action': status == KycStatus.approved ? 'KYC_APPROVED' : 'KYC_REJECTED',
          'entity': 'shop_kyc',
          'entity_id': boutiqueId,
          'details': 'Updated KYC verification status. Reason: $reason',
          'new_value': {'status': dbShopStatus, 'is_verified': isApproved, 'kyc_status': dbKycStatus},
        });
      } catch (_) {}

      return true;
    } catch (_) {
      return true;
    }
  }

  /// Approve or Reject Delivery Partner KYC Onboarding
  Future<bool> updateDeliveryPartnerKycStatus({
    required String driverId,
    required String verificationStatus, // 'verified', 'rejected', 'pending'
    String? reason,
    String? verificationNotes,
    String adminName = 'Super Admin',
  }) async {
    await _loadPersistedStatus();

    if (verificationStatus == 'verified') {
      _locallyApprovedDriverIds.add(driverId);
      _locallyRejectedDriverIds.remove(driverId);
    } else if (verificationStatus == 'rejected') {
      _locallyRejectedDriverIds.add(driverId);
      _locallyApprovedDriverIds.remove(driverId);
    }

    final index = _simulatedFleet.indexWhere((d) => d.id == driverId);
    if (index != -1) {
      _simulatedFleet[index] = _simulatedFleet[index].copyWith(
        verificationStatus: verificationStatus,
        rejectionReason: reason,
      );
    }

    await _persistStatus();

    _simulatedAuditLogs.insert(
      0,
      AdminAuditLogItem(
        id: 'audit-${DateTime.now().millisecondsSinceEpoch}',
        adminName: adminName,
        action: verificationStatus == 'verified' ? 'DELIVERY_PARTNER_APPROVED' : 'DELIVERY_PARTNER_REJECTED',
        entity: 'delivery_partner_kyc',
        entityId: driverId,
        details: 'Delivery partner status updated to "$verificationStatus". ${reason != null ? "Reason: $reason" : ""}',
        newValue: 'status: $verificationStatus',
        timestamp: DateTime.now(),
      ),
    );

    if (_client == null) return true;

    try {
      try {
        await _client.from('delivery_partner_profiles').update({
          'verification_status': verificationStatus,
          'kyc_rejection_reason': reason,
          'kyc_notes': verificationNotes,
          'verified_at': verificationStatus == 'verified' ? DateTime.now().toIso8601String() : null,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', driverId);
      } catch (_) {
        await _client.from('delivery_partner_profiles').update({
          'verification_status': verificationStatus,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', driverId);
      }

      try {
        await _client.from('admin_audit_logs').insert({
          'admin_name': adminName,
          'action': verificationStatus == 'verified' ? 'DELIVERY_PARTNER_APPROVED' : 'DELIVERY_PARTNER_REJECTED',
          'entity': 'delivery_partner_kyc',
          'entity_id': driverId,
          'details': 'Updated delivery partner verification. Reason: $reason',
          'new_value': {'status': verificationStatus},
        });
      } catch (_) {}

      return true;
    } catch (_) {
      return true;
    }
  }

  /// Log sensitive data access (e.g. unmasking PAN / Aadhaar / Bank details)
  Future<void> logSensitiveDataAccess({
    required String entityId,
    required String entityType,
    required String fieldAccessed,
    String adminName = 'Super Admin',
  }) async {
    _simulatedAuditLogs.insert(
      0,
      AdminAuditLogItem(
        id: 'audit-${DateTime.now().millisecondsSinceEpoch}',
        adminName: adminName,
        action: 'SENSITIVE_DATA_VIEWED',
        entity: entityType,
        entityId: entityId,
        details: 'Super Admin viewed unmasked sensitive information: $fieldAccessed',
        timestamp: DateTime.now(),
      ),
    );

    if (_client == null) return;
    try {
      await _client.from('admin_audit_logs').insert({
        'admin_name': adminName,
        'action': 'SENSITIVE_DATA_VIEWED',
        'entity': entityType,
        'entity_id': entityId,
        'details': 'Super Admin viewed unmasked: $fieldAccessed',
      });
    } catch (_) {}
  }

  /// Update Seller / Boutique Store status (Active / Suspended / Pending)
  Future<bool> updateSellerAccountStatus({
    required String shopId,
    required String newStatus, // 'verified', 'suspended', 'pending'
    String? reason,
    String adminName = 'Super Admin',
  }) async {
    _simulatedAuditLogs.insert(
      0,
      AdminAuditLogItem(
        id: 'audit-${DateTime.now().millisecondsSinceEpoch}',
        adminName: adminName,
        action: 'SELLER_STATUS_CHANGED',
        entity: 'shop',
        entityId: shopId,
        details: 'Changed seller status to $newStatus. ${reason ?? ""}',
        newValue: 'status: $newStatus',
        timestamp: DateTime.now(),
      ),
    );

    if (_client == null) return true;
    try {
      await _client.from('shops').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', shopId);
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Resolve dispute ticket or process refund
  Future<bool> resolveDisputeTicket({
    required String disputeId,
    bool isRefundApproved = false,
    String adminName = 'Super Admin',
  }) async {
    final index = _simulatedDisputes.indexWhere((d) => d.id == disputeId);
    if (index != -1) {
      _simulatedDisputes[index] = _simulatedDisputes[index].copyWith(
        isResolved: true,
        status: isRefundApproved ? 'refunded' : 'resolved',
      );
    }

    _simulatedAuditLogs.insert(
      0,
      AdminAuditLogItem(
        id: 'audit-${DateTime.now().millisecondsSinceEpoch}',
        adminName: adminName,
        action: isRefundApproved ? 'REFUND_PROCESSED' : 'DISPUTE_RESOLVED',
        entity: 'dispute',
        entityId: disputeId,
        details: 'Case marked resolved. Refund approved: $isRefundApproved',
        timestamp: DateTime.now(),
      ),
    );

    if (_client == null) return true;
    try {
      await _client.from('returns_refunds').update({
        'status': isRefundApproved ? 'refunded' : 'resolved',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', disputeId);
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Update Order Status (Admin Override)
  Future<bool> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String adminName = 'Super Admin',
  }) async {
    final index = _simulatedOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final old = _simulatedOrders[index];
      _simulatedOrders[index] = AdminOrderItem(
        id: old.id,
        consumerName: old.consumerName,
        consumerPhone: old.consumerPhone,
        shopName: old.shopName,
        productTitles: old.productTitles,
        itemCount: old.itemCount,
        subtotal: old.subtotal,
        deliveryFee: old.deliveryFee,
        commissionAmount: old.commissionAmount,
        sellerPayout: old.sellerPayout,
        total: old.total,
        paymentMethod: old.paymentMethod,
        paymentStatus: old.paymentStatus,
        orderStatus: newStatus,
        deliveryPartnerName: old.deliveryPartnerName,
        deliveryAddress: old.deliveryAddress,
        createdAt: old.createdAt,
      );
    }

    _simulatedAuditLogs.insert(
      0,
      AdminAuditLogItem(
        id: 'audit-${DateTime.now().millisecondsSinceEpoch}',
        adminName: adminName,
        action: 'ORDER_STATUS_OVERRIDE',
        entity: 'order',
        entityId: orderId,
        details: 'Admin updated order status to "$newStatus"',
        timestamp: DateTime.now(),
      ),
    );

    if (_client == null) return true;
    try {
      await _client.from('orders').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      return true;
    } catch (_) {
      return true;
    }
  }

  // ==========================================
  // FINANCIAL SETTLEMENTS & SALARY METHODS
  // ==========================================

  List<ShopSettlementSummary> _computeShopSettlements(
    List<BoutiqueVerificationItem> shops,
    List<AdminOrderItem> ordersList,
    double rate,
  ) {
    return shops.map((shop) {
      final shopOrders = ordersList.where((o) =>
        o.shopName.toLowerCase() == shop.shopName.toLowerCase() ||
        o.id == shop.id ||
        o.id == shop.sellerId).toList();

      final eligibleCount = shopOrders.isNotEmpty ? shopOrders.length : 1;
      final grossSubtotal = shopOrders.isNotEmpty
          ? shopOrders.fold<double>(0.0, (acc, o) => acc + o.subtotal)
          : 45000.0;
      final commAmount = double.parse((grossSubtotal * (rate / 100)).toStringAsFixed(2));
      final netPayback = double.parse((grossSubtotal - commAmount).toStringAsFixed(2));

      double paid = 0.0;
      for (final o in shopOrders) {
        if (o.sellerPayoutStatus == 'paid' || _locallyPaidOrderPayouts.containsKey(o.id)) {
          paid += o.sellerPayout;
        }
      }
      final pending = (netPayback - paid).clamp(0.0, double.infinity);
      final status = pending == 0 ? 'Settled' : (paid > 0 ? 'Partial' : 'Pending');

      return ShopSettlementSummary(
        shopId: shop.id,
        shopName: shop.shopName,
        ownerName: shop.ownerName,
        bankAccountNumber: shop.bankAccountNumber,
        bankIfsc: shop.bankIfsc,
        bankName: shop.bankName,
        eligibleOrdersCount: eligibleCount,
        grossSubtotal: grossSubtotal,
        commissionRate: rate,
        commissionAmount: commAmount,
        netPayback: netPayback,
        amountPaid: paid,
        pendingPayback: pending,
        settlementStatus: status,
      );
    }).toList();
  }

  List<DeliveryMonthlySalarySummary> _computeDeliverySalaries(
    List<AdminDeliveryPartnerItem> fleet,
    List<AdminOrderItem> ordersList,
  ) {
    const month = 'October 2026';
    return fleet.map((driver) {
      final driverOrders = ordersList.where((o) =>
        o.deliveryPartnerName != null &&
        o.deliveryPartnerName!.toLowerCase().contains(driver.name.toLowerCase().split(' ').first)).toList();

      final tripRecords = <DeliveryOrderTripRecord>[];
      if (driverOrders.isNotEmpty) {
        for (final o in driverOrders) {
          tripRecords.add(DeliveryOrderTripRecord(
            orderId: o.id,
            orderNumber: o.id,
            deliveryTime: o.createdAt,
            orderAmount: o.total,
            tripEarning: 70.0,
            deliveryZone: o.deliveryAddress,
            status: 'Delivered & Confirmed',
          ));
        }
      } else {
        tripRecords.addAll([
          DeliveryOrderTripRecord(
            orderId: 'PRD-2026-8812',
            orderNumber: 'PRD-2026-8812',
            deliveryTime: DateTime.now().subtract(const Duration(hours: 2)),
            orderAmount: 3549.0,
            tripEarning: 70.0,
            deliveryZone: 'B-24, Tilak Nagar, Jaipur',
          ),
          DeliveryOrderTripRecord(
            orderId: 'PRD-2026-6541',
            orderNumber: 'PRD-2026-6541',
            deliveryTime: DateTime.now().subtract(const Duration(days: 1)),
            orderAmount: 1939.0,
            tripEarning: 70.0,
            deliveryZone: '108, Malviya Nagar, Near WTP, Jaipur',
          ),
          DeliveryOrderTripRecord(
            orderId: 'PRD-2026-4419',
            orderNumber: 'PRD-2026-4419',
            deliveryTime: DateTime.now().subtract(const Duration(days: 2)),
            orderAmount: 2240.0,
            tripEarning: 70.0,
            deliveryZone: 'C-Scheme, Ashok Nagar, Jaipur',
          ),
        ]);
      }

      final ordersDelivered = driver.ordersDelivered > 0 ? driver.ordersDelivered : tripRecords.length;
      final perOrderTotal = ordersDelivered * 70.0;
      final incentive = 2500.0;
      final penalty = 0.0;
      final totalSalary = perOrderTotal + incentive - penalty;

      final salaryKey = '${driver.id}_$month';
      final isPaid = _locallyPaidDriverSalaries.containsKey(salaryKey);
      final paidMap = _locallyPaidDriverSalaries[salaryKey];
      final paidAmount = isPaid ? totalSalary : 0.0;
      final pendingAmount = isPaid ? 0.0 : totalSalary;
      final status = isPaid ? 'Paid' : 'Pending';

      return DeliveryMonthlySalarySummary(
        driverId: driver.id,
        driverName: driver.name,
        phone: driver.phone,
        vehicleType: driver.vehicleType,
        vehicleNumber: driver.vehicleNumber,
        upiId: driver.upiId ?? '${driver.name.toLowerCase().replaceAll(' ', '')}@upi',
        bankAccount: 'SBI 30981122334',
        monthName: month,
        completedOrdersCount: ordersDelivered,
        perOrderEarningsTotal: perOrderTotal,
        monthlyIncentiveBonus: incentive,
        penaltyDeductions: penalty,
        totalCalculatedSalary: totalSalary,
        amountPaid: paidAmount,
        pendingSalary: pendingAmount,
        salaryStatus: status,
        paymentReference: paidMap?['ref']?.toString(),
        paidAt: paidMap?['paidAt'] != null ? DateTime.tryParse(paidMap!['paidAt'].toString()) : null,
        tripRecords: tripRecords,
      );
    }).toList();
  }

  Future<bool> paySellerForOrder({
    required String orderId,
    required String shopName,
    required double amount,
    required String paymentMethod,
    required String transactionRef,
    String adminName = 'Super Admin',
  }) async {
    await _loadPersistedStatus();
    final now = DateTime.now();
    _locallyPaidOrderPayouts[orderId] = {
      'status': 'paid',
      'amount': amount,
      'ref': transactionRef,
      'method': paymentMethod,
      'paidAt': now.toIso8601String(),
      'shopName': shopName,
    };
    await _persistStatus();

    final idx = _simulatedOrders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _simulatedOrders[idx] = _simulatedOrders[idx].copyWith(
        sellerPayoutStatus: 'paid',
        sellerPayoutRef: transactionRef,
        sellerPaidAt: now,
        sellerPaymentMethod: paymentMethod,
      );
    }

    if (_client != null) {
      try {
        await _client.from('orders').update({
          'seller_payout_status': 'paid',
          'seller_payout_ref': transactionRef,
          'seller_paid_at': now.toIso8601String(),
          'seller_payment_method': paymentMethod,
        }).eq('id', orderId);
      } catch (_) {}

      try {
        await _client.from('settlement_transactions').insert({
          'recipient_type': 'seller',
          'order_id': orderId,
          'amount': amount,
          'currency': 'INR',
          'payment_method': paymentMethod,
          'external_reference': transactionRef,
          'status': 'paid',
          'metadata': {'shop_name': shopName, 'disbursed_by': adminName},
        });
      } catch (_) {}

      try {
        await _client.from('admin_audit_logs').insert({
          'admin_name': adminName,
          'action': 'SELLER_PAYOUT_DISBURSED',
          'entity': 'order_settlement',
          'entity_id': orderId,
          'details': 'Disbursed ₹${amount.toStringAsFixed(2)} revenue for order #$orderId to $shopName via $paymentMethod (Ref: $transactionRef)',
          'new_value': {
            'order_id': orderId,
            'shop_name': shopName,
            'amount': amount,
            'status': 'paid',
            'ref': transactionRef,
            'method': paymentMethod,
          },
        });
      } catch (_) {}
    }

    _simulatedAuditLogs.insert(
      0,
      AdminAuditLogItem(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}',
        adminName: adminName,
        action: 'SELLER_PAYOUT_DISBURSED',
        entity: 'order_settlement',
        entityId: orderId,
        details: 'Disbursed ₹${amount.toStringAsFixed(2)} revenue for order #$orderId to $shopName via $paymentMethod (Ref: $transactionRef)',
        timestamp: now,
      ),
    );

    return true;
  }

  Future<bool> disburseDeliverySalary({
    required String driverId,
    required String driverName,
    required String monthName,
    required double amount,
    required String paymentMethod,
    required String transactionRef,
    String adminName = 'Super Admin',
  }) async {
    await _loadPersistedStatus();
    final now = DateTime.now();
    final salaryKey = '${driverId}_$monthName';
    _locallyPaidDriverSalaries[salaryKey] = {
      'status': 'paid',
      'amount': amount,
      'ref': transactionRef,
      'method': paymentMethod,
      'paidAt': now.toIso8601String(),
      'driverName': driverName,
      'month': monthName,
    };
    await _persistStatus();

    if (_client != null) {
      try {
        await _client.from('admin_audit_logs').insert({
          'admin_name': adminName,
          'action': 'DELIVERY_SALARY_DISBURSED',
          'entity': 'delivery_salary',
          'entity_id': driverId,
          'details': 'Disbursed monthly salary ₹${amount.toStringAsFixed(2)} for $monthName to $driverName via $paymentMethod (Ref: $transactionRef)',
          'new_value': {
            'driver_id': driverId,
            'driver_name': driverName,
            'month': monthName,
            'amount': amount,
            'status': 'paid',
            'ref': transactionRef,
            'method': paymentMethod,
          },
        });
      } catch (_) {}
    }

    _simulatedAuditLogs.insert(
      0,
      AdminAuditLogItem(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}',
        adminName: adminName,
        action: 'DELIVERY_SALARY_DISBURSED',
        entity: 'delivery_salary',
        entityId: driverId,
        details: 'Disbursed monthly salary ₹${amount.toStringAsFixed(2)} for $monthName to $driverName via $paymentMethod (Ref: $transactionRef)',
        timestamp: now,
      ),
    );

    return true;
  }
}
