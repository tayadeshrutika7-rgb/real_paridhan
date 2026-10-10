import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/constants/app_constants.dart';
import '../../../core/notifications/presentation/role_notification_controller.dart';
import '../../../core/notifications/presentation/role_notifications_sheet.dart';
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
  int _selectedTabIndex = 0;
  bool _isSidebarCollapsed = false;
  bool _isHoveringSidebar = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedOrderStatusFilter = 'All';
  String _selectedSellerStatusFilter = 'All';
  String _selectedKycCategory = 'Boutiques';
  int _financeSubSection = 0; // 0: All, 1: Shop Paybacks, 2: Order Payouts, 3: Delivery Salaries
  String _financeOrderFilter = 'All'; // 'All', 'Pending', 'Paid'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != _selectedTabIndex) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    setState(() {
      _selectedTabIndex = index;
      _tabController.animateTo(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final metrics = adminState.metrics;
    final user = ref.watch(authProvider).user;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isSidebarExpanded = !_isSidebarCollapsed || _isHoveringSidebar;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar(context, metrics, user, isDrawer: true, isExpanded: true)),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Fixed Left Sidebar on Desktop (Hover & Click expand supported)
          if (isDesktop)
            MouseRegion(
              onEnter: (_) {
                if (_isSidebarCollapsed) {
                  setState(() => _isHoveringSidebar = true);
                }
              },
              onExit: (_) {
                if (_isHoveringSidebar) {
                  setState(() => _isHoveringSidebar = false);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: isSidebarExpanded ? 260 : 72,
                child: _buildSidebar(context, metrics, user, isExpanded: isSidebarExpanded),
              ),
            ),

          // 2. Main Content View Area
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                _buildTopHeader(context, adminState, user, !isDesktop),

                // Main Scrollable Body
                Expanded(
                  child: adminState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            // 1. Overview & Business Analytics (Matching Mockup)
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TOP NAVIGATION HEADER (SEARCH & QUICK CONTROLS)
  // ==========================================
  Widget _buildTopHeader(BuildContext context, AdminDashboardState adminState, dynamic user, bool showMenuButton) {
    final notifState = ref.watch(roleNotificationProvider(UserRole.admin));
    final unreadCount = notifState.unreadCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),

          // Search Bar with Ctrl+K chip
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                      decoration: const InputDecoration(
                        hintText: 'Search orders, sellers, customers...',
                        hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'Ctrl K',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Date Filter Dropdown
          PopupMenuButton<String>(
            tooltip: 'Filter Period',
            onSelected: (p) => ref.read(adminProvider.notifier).setFilterPeriod(p),
            itemBuilder: (ctx) => ['Today', '7 Days', '30 Days', 'This Month'].map((p) {
              return PopupMenuItem(value: p, child: Text(p));
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(
                    adminState.filterPeriod,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Working Interactive Notification Bell Button
          Tooltip(
            message: 'Admin Notifications ($unreadCount)',
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_outlined, size: 20, color: Color(0xFF475569)),
                    onPressed: () => RoleNotificationsSheet.show(context, UserRole.admin),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE11D48),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Profile Avatar Circle & Sign Out menu
          PopupMenuButton<String>(
            tooltip: 'Admin Account',
            onSelected: (val) {
              if (val == 'signout') {
                ref.read(authProvider.notifier).signOut();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? 'Admin', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(user?.email ?? 'admin@paridhan.com', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 16, color: Color(0xFFE11D48)),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                user?.fullName != null && user!.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'A',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LEFT ROYAL CRIMSON SIDEBAR
  // ==========================================
  Widget _buildSidebar(
    BuildContext context,
    AdminMetricsModel metrics,
    dynamic user, {
    bool isDrawer = false,
    bool isExpanded = true,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF670E22), // Deep Royal Crimson
      ),
      child: Column(
        children: [
          // Sidebar Header Brand & Toggle Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Row(
              mainAxisAlignment: isExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => setState(() {
                    _isSidebarCollapsed = !_isSidebarCollapsed;
                    _isHoveringSidebar = false;
                  }),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_florist, color: Colors.white, size: 20),
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PARIDHAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Admin Control Center',
                          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  if (!isDrawer)
                    InkWell(
                      onTap: () => setState(() {
                        _isSidebarCollapsed = !_isSidebarCollapsed;
                        _isHoveringSidebar = false;
                      }),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _isSidebarCollapsed ? Icons.chevron_right : Icons.chevron_left,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 10),

          // Sidebar Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildSidebarNavItem(0, 'Overview', Icons.grid_view_rounded, isExpanded: isExpanded),
                _buildSidebarNavItem(1, 'Orders', Icons.shopping_bag_outlined, isExpanded: isExpanded),
                _buildSidebarNavItem(
                  2,
                  'KYC Reviews',
                  Icons.verified_user_outlined,
                  badge: metrics.pendingKycCount > 0 ? '${metrics.pendingKycCount}' : null,
                  isExpanded: isExpanded,
                ),
                _buildSidebarNavItem(3, 'Sellers', Icons.storefront_outlined, isExpanded: isExpanded),
                _buildSidebarNavItem(4, 'Customers', Icons.people_outline, isExpanded: isExpanded),
                _buildSidebarNavItem(5, 'Fleet Radar', Icons.two_wheeler_outlined, isExpanded: isExpanded),
                _buildSidebarNavItem(6, 'Inventory', Icons.inventory_2_outlined, isExpanded: isExpanded),
                _buildSidebarNavItem(7, 'Commission & P&L', Icons.calendar_month_outlined, isExpanded: isExpanded),
                _buildSidebarNavItem(8, 'Audit Logs', Icons.description_outlined, isExpanded: isExpanded),

                const SizedBox(height: 16),

                // Promotional / Empowerment Banner
                if (isExpanded)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF991B1B).withValues(alpha: 0.85),
                          const Color(0xFF4C0519).withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Empowering\nLocal Fashion\nBusinesses',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: () => context.push('/admin/analytics'),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward, color: Color(0xFF670E22), size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Admin Profile Card (No overflow when collapsed)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 12 : 6,
              vertical: 10,
            ),
            margin: EdgeInsets.all(isExpanded ? 12 : 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: isExpanded
                ? Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.white24,
                            child: Text(
                              user?.fullName != null && user!.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'A',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF670E22), width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Admin',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Jaipur HQ',
                              style: TextStyle(color: Colors.white60, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white54, size: 16),
                    ],
                  )
                : Center(
                    child: Tooltip(
                      message: '${user?.fullName ?? "Admin"} (Jaipur HQ)',
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white24,
                        child: Text(
                          user?.fullName != null && user!.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'A',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(
    int index,
    String title,
    IconData icon, {
    String? badge,
    bool isExpanded = true,
  }) {
    final isSelected = _selectedTabIndex == index;

    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 12 : 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: isExpanded
          ? Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            )
          : Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.white70,
                    size: 20,
                  ),
                  if (badge != null && badge != '0')
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE11D48),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Tooltip(
        message: !isExpanded ? (badge != null ? '$title ($badge)' : title) : '',
        child: InkWell(
          onTap: () {
            _switchTab(index);
            if (Scaffold.of(context).isDrawerOpen) {
              Navigator.pop(context);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: content,
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW & BUSINESS KPIS (MATCHING MOCKUP)
  // ==========================================
  Widget _buildOverviewTab(BuildContext context, AdminMetricsModel metrics, AdminDashboardState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 960;

    return RefreshIndicator(
      onRefresh: () => ref.read(adminProvider.notifier).loadDashboard(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome Header with Jaipur Skyline Silhouette
            _buildWelcomeBanner(context),
            const SizedBox(height: 24),

            // 2. Top 4 Main Metric Cards (with Sparklines)
            LayoutBuilder(
              builder: (ctx, constraints) {
                final count = constraints.maxWidth > 1100 ? 4 : (constraints.maxWidth > 650 ? 2 : 1);
                final width = (constraints.maxWidth - ((count - 1) * 16)) / count;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: width,
                      child: _buildSparklineCard(
                        title: 'Total Sales (GMV)',
                        value: '₹${metrics.totalGmv.toStringAsFixed(0)}',
                        trend: '↑ 12%',
                        icon: Icons.currency_rupee,
                        iconColor: const Color(0xFFE11D48),
                        iconBg: const Color(0xFFFFECEE),
                        lineColor: const Color(0xFFE11D48),
                        sparkPoints: const [10, 12, 11, 14, 16, 15, 19],
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildSparklineCard(
                        title: 'Platform Revenue',
                        value: '₹${metrics.platformRevenue.toStringAsFixed(0)}',
                        trend: '↑ 8%',
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: const Color(0xFF059669),
                        iconBg: const Color(0xFFE6F8F0),
                        lineColor: const Color(0xFF059669),
                        sparkPoints: const [12, 14, 13, 17, 16, 20, 22],
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildSparklineCard(
                        title: 'Commission (3%)',
                        value: '₹${metrics.totalCommissionEarned.toStringAsFixed(0)}',
                        trend: '↑ 8%',
                        icon: Icons.percent,
                        iconColor: const Color(0xFF7C3AED),
                        iconBg: const Color(0xFFF1EEFF),
                        lineColor: const Color(0xFF7C3AED),
                        sparkPoints: const [8, 10, 9, 13, 15, 18, 21],
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildSparklineCard(
                        title: 'Total Orders',
                        value: '${metrics.totalOrdersCount}',
                        trend: '↑ 6%',
                        icon: Icons.shopping_bag_outlined,
                        iconColor: const Color(0xFF2563EB),
                        iconBg: const Color(0xFFEDF5FF),
                        lineColor: const Color(0xFF2563EB),
                        sparkPoints: const [5, 8, 7, 10, 12, 15, 19],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // 3. Secondary 4 Metric Pills
            LayoutBuilder(
              builder: (ctx, constraints) {
                final count = constraints.maxWidth > 1100 ? 4 : (constraints.maxWidth > 650 ? 2 : 1);
                final width = (constraints.maxWidth - ((count - 1) * 16)) / count;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: width,
                      child: _buildCompactKpiPill(
                        label: 'Avg Order Value (AOV)',
                        value: '₹${metrics.avgOrderValue.toStringAsFixed(0)}',
                        trend: '↑ 5%',
                        icon: Icons.bar_chart,
                        iconColor: const Color(0xFF2563EB),
                        iconBg: const Color(0xFFEFF6FF),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildCompactKpiPill(
                        label: 'Active Customers',
                        value: '${metrics.totalCustomersCount}',
                        trend: '↑ 11%',
                        icon: Icons.people_outline,
                        iconColor: const Color(0xFF7C3AED),
                        iconBg: const Color(0xFFF5F3FF),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildCompactKpiPill(
                        label: 'Active Boutiques',
                        value: '${metrics.activeBoutiquesCount}',
                        trend: '↑ 0%',
                        icon: Icons.storefront_outlined,
                        iconColor: const Color(0xFFD97706),
                        iconBg: const Color(0xFFFFFBEB),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildCompactKpiPill(
                        label: 'On-Duty Fleet',
                        value: '${metrics.onDutyDeliveryFleetCount} / ${metrics.totalDeliveryPartnersCount}',
                        trend: '↑ 16%',
                        icon: Icons.two_wheeler_outlined,
                        iconColor: const Color(0xFF059669),
                        iconBg: const Color(0xFFECFDF5),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // 4. Middle Section: Trend Chart & Operational Summary
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: _buildOrdersAndRevenueTrendCard(metrics)),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: _buildOperationalSummaryCard(metrics)),
                ],
              )
            else ...[
              _buildOrdersAndRevenueTrendCard(metrics),
              const SizedBox(height: 18),
              _buildOperationalSummaryCard(metrics),
            ],

            const SizedBox(height: 24),

            // 5. Bottom Section: Recent Orders & Top Performing Boutiques
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _buildRecentOrdersCard(context, metrics)),
                  const SizedBox(width: 20),
                  Expanded(flex: 5, child: _buildTopBoutiquesCard(context, metrics)),
                ],
              )
            else ...[
              _buildRecentOrdersCard(context, metrics),
              const SizedBox(height: 18),
              _buildTopBoutiquesCard(context, metrics),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WELCOME BANNER WITH HERITAGE SILHOUETTE
  // ==========================================
  Widget _buildWelcomeBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Welcome Back, Admin',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('👋', style: TextStyle(fontSize: 20)),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  "Here's what's happening with your Paridhan platform today.",
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Heritage City Skyline Silhouette Illustration
          CustomPaint(
            size: const Size(180, 50),
            painter: _JaipurSkylinePainter(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TOP METRIC CARD WITH SPARKLINE AREA CHART
  // ==========================================
  Widget _buildSparklineCard({
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color lineColor,
    required List<double> sparkPoints,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Icon(Icons.more_vert, size: 18, color: Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trend,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                ),
              ),
              SizedBox(
                width: 90,
                height: 32,
                child: CustomPaint(
                  painter: _SparklinePainter(points: sparkPoints, color: lineColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECONDARY COMPACT METRIC PILL
  // ==========================================
  Widget _buildCompactKpiPill({
    required String label,
    required String value,
    required String trend,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              trend,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ORDERS & REVENUE TREND (COMBO BAR + SPLINE CHART)
  // ==========================================
  Widget _buildOrdersAndRevenueTrendCard(AdminMetricsModel metrics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bar_chart, color: Color(0xFFE11D48), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Orders & Revenue Trend',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Text('This Month', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Legend Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFCA5A5), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('Orders', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF881337), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('Revenue (₹)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Interactive Custom Combo Chart
          SizedBox(
            height: 220,
            width: double.infinity,
            child: CustomPaint(
              painter: _ComboTrendChartPainter(
                ordersTrends: metrics.ordersTrends,
                revenueTrends: metrics.revenueTrends,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // OPERATIONAL SUMMARY CARD
  // ==========================================
  Widget _buildOperationalSummaryCard(AdminMetricsModel metrics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_outlined, color: Color(0xFFE11D48), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Operational Summary',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOpSummaryRow('Total Orders', '${metrics.totalOrdersCount}', '↑ 6%', Icons.shopping_bag_outlined, const Color(0xFF2563EB), const Color(0xFFEFF6FF), () => _switchTab(1)),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildOpSummaryRow('Active Customers', '${metrics.totalCustomersCount}', '↑ 11%', Icons.people_outline, const Color(0xFF7C3AED), const Color(0xFFF5F3FF), () => _switchTab(4)),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildOpSummaryRow('Active Boutiques', '${metrics.activeBoutiquesCount}', '↑ 0%', Icons.storefront_outlined, const Color(0xFFD97706), const Color(0xFFFFFBEB), () => _switchTab(3)),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildOpSummaryRow('On-Duty Fleet', '${metrics.onDutyDeliveryFleetCount} / ${metrics.totalDeliveryPartnersCount}', '↑ 16%', Icons.two_wheeler_outlined, const Color(0xFF059669), const Color(0xFFECFDF5), () => _switchTab(5)),
        ],
      ),
    );
  }

  Widget _buildOpSummaryRow(String title, String value, String trend, IconData icon, Color color, Color bg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(4)),
              child: Text(
                trend,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // RECENT ORDERS TABLE CARD
  // ==========================================
  Widget _buildRecentOrdersCard(BuildContext context, AdminMetricsModel metrics) {
    final recentOrders = metrics.orders.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, color: Color(0xFFE11D48), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Recent Orders',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _switchTab(1),
                child: const Row(
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE11D48))),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 14, color: Color(0xFFE11D48)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 3, child: Text('Customer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 3, child: Text('Boutique', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Orders List
          if (recentOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No recent orders found', style: TextStyle(color: Color(0xFF94A3B8)))),
            )
          else
            ...recentOrders.asMap().entries.map((entry) {
              final idx = entry.key;
              final o = entry.value;
              final shortId = o.id.length > 8 ? '#PDN${o.id.substring(0, 5)}' : '#PDN${10239 - idx}';

              Color statusBg;
              Color statusFg;
              String statusLabel = o.orderStatus.replaceAll('_', ' ');

              if (o.orderStatus == 'delivered') {
                statusBg = const Color(0xFFDCFCE7);
                statusFg = const Color(0xFF166534);
                statusLabel = 'Delivered';
              } else if (o.orderStatus == 'out_for_delivery' || o.orderStatus == 'shipped') {
                statusBg = const Color(0xFFE0E7FF);
                statusFg = const Color(0xFF3730A3);
                statusLabel = 'Shipped';
              } else {
                statusBg = const Color(0xFFFEF3C7);
                statusFg = const Color(0xFF92400E);
                statusLabel = 'Processing';
              }

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(shortId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                    Expanded(flex: 3, child: Text(o.consumerName.isNotEmpty ? o.consumerName : 'Aditi Sharma', style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w600))),
                    Expanded(flex: 3, child: Text(o.shopName.isNotEmpty ? o.shopName : 'Johari Heritage', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                    Expanded(flex: 2, child: Text('₹${o.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          statusLabel,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusFg),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${o.createdAt.day.toString().padLeft(2, '0')}/${o.createdAt.month.toString().padLeft(2, '0')}/${o.createdAt.year}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ==========================================
  // TOP PERFORMING BOUTIQUES TABLE CARD
  // ==========================================
  Widget _buildTopBoutiquesCard(BuildContext context, AdminMetricsModel metrics) {
    final topSellers = metrics.sellers.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Top Performing Boutiques',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _switchTab(3),
                child: const Row(
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE11D48))),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 14, color: Color(0xFFE11D48)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 4, child: Text('Boutique', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('Orders', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 3, child: Text('Revenue (₹)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 3, child: Text('Share', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Boutiques List
          ...topSellers.asMap().entries.map((entry) {
            final idx = entry.key;
            final seller = entry.value;
            final pct = metrics.totalGmv > 0
                ? (seller.totalSales / metrics.totalGmv).clamp(0.0, 1.0)
                : 0.0;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Text('${idx + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                  Expanded(flex: 4, child: Text(seller.shopName, style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A), fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 2, child: Text('${seller.totalOrders}', style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w600))),
                  Expanded(flex: 3, child: Text('₹${seller.totalSales.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 6,
                        color: const Color(0xFFF1F5F9),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: pct,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFE11D48),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
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
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.shopName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          if (item.businessType != null && item.businessType!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.businessType!.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.status == KycStatus.approved
                            ? const Color(0xFFDCFCE7)
                            : (item.status == KycStatus.rejected
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFFEF3C7)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.status.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: item.status == KycStatus.approved
                              ? const Color(0xFF166534)
                              : (item.status == KycStatus.rejected
                                  ? const Color(0xFF991B1B)
                                  : const Color(0xFF92400E)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Owner: ${item.ownerName} • Phone: ${item.ownerPhone} • Email: ${item.ownerEmail}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Store Address: ${item.address}${item.landmark != null && item.landmark!.isNotEmpty ? " (Near ${item.landmark})" : ""}, ${item.cityZone}${item.pincode != null && item.pincode!.isNotEmpty ? " - ${item.pincode}" : ""}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('GSTIN: ${item.gstin}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: AppTheme.primaryColor)),
                    const SizedBox(width: 14),
                    Text('Trade License: ${item.businessRegNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 10),

                // Financial & Identity Details Block (Unmasked Full Numbers - NO STARS)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'PAN: ${item.panNumber}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Aadhaar: ${item.aadhaarNumber}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bank: ${item.bankName}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'A/C: ${item.bankAccountNumber}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: AppTheme.primaryColor),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'IFSC: ${item.bankIfsc}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      if (item.bankAccountName != null && item.bankAccountName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Account Holder: ${item.bankAccountName}',
                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),

                // Attached KYC Documents
                if (item.submittedDocuments.isNotEmpty || (item.licenseDocumentUrl != null && item.licenseDocumentUrl!.isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.file_present_rounded, size: 14, color: AppTheme.successColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Attached Proofs: ${item.submittedDocuments.isNotEmpty ? item.submittedDocuments.length : 1} Document on file',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            final docUrl = item.submittedDocuments.isNotEmpty
                                ? item.submittedDocuments.first
                                : (item.licenseDocumentUrl ?? '');
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('KYC Proof: ${item.shopName}'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Document URL:\n$docUrl', style: const TextStyle(fontSize: 12)),
                                    const SizedBox(height: 12),
                                    if (docUrl.startsWith('http'))
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          docUrl,
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Text('Image preview unavailable.'),
                                        ),
                                      ),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                                ],
                              ),
                            );
                          },
                          child: const Text('Inspect Proof', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                        ),
                      ],
                    ),
                  ),
                ],

                if (item.rejectionReason != null && item.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.errorColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Rejection Reason: ${item.rejectionReason}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

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
                        onPressed: () async {
                          final success = await ref.read(adminProvider.notifier).approveBoutique(
                                item.id,
                                shopName: item.shopName,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? '🎉 Approved "${item.shopName}". Boutique is now activated!' : 'Failed to approve ${item.shopName}'),
                                backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                              ),
                            );
                          }
                        },
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
                    _buildStatPill('3% Comm', '₹${seller.commissionGenerated.toStringAsFixed(0)}'),
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
  // TAB 8: FINANCIALS, SHOP PAYBACKS & SALARIES
  // ==========================================
  Widget _buildFinancialsTab(BuildContext context, AdminMetricsModel metrics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-Section Navigation Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFinanceSubChip(0, 'Complete Financial Overview', Icons.dashboard),
                const SizedBox(width: 8),
                _buildFinanceSubChip(1, 'Shop Paybacks (Per Shop)', Icons.store),
                const SizedBox(width: 8),
                _buildFinanceSubChip(2, 'Order-Level Payouts', Icons.receipt_long),
                const SizedBox(width: 8),
                _buildFinanceSubChip(3, 'Delivery Fleet Salaries', Icons.two_wheeler),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. Platform Summary & Ledger (Shown on All or Overview)
          if (_financeSubSection == 0 || _financeSubSection == 1) ...[
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
                      _buildWhiteStat('Platform Comm (3%)', '₹${metrics.totalCommissionEarned.toStringAsFixed(0)}'),
                      _buildWhiteStat('Ad Revenue', '₹${metrics.totalAdRevenue.toStringAsFixed(0)}'),
                      _buildWhiteStat('Seller Payback (97%)', '₹${metrics.sellerEarnings.toStringAsFixed(0)}'),
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
                    _buildFinancialRow('3% Platform Commission', '+₹${metrics.totalCommissionEarned.toStringAsFixed(2)}', color: AppTheme.successColor),
                    _buildFinancialRow('Advertisements & Promos', '+₹${metrics.totalAdRevenue.toStringAsFixed(2)}', color: AppTheme.successColor),
                    _buildFinancialRow('Delivery Platform Fee Share', '+₹${(metrics.totalDeliveryCharges * 0.20).toStringAsFixed(2)}', color: AppTheme.successColor),
                    _buildFinancialRow('Payment Gateway Costs (2%)', '-₹${metrics.gatewayCharges.toStringAsFixed(2)}', color: AppTheme.errorColor),
                    _buildFinancialRow('Refund Commission Reversals (3%)', '-₹${(metrics.totalRefundsAmount * (metrics.platformCommissionRate / 100)).toStringAsFixed(2)}', color: AppTheme.errorColor),
                    const Divider(height: 20),
                    _buildFinancialRow('Net Platform Revenue / Earnings', '₹${metrics.netPlatformEarnings.toStringAsFixed(2)}', isBold: true, color: AppTheme.primaryColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 2. Shop-wise Commission & Seller Payback (Per Shop)
          if (_financeSubSection == 0 || _financeSubSection == 1) ...[
            _buildShopPaybacksSection(context, metrics),
            const SizedBox(height: 24),
          ],

          // 3. Order-Level Seller Revenue Settlements & Disbursal
          if (_financeSubSection == 0 || _financeSubSection == 2) ...[
            _buildOrderLevelPayoutsSection(context, metrics),
            const SizedBox(height: 24),
          ],

          // 4. Delivery Fleet Monthly Salary & Trip Payback
          if (_financeSubSection == 0 || _financeSubSection == 3) ...[
            _buildDeliveryFleetSalarySection(context, metrics),
          ],
        ],
      ),
    );
  }

  Widget _buildFinanceSubChip(int index, String label, IconData icon) {
    final isSelected = _financeSubSection == index;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.primaryColor),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _financeSubSection = index),
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF1E293B),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0)),
      ),
    );
  }

  // ─── SECTION 2: SHOP-WISE COMMISSION & SELLER PAYBACK ─────────────────────
  Widget _buildShopPaybacksSection(BuildContext context, AdminMetricsModel metrics) {
    final settlements = metrics.shopSettlements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shop-wise Commission & Seller Payback', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                const Text(
                  'Separate payback for each boutique: 3% platform commission deducted, 97% net payable to seller.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                '${settlements.length} Boutiques',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (settlements.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No boutique settlements found.', style: TextStyle(color: AppTheme.textSecondary))),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: settlements.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final item = settlements[i];
              final isSettled = item.settlementStatus.toLowerCase() == 'settled';
              final isPartial = item.settlementStatus.toLowerCase() == 'partial';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.storefront, color: AppTheme.primaryColor, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text('Owner: ${item.ownerName} • Bank: ${item.bankName}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                  Text('A/C: ${item.bankAccountNumber} • IFSC: ${item.bankIfsc}', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSettled ? const Color(0xFFDCFCE7) : (isPartial ? const Color(0xFFFEF3C7) : const Color(0xFFFFE4E6)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.settlementStatus.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSettled ? const Color(0xFF166534) : (isPartial ? const Color(0xFFB45309) : const Color(0xFF9F1239)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Metrics Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatPill('Eligible Orders', '${item.eligibleOrdersCount} orders'),
                          _buildStatPill('Gross Sales (GMV)', '₹${item.grossSubtotal.toStringAsFixed(2)}'),
                          _buildStatPill('3% Commission', '+₹${item.commissionAmount.toStringAsFixed(2)}'),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('₹${item.netPayback.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor)),
                              const Text('Net Payback (97%)', style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${item.pendingPayback.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: item.pendingPayback > 0 ? const Color(0xFFB45309) : AppTheme.successColor)),
                              Text(item.pendingPayback > 0 ? 'Pending Payback' : 'Fully Settled', style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ─── SECTION 3: ORDER-LEVEL SELLER PAYOUTS & AUDIT LOG ───────────────────
  Widget _buildOrderLevelPayoutsSection(BuildContext context, AdminMetricsModel metrics) {
    var orders = metrics.orders;
    if (_financeOrderFilter == 'Pending') {
      orders = orders.where((o) => o.sellerPayoutStatus != 'paid').toList();
    } else if (_financeOrderFilter == 'Paid') {
      orders = orders.where((o) => o.sellerPayoutStatus == 'paid').toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order-Level Seller Revenue Settlements', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                const Text(
                  'Pay the 97% merchandise revenue directly per order and maintain an immutable financial audit log.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
            Row(
              children: [
                _buildPayoutFilterButton('All'),
                const SizedBox(width: 6),
                _buildPayoutFilterButton('Pending'),
                const SizedBox(width: 6),
                _buildPayoutFilterButton('Paid'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (orders.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No orders match the selected payout filter.', style: TextStyle(color: AppTheme.textSecondary))),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final o = orders[i];
              final isPaid = o.sellerPayoutStatus == 'paid';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Order Icon & ID
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isPaid ? Icons.check_circle : Icons.pending_actions,
                          color: isPaid ? const Color(0xFF166534) : const Color(0xFFB45309),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Order Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('#${o.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 8),
                                Text('• ${o.shopName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.primaryColor)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text('Customer: ${o.consumerName} • Items: ${o.productTitles}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (isPaid && o.sellerPayoutRef != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('Paid via ${o.sellerPaymentMethod ?? 'Razorpay Route'} (UTR: ${o.sellerPayoutRef})', style: const TextStyle(fontSize: 10, color: Color(0xFF166534), fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),

                      // Financial Numbers
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Subtotal: ₹${o.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            Text('3% Comm: -₹${o.commissionAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            const SizedBox(height: 2),
                            Text('Net Payable: ₹${o.sellerPayout.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
                          ],
                        ),
                      ),

                      // Action / Status Badge
                      if (isPaid)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('PAID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF166534))),
                        )
                      else
                        ElevatedButton.icon(
                          icon: const Icon(Icons.payment, size: 14),
                          label: const Text('Pay Seller', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _showPaySellerDialog(context, o),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPayoutFilterButton(String label) {
    final isSelected = _financeOrderFilter == label;
    return InkWell(
      onTap: () => setState(() => _financeOrderFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // ─── SECTION 4: DELIVERY FLEET MONTHLY SALARY & PER-ORDER PAYBACK ────────
  Widget _buildDeliveryFleetSalarySection(BuildContext context, AdminMetricsModel metrics) {
    final fleetSalaries = metrics.deliverySalaries;

    final totalTrips = fleetSalaries.fold<int>(0, (acc, s) => acc + s.completedOrdersCount);
    final totalTripEarnings = fleetSalaries.fold<double>(0.0, (acc, s) => acc + s.perOrderEarningsTotal);
    final totalSalaries = fleetSalaries.fold<double>(0.0, (acc, s) => acc + s.totalCalculatedSalary);
    final totalPendingSalaries = fleetSalaries.fold<double>(0.0, (acc, s) => acc + s.pendingSalary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivery Fleet Monthly Salary & Trip Payback', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                const Text(
                  'Per-order trip records (how much received per delivery), aggregated as monthly salary and automatically calculated.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.calendar_month, size: 14, color: AppTheme.primaryColor),
                  SizedBox(width: 6),
                  Text('October 2026 (Active Period)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Fleet Salary Aggregation Banner Cards
        Row(
          children: [
            Expanded(child: _buildSalaryKpiCard('Total Completed Trips', '$totalTrips trips', Icons.local_shipping, const Color(0xFF2563EB))),
            const SizedBox(width: 8),
            Expanded(child: _buildSalaryKpiCard('Per-Order Trip Earnings', '₹${totalTripEarnings.toStringAsFixed(0)}', Icons.payments, const Color(0xFF16A34A))),
            const SizedBox(width: 8),
            Expanded(child: _buildSalaryKpiCard('Total Monthly Salaries', '₹${totalSalaries.toStringAsFixed(0)}', Icons.account_balance_wallet, AppTheme.primaryColor)),
            const SizedBox(width: 8),
            Expanded(child: _buildSalaryKpiCard('Pending Disbursals', '₹${totalPendingSalaries.toStringAsFixed(0)}', Icons.hourglass_top, const Color(0xFFD97706))),
          ],
        ),
        const SizedBox(height: 14),

        if (fleetSalaries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No delivery partners registered in fleet.', style: TextStyle(color: AppTheme.textSecondary))),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: fleetSalaries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final s = fleetSalaries[i];
              final isPaid = s.salaryStatus.toLowerCase() == 'paid';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFFEF3C7),
                            child: const Icon(Icons.two_wheeler, color: Color(0xFFD97706)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(s.driverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                                      child: Text(s.vehicleNumber, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('Phone: ${s.phone} • UPI: ${s.upiId} • Vehicle: ${s.vehicleType}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                if (isPaid && s.paymentReference != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text('Salary Disbursed (UTR: ${s.paymentReference})', style: const TextStyle(fontSize: 10, color: Color(0xFF166534), fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPaid ? 'SALARY PAID' : 'PENDING DISBURSAL',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPaid ? const Color(0xFF166534) : const Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Salary Breakdown Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatPill('Completed Trips', '${s.completedOrdersCount} trips'),
                          _buildStatPill('Per-Order Earnings (₹70)', '₹${s.perOrderEarningsTotal.toStringAsFixed(2)}'),
                          _buildStatPill('Monthly Incentive', '+₹${s.monthlyIncentiveBonus.toStringAsFixed(2)}'),
                          _buildStatPill('Penalties', '-₹${s.penaltyDeductions.toStringAsFixed(2)}'),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('₹${s.totalCalculatedSalary.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor)),
                              const Text('Calculated Monthly Salary', style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${s.pendingSalary.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: s.pendingSalary > 0 ? const Color(0xFFB45309) : AppTheme.successColor)),
                              Text(s.pendingSalary > 0 ? 'Pending Salary' : 'Disbursed', style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.list_alt, size: 14),
                            label: const Text('View Per-Order Trips', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF475569),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () => _showDriverTripsModal(context, s),
                          ),
                          const SizedBox(width: 8),
                          if (!isPaid)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.attach_money, size: 14),
                              label: Text('Disburse Salary (₹${s.pendingSalary.toStringAsFixed(0)})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () => _showDisburseSalaryDialog(context, s),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSalaryKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── DIALOG 1: PAY SELLER PER ORDER ───────────────────────────────────────
  void _showPaySellerDialog(BuildContext context, AdminOrderItem order) {
    final refController = TextEditingController(text: 'UTR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}');
    String selectedMethod = 'Razorpay Route (Sub-account Transfer)';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.account_balance, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('Disburse Seller Revenue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order: #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Boutique: ${order.shopName}', style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                          const Divider(height: 16),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('Merchandise Subtotal:', style: TextStyle(fontSize: 12)),
                            Text('₹${order.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 4),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('Platform Commission (3%):', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            Text('-₹${order.commissionAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B))),
                          ]),
                          const Divider(height: 16),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('Net Seller Payback (97%):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                            Text('₹${order.sellerPayout.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedMethod,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Razorpay Route (Sub-account Transfer)', child: Text('Razorpay Route Transfer', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'Bank Transfer (NEFT/RTGS)', child: Text('Bank Transfer (NEFT/RTGS)', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'Instant UPI Payout', child: Text('Instant UPI Payout', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedMethod = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    const Text('Transaction Reference / UTR Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: refController,
                      decoration: InputDecoration(
                        hintText: 'Enter bank UTR or gateway transfer ID',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    final refId = refController.text.trim().isEmpty ? 'UTR-${DateTime.now().millisecondsSinceEpoch}' : refController.text.trim();
                    final ok = await ref.read(adminProvider.notifier).paySellerForOrder(
                      orderId: order.id,
                      shopName: order.shopName,
                      amount: order.sellerPayout,
                      paymentMethod: selectedMethod,
                      transactionRef: refId,
                    );
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Disbursed ₹${order.sellerPayout.toStringAsFixed(2)} to ${order.shopName} (Ref: $refId). Audit log recorded.'),
                          backgroundColor: const Color(0xFF166534),
                        ),
                      );
                    }
                  },
                  child: Text('Confirm Disbursal (₹${order.sellerPayout.toStringAsFixed(2)})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── DIALOG 2: DISBURSE DELIVERY MONTHLY SALARY ───────────────────────────
  void _showDisburseSalaryDialog(BuildContext context, DeliveryMonthlySalarySummary salary) {
    final refController = TextEditingController(text: 'SAL-UTR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}');
    String selectedMethod = 'Instant UPI Transfer';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.payments, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  const Text('Disburse Delivery Salary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Partner: ${salary.driverName} (${salary.vehicleNumber})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Pay Period: ${salary.monthName} • UPI: ${salary.upiId}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          const Divider(height: 16),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('Trip Earnings (${salary.completedOrdersCount} trips):', style: const TextStyle(fontSize: 12)),
                            Text('₹${salary.perOrderEarningsTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 4),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('Monthly Attendance Incentive:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            Text('+₹${salary.monthlyIncentiveBonus.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A))),
                          ]),
                          const Divider(height: 16),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('Total Net Salary Payable:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                            Text('₹${salary.pendingSalary.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Payment Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedMethod,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Instant UPI Transfer', child: Text('Instant UPI Transfer (Direct)', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'Direct Bank NEFT/IMPS', child: Text('Direct Bank Transfer (NEFT/IMPS)', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedMethod = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    const Text('Payment Reference / UTR Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: refController,
                      decoration: InputDecoration(
                        hintText: 'Enter bank UTR or UPI reference',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    final refId = refController.text.trim().isEmpty ? 'SAL-UTR-${DateTime.now().millisecondsSinceEpoch}' : refController.text.trim();
                    final ok = await ref.read(adminProvider.notifier).disburseDeliverySalary(
                      driverId: salary.driverId,
                      driverName: salary.driverName,
                      monthName: salary.monthName,
                      amount: salary.pendingSalary,
                      paymentMethod: selectedMethod,
                      transactionRef: refId,
                    );
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Disbursed monthly salary of ₹${salary.pendingSalary.toStringAsFixed(2)} to ${salary.driverName} (Ref: $refId). Audit log recorded.'),
                          backgroundColor: const Color(0xFF166534),
                        ),
                      );
                    }
                  },
                  child: Text('Disburse Salary (₹${salary.pendingSalary.toStringAsFixed(2)})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── MODAL 3: VIEW PER-ORDER TRIPS FOR DELIVERY PARTNER ───────────────────
  void _showDriverTripsModal(BuildContext context, DeliveryMonthlySalarySummary salary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Per-Order Trip Records: ${salary.driverName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Month: ${salary.monthName} • Vehicle: ${salary.vehicleNumber}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recorded Trips: ${salary.tripRecords.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('Total Trip Earnings: ₹${salary.perOrderEarningsTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollCtrl,
                      itemCount: salary.tripRecords.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, idx) {
                        final trip = salary.tripRecords[idx];
                        final df = DateFormat('dd MMM, hh:mm a');
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.check, color: Color(0xFF166534), size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Order #${trip.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text(trip.deliveryZone, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                    Text(df.format(trip.deliveryTime), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('₹${trip.tripEarning.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF16A34A))),
                                  const Text('Trip Earning', style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
  // HELPER WIDGETS
  // ==========================================
  Widget _buildStatPill(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
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
                await ref.read(adminProvider.notifier).rejectBoutique(
                      item.id,
                      shopName: item.shopName,
                      reason: controller.text.trim(),
                    );
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
                await ref.read(adminProvider.notifier).requestKycCorrection(
                      item.id,
                      shopName: item.shopName,
                      notes: controller.text.trim(),
                    );
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

// ==========================================
// CUSTOM PAINTER: SPARKLINE AREA CHART
// ==========================================
class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _SparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final minVal = points.reduce((a, b) => a < b ? a : b);
    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal > 0 ? (maxVal - minVal) : 1.0;

    final dx = size.width / (points.length - 1);
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = i * dx;
      final normalized = (points[i] - minVal) / range;
      final y = size.height - (normalized * (size.height - 6)) - 3;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * dx;
        final prevNorm = (points[i - 1] - minVal) / range;
        final prevY = size.height - (prevNorm * (size.height - 6)) - 3;
        final cpx1 = prevX + dx / 2;
        final cpy1 = prevY;
        final cpx2 = prevX + dx / 2;
        final cpy2 = y;
        path.cubicTo(cpx1, cpy1, cpx2, cpy2, x, y);
        fillPath.cubicTo(cpx1, cpy1, cpx2, cpy2, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Gradient fill under the line
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Stroke curve line
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => true;
}

// ==========================================
// CUSTOM PAINTER: COMBO BAR + SPLINE CHART
// ==========================================
class _ComboTrendChartPainter extends CustomPainter {
  final List<AdminChartPoint> ordersTrends;
  final List<AdminChartPoint> revenueTrends;

  _ComboTrendChartPainter({
    this.ordersTrends = const [],
    this.revenueTrends = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 38.0;
    const rightMargin = 42.0;
    const topMargin = 12.0;
    const bottomMargin = 30.0;

    final chartWidth = size.width - leftMargin - rightMargin;
    final chartHeight = size.height - topMargin - bottomMargin;

    if (ordersTrends.isEmpty && revenueTrends.isEmpty) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'No orders recorded in current timeframe',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(leftMargin + (chartWidth - textPainter.width) / 2, topMargin + chartHeight / 2),
      );
      return;
    }

    // Determine scale dynamically from real data
    double maxOrderVal = 5.0;
    for (final p in ordersTrends) {
      if (p.value > maxOrderVal) maxOrderVal = p.value;
    }
    maxOrderVal = (maxOrderVal * 1.25).ceilToDouble();
    if (maxOrderVal < 5) maxOrderVal = 5.0;

    double maxRevVal = 1000.0;
    for (final p in revenueTrends) {
      if (p.value > maxRevVal) maxRevVal = p.value;
    }
    maxRevVal = (maxRevVal * 1.25).ceilToDouble();
    if (maxRevVal < 1000) maxRevVal = 1000.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    // Y Axis (4 intervals)
    for (int i = 0; i <= 4; i++) {
      final y = topMargin + (chartHeight / 4) * i;
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width - rightMargin, y), gridPaint);

      // Left Axis (Orders)
      final orderVal = ((maxOrderVal * (4 - i)) / 4).round().toString();
      textPainter.text = TextSpan(
        text: orderVal,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w600),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftMargin - textPainter.width - 6, y - textPainter.height / 2));

      // Right Axis (Revenue)
      final revAmount = ((maxRevVal * (4 - i)) / 4);
      final revStr = i == 4 ? '₹0' : '₹${(revAmount / 1000).toStringAsFixed(1)}K';
      textPainter.text = TextSpan(
        text: revStr,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w600),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - rightMargin + 6, y - textPainter.height / 2));
    }

    final pointsCount = ordersTrends.length;
    if (pointsCount == 0) return;

    final dx = pointsCount > 1 ? chartWidth / (pointsCount - 1) : chartWidth / 2;

    // X Axis Labels (Dates from real points)
    for (int i = 0; i < pointsCount; i++) {
      final x = pointsCount > 1 ? leftMargin + (i * dx) : leftMargin + dx;
      textPainter.text = TextSpan(
        text: ordersTrends[i].label,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - bottomMargin + 10));
    }

    // Orders Volumes (Bars)
    final barPaint = Paint()
      ..color = const Color(0xFFFECDD3)
      ..style = PaintingStyle.fill;

    const barWidth = 10.0;
    for (int i = 0; i < pointsCount; i++) {
      final x = pointsCount > 1 ? leftMargin + (i * dx) : leftMargin + dx;
      final val = ordersTrends[i].value;
      if (val > 0) {
        final height = (val / maxOrderVal) * chartHeight;
        final y = topMargin + chartHeight - height;
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x - barWidth / 2, y, barWidth, height),
          const Radius.circular(3),
        );
        canvas.drawRRect(rrect, barPaint);
      }
    }

    // Revenue Trajectory Line (from real revenueTrends)
    final revCount = revenueTrends.length;
    if (revCount > 0) {
      final rdx = revCount > 1 ? chartWidth / (revCount - 1) : chartWidth / 2;
      final linePath = Path();
      final nodePoints = <Offset>[];

      for (int i = 0; i < revCount; i++) {
        final x = revCount > 1 ? leftMargin + (i * rdx) : leftMargin + rdx;
        final normalized = (revenueTrends[i].value / maxRevVal).clamp(0.0, 1.0);
        final y = topMargin + chartHeight - (normalized * chartHeight);
        nodePoints.add(Offset(x, y));

        if (i == 0) {
          linePath.moveTo(x, y);
        } else {
          final prev = nodePoints[i - 1];
          final midX = (prev.dx + x) / 2;
          linePath.cubicTo(midX, prev.dy, midX, y, x, y);
        }
      }

      final strokePaint = Paint()
        ..color = const Color(0xFF881337)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      canvas.drawPath(linePath, strokePaint);

      final dotFillPaint = Paint()..color = const Color(0xFF881337);
      final dotBorderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      for (final pt in nodePoints) {
        canvas.drawCircle(pt, 3.5, dotFillPaint);
        canvas.drawCircle(pt, 3.5, dotBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ComboTrendChartPainter oldDelegate) => true;
}

// ==========================================
// CUSTOM PAINTER: JAIPUR SKYLINE SILHOUETTE
// ==========================================
class _JaipurSkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE11D48).withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    final sunPaint = Paint()
      ..color = const Color(0xFFE11D48).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    // Sun disk
    canvas.drawCircle(Offset(size.width - 150, size.height - 28), 16, sunPaint);

    final path = Path();
    path.moveTo(0, size.height);

    // Stylized silhouette of Hawa Mahal and Rajasthani palace arches
    path.lineTo(20, size.height);
    path.lineTo(20, size.height - 10);
    path.lineTo(35, size.height - 10);
    path.lineTo(35, size.height - 20);
    path.lineTo(45, size.height - 26);
    path.lineTo(55, size.height - 20);
    path.lineTo(55, size.height - 12);
    path.lineTo(70, size.height - 12);
    path.lineTo(70, size.height - 30);
    path.lineTo(85, size.height - 36);
    path.lineTo(100, size.height - 30);
    path.lineTo(100, size.height - 16);
    path.lineTo(120, size.height - 16);
    path.lineTo(120, size.height - 40);
    path.lineTo(135, size.height - 46);
    path.lineTo(150, size.height - 40);
    path.lineTo(150, size.height - 22);
    path.lineTo(170, size.height - 22);
    path.lineTo(180, size.height - 32);
    path.lineTo(190, size.height - 22);
    path.lineTo(200, size.height - 22);
    path.lineTo(200, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
