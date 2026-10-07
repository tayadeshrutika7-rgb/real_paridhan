import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/notifications/presentation/role_notification_badge.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';
import '../domain/admin_metrics_model.dart';
import 'admin_controller.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedOrderStatusFilter = 'All';
  String _selectedSellerStatusFilter = 'All';
  String _selectedKycCategory = 'Boutiques';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final metrics = adminState.metrics;
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PARIDHAN Admin Control Center',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Operator: ${user?.fullName ?? "Super Admin"} • City: Jaipur (HQ)',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Filter Period Badge / Dropdown
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 13, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    adminState.filterPeriod,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
            onSelected: (period) => ref.read(adminProvider.notifier).setFilterPeriod(period),
            itemBuilder: (ctx) => ['Today', '7 Days', '30 Days', 'This Month'].map((p) {
              return PopupMenuItem(value: p, child: Text(p));
            }).toList(),
          ),
          const RoleNotificationBadge(role: UserRole.admin),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Realtime Data',
            onPressed: () => ref.read(adminProvider.notifier).loadDashboard(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            const Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
            Tab(
              icon: const Icon(Icons.shopping_bag_outlined),
              text: 'Orders (${metrics.totalOrdersCount})',
            ),
            Tab(
              icon: const Icon(Icons.verified_user_outlined),
              text: 'KYC Reviews (${metrics.pendingKycCount})',
            ),
            Tab(
              icon: const Icon(Icons.storefront_outlined),
              text: 'Sellers (${metrics.totalSellersCount})',
            ),
            Tab(
              icon: const Icon(Icons.people_outline),
              text: 'Customers (${metrics.totalCustomersCount})',
            ),
            Tab(
              icon: const Icon(Icons.delivery_dining_outlined),
              text: 'Fleet Radar (${metrics.onDutyDeliveryFleetCount})',
            ),
            const Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Inventory'),
            const Tab(icon: Icon(Icons.account_balance_wallet_outlined), text: 'Commission & P&L'),
            Tab(
              icon: const Icon(Icons.history_edu_outlined),
              text: 'Audit Logs (${metrics.auditLogs.length})',
            ),
          ],
        ),
      ),
      body: adminState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. Master Overview & Business KPIs Tab
                _buildOverviewTab(context, metrics, adminState),

                // 2. Orders Pipeline Tab
                _buildOrdersTab(context, metrics),

                // 3. KYC Verification Tab
                _buildKycReviewsTab(context, metrics, adminState),

                // 4. Sellers Directory Tab
                _buildSellersTab(context, metrics),

                // 5. Customers CRM Tab
                _buildCustomersTab(context, metrics),

                // 6. Delivery Fleet Tab
                _buildFleetTab(context, metrics),

                // 7. Inventory & Products Tab
                _buildInventoryTab(context, metrics),

                // 8. Finance & P&L Tab
                _buildFinancialsTab(context, metrics),

                // 9. Admin Security Audit Logs Tab
                _buildAuditLogsTab(context, metrics),
              ],
            ),
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW & BUSINESS KPIS
  // ==========================================
  Widget _buildOverviewTab(BuildContext context, AdminMetricsModel metrics, AdminDashboardState state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(adminProvider.notifier).loadDashboard(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Revenue Banner
            _buildHeroGmvCard(metrics, state.filterPeriod),
            const SizedBox(height: 16),

            // 2. Pending KYC Action Banner
            if (metrics.pendingKycCount > 0) ...[
              InkWell(
                onTap: () => _tabController.animateTo(2),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppTheme.errorColor,
                        radius: 18,
                        child: Icon(Icons.verified_user_outlined, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${metrics.pendingKycCount} Boutiques Awaiting KYC Approval',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF991B1B)),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Verify PAN, GSTIN & bank accounts to activate stores for consumer discovery.',
                              style: TextStyle(color: Color(0xFF7F1D1D), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.errorColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 3. High-Density KPI Metric Grid (14 Metrics)
            Text('Business & Platform KPIs', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _buildKpiTile('Total Sales (GMV)', '₹${metrics.totalGmv.toStringAsFixed(0)}', Icons.currency_rupee, AppTheme.primaryColor),
                _buildKpiTile('Platform Revenue', '₹${metrics.platformRevenue.toStringAsFixed(0)}', Icons.account_balance_wallet, AppTheme.successColor),
                _buildKpiTile('Commission (10%)', '₹${metrics.totalCommissionEarned.toStringAsFixed(0)}', Icons.percent, Colors.teal),
                _buildKpiTile('Total Orders', '${metrics.totalOrdersCount}', Icons.shopping_bag_outlined, Colors.indigo),
                _buildKpiTile('Avg Order Value (AOV)', '₹${metrics.avgOrderValue.toStringAsFixed(0)}', Icons.analytics_outlined, Colors.blue),
                _buildKpiTile('Active Customers', '${metrics.totalCustomersCount}', Icons.people_outline, Colors.deepPurple),
                _buildKpiTile('Active Boutiques', '${metrics.activeBoutiquesCount}', Icons.storefront_outlined, AppTheme.accentColor),
                _buildKpiTile('On-Duty Fleet', '${metrics.onDutyDeliveryFleetCount} / ${metrics.totalDeliveryPartnersCount}', Icons.delivery_dining_outlined, Colors.green),
                _buildKpiTile('Pending Orders', '${metrics.pendingOrdersCount}', Icons.hourglass_top, Colors.amber.shade900),
                _buildKpiTile('Pending KYC', '${metrics.pendingKycCount}', Icons.badge_outlined, Colors.orange),
                _buildKpiTile('Refunds & Claims', '₹${metrics.totalRefundsAmount.toStringAsFixed(0)}', Icons.gavel_outlined, AppTheme.errorColor),
                _buildKpiTile('Ad Spend Revenue', '₹${metrics.totalAdRevenue.toStringAsFixed(0)}', Icons.campaign_outlined, const Color(0xFFE11D48)),
              ],
            ),

            const SizedBox(height: 24),

            // 4. Quick Action Navigation Row
            Text('Operations Quick Actions', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickActionButton('Review KYC', Icons.verified_user_outlined, AppTheme.primaryColor, () => _tabController.animateTo(2)),
                  const SizedBox(width: 8),
                  _buildQuickActionButton('View Orders', Icons.receipt_long, Colors.indigo, () => _tabController.animateTo(1)),
                  const SizedBox(width: 8),
                  _buildQuickActionButton('Manage Sellers', Icons.storefront, AppTheme.accentColor, () => _tabController.animateTo(3)),
                  const SizedBox(width: 8),
                  _buildQuickActionButton('Fleet Radar', Icons.delivery_dining, Colors.green, () => _tabController.animateTo(5)),
                  const SizedBox(width: 8),
                  _buildQuickActionButton('Advertisements', Icons.campaign, const Color(0xFFE11D48), () => context.push('/admin/advertisements')),
                  const SizedBox(width: 8),
                  _buildQuickActionButton('Disputes & Refunds', Icons.support_agent, Colors.purple, () => context.push('/admin/disputes')),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 5. Interactive Trend Visuals (Revenue & Category Sales)
            Text('Platform Trends & Distributions', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Revenue Trend (Weekly Cadence)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Icon(Icons.show_chart, color: AppTheme.primaryColor, size: 20),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInteractiveBarChart(metrics.revenueTrends, maxVal: 70000),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Top Fashion Categories Share', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    ...metrics.categorySalesDistribution.map((c) => _buildCategoryShareRow(c, metrics.totalGmv)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 6. Jaipur Hyperlocal Zone Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Jaipur Hyperlocal Zones', style: Theme.of(context).textTheme.headlineSmall),
                TextButton(
                  onPressed: () => context.push('/admin/analytics'),
                  child: const Text('Full City Map'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...metrics.zoneMetrics.map((zone) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.location_city, color: AppTheme.primaryColor, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(zone.zoneName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(
                                '${zone.activeBoutiques} Boutiques • ${zone.totalOrders} Orders',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${zone.gmvAmount.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '+₹${zone.platformRevenue.toStringAsFixed(0)} (10%)',
                              style: const TextStyle(fontSize: 11, color: AppTheme.successColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: ORDERS MANAGEMENT
  // ==========================================
  Widget _buildOrdersTab(BuildContext context, AdminMetricsModel metrics) {
    final statusFilters = ['All', 'placed', 'confirmed', 'packed', 'out_for_delivery', 'delivered', 'cancelled', 'returned'];

    final filtered = _selectedOrderStatusFilter == 'All'
        ? metrics.orders
        : metrics.orders.where((o) => o.orderStatus == _selectedOrderStatusFilter).toList();

    return Column(
      children: [
        // Status Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statusFilters.map((s) {
                final isSelected = _selectedOrderStatusFilter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(s.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.bold),
                    onSelected: (_) => setState(() => _selectedOrderStatusFilter = s),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No orders found matching status filter'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final order = filtered[i];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppTheme.borderSubtle)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                _buildStatusBadge(order.orderStatus),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('${order.consumerName} (${order.consumerPhone}) ➔ ${order.shopName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('Items: ${order.productTitles} (${order.itemCount} items)', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total: ₹${order.total.toStringAsFixed(2)} (${order.paymentMethod.toUpperCase()})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
                                Text('Comm: +₹${order.commissionAmount.toStringAsFixed(0)} | Payout: ₹${order.sellerPayout.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppTheme.successColor, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Driver: ${order.deliveryPartnerName ?? "Not Assigned"}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                TextButton(
                                  onPressed: () => _showOrderOverrideDialog(context, order),
                                  child: const Text('Update Status', style: TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: KYC REVIEWS (BOUTIQUES & DELIVERY PARTNERS)
  // ==========================================
  Widget _buildKycReviewsTab(BuildContext context, AdminMetricsModel metrics, AdminDashboardState state) {
    final pendingBoutiques = metrics.pendingBoutiques;
    final pendingDrivers = metrics.deliveryPartners.where((d) => d.verificationStatus == 'pending').toList();

    return Column(
      children: [
        // Category Selector Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              ChoiceChip(
                label: Text('Boutique Shops (${pendingBoutiques.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                selected: _selectedKycCategory == 'Boutiques',
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(color: _selectedKycCategory == 'Boutiques' ? Colors.white : AppTheme.textPrimary),
                onSelected: (val) {
                  if (val) setState(() => _selectedKycCategory = 'Boutiques');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Delivery Partners (${pendingDrivers.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                selected: _selectedKycCategory == 'Delivery Partners',
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(color: _selectedKycCategory == 'Delivery Partners' ? Colors.white : AppTheme.textPrimary),
                onSelected: (val) {
                  if (val) setState(() => _selectedKycCategory = 'Delivery Partners');
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: _selectedKycCategory == 'Boutiques'
              ? _buildBoutiqueKycList(context, pendingBoutiques, state)
              : _buildDeliveryPartnerKycList(context, metrics.deliveryPartners),
        ),
      ],
    );
  }

  Widget _buildBoutiqueKycList(BuildContext context, List<BoutiqueVerificationItem> pending, AdminDashboardState state) {
    if (pending.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppTheme.successColor),
            SizedBox(height: 12),
            Text('All boutique KYC verifications are cleared!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (ctx, i) {
        final item = pending[i];
        final isUnmasked = state.unmaskedKycShops.contains(item.id);

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.borderSubtle)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                      child: Text(item.status.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Owner: ${item.ownerName} • Phone: ${item.ownerPhone} • Email: ${item.ownerEmail}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Text('Location: ${item.address} (${item.cityZone})', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Text('GSTIN: ${item.gstin}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                const SizedBox(height: 10),

                // Masked Sensitive Details Block
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.security, size: 14, color: AppTheme.primaryColor),
                              SizedBox(width: 4),
                              Text('Protected Identification Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                          TextButton(
                            onPressed: () => ref.read(adminProvider.notifier).toggleUnmaskKyc(item.id),
                            child: Text(isUnmasked ? 'Mask' : 'Reveal (Audit Logged)', style: const TextStyle(fontSize: 10)),
                          ),
                        ],
                      ),
                      Text('PAN: ${isUnmasked ? item.panNumber : item.maskedPan} | Aadhaar: ${isUnmasked ? item.aadhaarNumber : item.maskedAadhaar}', style: const TextStyle(fontSize: 11)),
                      Text('Bank: ${item.bankName} • A/C: ${isUnmasked ? item.bankAccountNumber : item.maskedBankAccount} • IFSC: ${item.bankIfsc}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showKycRejectDialog(context, item),
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor, side: const BorderSide(color: AppTheme.errorColor)),
                        child: const Text('Reject', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showKycCorrectionDialog(context, item),
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.accentColor, side: const BorderSide(color: AppTheme.accentColor)),
                        child: const Text('Correction', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => ref.read(adminProvider.notifier).approveBoutique(item.id),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                        child: const Text('Approve & Activate', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeliveryPartnerKycList(BuildContext context, List<AdminDeliveryPartnerItem> drivers) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: drivers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (ctx, i) {
        final driver = drivers[i];
        final isVerified = driver.verificationStatus == 'verified';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.borderSubtle)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        driver.verificationStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isVerified ? AppTheme.successColor : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Phone: ${driver.phone} • Vehicle: ${driver.vehicleType} (${driver.vehicleNumber})', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Text('Driving License: ${driver.drivingLicenseNumber ?? "RJ14 20210049281"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PAN: ${driver.panNumber ?? "ABCDE9876K"} | Aadhaar: ${driver.aadhaarNumber ?? "987654321012"}', style: const TextStyle(fontSize: 11)),
                      Text('Payout UPI ID: ${driver.upiId ?? "driver@upi"}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                if (!isVerified)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showDeliveryKycRejectDialog(context, driver),
                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor, side: const BorderSide(color: AppTheme.errorColor)),
                          child: const Text('Reject', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => ref.read(adminProvider.notifier).approveDeliveryPartner(driver.id),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                          child: const Text('Approve Delivery Partner', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: AppTheme.successColor),
                          SizedBox(width: 6),
                          Text('Driver Verified & Ready for Assignments', style: TextStyle(fontSize: 12, color: AppTheme.successColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _showDeliveryKycRejectDialog(context, driver),
                        child: const Text('Suspend / Revoke', style: TextStyle(fontSize: 11, color: AppTheme.errorColor)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 4: SELLERS DIRECTORY
  // ==========================================
  Widget _buildSellersTab(BuildContext context, AdminMetricsModel metrics) {
    final filters = ['All', 'verified', 'pending', 'suspended'];
    final filteredSellers = _selectedSellerStatusFilter == 'All'
        ? metrics.sellers
        : metrics.sellers.where((s) => s.status == _selectedSellerStatusFilter).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) {
                final isSelected = _selectedSellerStatusFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(f.toUpperCase(), style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.bold),
                    onSelected: (_) => setState(() => _selectedSellerStatusFilter = f),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filteredSellers.isEmpty
              ? const Center(child: Text('No sellers found for this filter'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredSellers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final seller = filteredSellers[i];
                    final isSuspended = seller.status == 'suspended';

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(seller.shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSuspended ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(seller.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSuspended ? AppTheme.errorColor : AppTheme.successColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Owner: ${seller.ownerName} • ${seller.phone} • ${seller.email}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                Text('Location: ${seller.address} (${seller.cityZone})', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatPill('Catalog Products', '${seller.totalProducts}'),
                    _buildStatPill('Total Orders', '${seller.totalOrders}'),
                    _buildStatPill('Gross Sales', '₹${seller.totalSales.toStringAsFixed(0)}'),
                    _buildStatPill('10% Comm', '₹${seller.commissionGenerated.toStringAsFixed(0)}'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        final newStatus = isSuspended ? 'verified' : 'suspended';
                        ref.read(adminProvider.notifier).updateSellerStatus(seller.id, newStatus);
                      },
                      icon: Icon(isSuspended ? Icons.check_circle : Icons.block, size: 14, color: isSuspended ? AppTheme.successColor : AppTheme.errorColor),
                      label: Text(isSuspended ? 'Reactivate Store' : 'Suspend Store', style: TextStyle(fontSize: 11, color: isSuspended ? AppTheme.successColor : AppTheme.errorColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  ),
],
);
}

  // ==========================================
  // TAB 5: CUSTOMERS CRM
  // ==========================================
  Widget _buildCustomersTab(BuildContext context, AdminMetricsModel metrics) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: metrics.customers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final cust = metrics.customers[i];
        final df = DateFormat('dd MMM yyyy');

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.2),
                  child: Text(cust.name.isNotEmpty ? cust.name[0] : 'C', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cust.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${cust.email} • ${cust.phone}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text('Registered: ${df.format(cust.registeredAt)}', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${cust.totalSpending.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor)),
                    Text('${cust.totalOrders} Orders', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 6: DELIVERY FLEET RADAR
  // ==========================================
  Widget _buildFleetTab(BuildContext context, AdminMetricsModel metrics) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: metrics.deliveryPartners.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final driver = metrics.deliveryPartners[i];

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: driver.isOnDuty ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                  child: Icon(Icons.delivery_dining, color: driver.isOnDuty ? AppTheme.successColor : AppTheme.textMuted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: driver.isOnDuty ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(driver.isOnDuty ? 'ON DUTY' : 'OFFLINE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: driver.isOnDuty ? AppTheme.successColor : AppTheme.textMuted)),
                          ),
                        ],
                      ),
                      Text('${driver.vehicleType} • ${driver.vehicleNumber} • ${driver.phone}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      Text('Delivered: ${driver.ordersDelivered} orders • Success Rate: ${driver.successRate}%', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        Text(' ${driver.rating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Text('₹${driver.totalEarnings.toStringAsFixed(0)} Earned', style: const TextStyle(fontSize: 11, color: AppTheme.successColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 7: INVENTORY & PRODUCTS
  // ==========================================
  Widget _buildInventoryTab(BuildContext context, AdminMetricsModel metrics) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: metrics.inventoryItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final item = metrics.inventoryItems[i];

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.checkroom, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Boutique: ${item.shopName} • Category: ${item.categoryName}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Base: ₹${item.basePrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                          const SizedBox(width: 12),
                          Text('Sold: ${item.soldCount}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.isOutOfStock
                        ? const Color(0xFFFEE2E2)
                        : (item.isLowStock ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.isOutOfStock ? 'OUT OF STOCK' : (item.isLowStock ? 'LOW: ${item.totalStock}' : '${item.totalStock} IN STOCK'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: item.isOutOfStock
                          ? AppTheme.errorColor
                          : (item.isLowStock ? const Color(0xFF92400E) : AppTheme.successColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 8: FINANCIALS & P&L
  // ==========================================
  Widget _buildFinancialsTab(BuildContext context, AdminMetricsModel metrics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Platform Net Revenue Summary', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text('₹${metrics.netPlatformEarnings.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildWhiteStat('Platform Comm', '₹${metrics.totalCommissionEarned.toStringAsFixed(0)}'),
                    _buildWhiteStat('Ad Revenue', '₹${metrics.totalAdRevenue.toStringAsFixed(0)}'),
                    _buildWhiteStat('Seller Payouts', '₹${metrics.sellerEarnings.toStringAsFixed(0)}'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text('Itemized Platform Earnings Ledger', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFinancialRow('Gross Merchandise Value (GMV)', '₹${metrics.totalGmv.toStringAsFixed(2)}', isBold: true),
                  _buildFinancialRow('10% Platform Commission', '+₹${metrics.totalCommissionEarned.toStringAsFixed(2)}', color: AppTheme.successColor),
                  _buildFinancialRow('Advertisements & Promos', '+₹${metrics.totalAdRevenue.toStringAsFixed(2)}', color: AppTheme.successColor),
                  _buildFinancialRow('Delivery Platform Fees', '+₹${metrics.totalDeliveryCharges.toStringAsFixed(2)}', color: AppTheme.successColor),
                  _buildFinancialRow('Payment Gateway Costs (2%)', '-₹${metrics.gatewayCharges.toStringAsFixed(2)}', color: AppTheme.errorColor),
                  _buildFinancialRow('Refunds & Claims Disbursed', '-₹${metrics.totalRefundsAmount.toStringAsFixed(2)}', color: AppTheme.errorColor),
                  const Divider(height: 20),
                  _buildFinancialRow('Net Platform Revenue / Earnings', '₹${metrics.netPlatformEarnings.toStringAsFixed(2)}', isBold: true, color: AppTheme.primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 9: AUDIT LOGS
  // ==========================================
  Widget _buildAuditLogsTab(BuildContext context, AdminMetricsModel metrics) {
    final df = DateFormat('dd MMM yyyy, hh:mm a');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: metrics.auditLogs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final log = metrics.auditLogs[i];

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.security, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryColor)),
                          Text(df.format(log.timestamp), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(log.details, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 2),
                      Text('By: ${log.adminName} • Entity: ${log.entity} (#${log.entityId}) • IP: ${log.ipAddress}', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // HELPER WIDGETS & MODALS
  // ==========================================
  Widget _buildHeroGmvCard(AdminMetricsModel metrics, String period) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gross Merchandise Value (GMV)', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                child: Text(period, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('₹${metrics.totalGmv.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniWhiteStat('10% Comm Revenue', '₹${metrics.platformRevenue.toStringAsFixed(0)}'),
              _buildMiniWhiteStat('Total Orders', '${metrics.totalOrdersCount}'),
              _buildMiniWhiteStat('Active Boutiques', '${metrics.activeBoutiquesCount}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveBarChart(List<AdminChartPoint> points, {required double maxVal}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: points.map((p) {
        final heightFactor = maxVal > 0 ? (p.value / maxVal).clamp(0.1, 1.0) : 0.2;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('₹${(p.value / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: 100 * heightFactor,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryLight], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            Text(p.label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCategoryShareRow(AdminChartPoint point, double totalGmv) {
    final pct = totalGmv > 0 ? (point.value / totalGmv) : 0.2;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(point.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('₹${point.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildMiniWhiteStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildWhiteStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildFinancialRow(String label, String val, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'delivered':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        break;
      case 'out_for_delivery':
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF3730A3);
        break;
      case 'cancelled':
      case 'returned':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  void _showOrderOverrideDialog(BuildContext context, AdminOrderItem order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Override Order #${order.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['confirmed', 'packed', 'out_for_delivery', 'delivered', 'cancelled', 'returned'].map((st) {
            return ListTile(
              title: Text(st.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 13)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(adminProvider.notifier).updateOrderStatus(order.id, st);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showKycRejectDialog(BuildContext context, BoutiqueVerificationItem item) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject KYC: ${item.shopName}'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Rejection Reason *', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                await ref.read(adminProvider.notifier).rejectBoutique(item.id, reason: controller.text.trim());
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showKycCorrectionDialog(BuildContext context, BoutiqueVerificationItem item) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Request Correction: ${item.shopName}'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Correction Notes *', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                await ref.read(adminProvider.notifier).requestKycCorrection(item.id, notes: controller.text.trim());
              }
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _showDeliveryKycRejectDialog(BuildContext context, AdminDeliveryPartnerItem driver) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject / Suspend: ${driver.name}'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection/suspension *',
            hintText: 'e.g. Invalid Driving License or expired RC document',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                await ref.read(adminProvider.notifier).rejectDeliveryPartner(driver.id, reason: controller.text.trim());
              }
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }
}
