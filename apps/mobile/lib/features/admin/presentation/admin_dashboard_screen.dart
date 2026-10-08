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
                        title: 'Commission (10%)',
                        value: '₹${(metrics.totalGmv * 0.1).toStringAsFixed(0)}',
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
              painter: _ComboTrendChartPainter(),
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
<<<<<<< HEAD
              Flexible(
=======
              Expanded(
>>>>>>> 1265cd9 (fix(kyc): resolve root cause for shop creation and kyc verification visibility in admin)
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
                    const Expanded(flex: 2, child: Text('Sep 30, 2026', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)))),
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
<<<<<<< HEAD
                    Flexible(
=======
                    Expanded(
>>>>>>> 1265cd9 (fix(kyc): resolve root cause for shop creation and kyc verification visibility in admin)
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
            final pct = (1.0 - (idx * 0.18)).clamp(0.2, 1.0);

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
                  _buildFinancialRow('Delivery Platform Fee Share', '+₹${(metrics.totalDeliveryCharges * 0.20).toStringAsFixed(2)}', color: AppTheme.successColor),
                  _buildFinancialRow('Payment Gateway Costs (2%)', '-₹${metrics.gatewayCharges.toStringAsFixed(2)}', color: AppTheme.errorColor),
                  _buildFinancialRow('Refund Commission Reversals (10%)', '-₹${(metrics.totalRefundsAmount * (metrics.platformCommissionRate / 100)).toStringAsFixed(2)}', color: AppTheme.errorColor),
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
  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 38.0;
    const rightMargin = 38.0;
    const topMargin = 12.0;
    const bottomMargin = 30.0;

    final chartWidth = size.width - leftMargin - rightMargin;
    final chartHeight = size.height - topMargin - bottomMargin;

    // Grid lines & Left/Right Axis Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 4; i++) {
      final y = topMargin + (chartHeight / 4) * i;
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width - rightMargin, y), gridPaint);

      // Left Axis (Orders: 40, 30, 20, 10, 0)
      final orderVal = (40 - (i * 10)).toString();
      textPainter.text = TextSpan(
        text: orderVal,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w600),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftMargin - textPainter.width - 6, y - textPainter.height / 2));

      // Right Axis (Revenue: 20K, 15K, 10K, 5K, 0)
      final revVal = i == 4 ? '0' : '${20 - (i * 5)}K';
      textPainter.text = TextSpan(
        text: revVal,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w600),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - rightMargin + 6, y - textPainter.height / 2));
    }

    // X Axis Labels (Dates)
    final dates = ['Sep 1', 'Sep 5', 'Sep 10', 'Sep 15', 'Sep 20', 'Sep 25', 'Sep 30'];
    final numPoints = 25; // 25 day data points
    final dx = chartWidth / (numPoints - 1);

    for (int i = 0; i < dates.length; i++) {
      final x = leftMargin + (chartWidth / (dates.length - 1)) * i;
      textPainter.text = TextSpan(
        text: dates[i],
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - bottomMargin + 10));
    }

    // Sample Orders Volumes (Bars)
    final barOrders = [
      8, 12, 10, 14, 15, 11, 16, 18, 13, 20, 24, 22, 38, 26, 28, 20, 24, 22, 29, 32, 27, 30, 31, 35, 36
    ];

    final barPaint = Paint()
      ..color = const Color(0xFFFECDD3) // Soft pinkish coral
      ..style = PaintingStyle.fill;

    const barWidth = 6.5;
    for (int i = 0; i < barOrders.length; i++) {
      final x = leftMargin + (i * dx);
      final height = (barOrders[i] / 40.0) * chartHeight;
      final y = topMargin + chartHeight - height;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth / 2, y, barWidth, height),
        const Radius.circular(3),
      );
      canvas.drawRRect(rrect, barPaint);
    }

    // Revenue Trajectory Line (Spline Curve with Circle Nodes)
    final revenue = [
      4.2, 5.0, 5.5, 7.8, 8.2, 9.1, 8.4, 9.8, 8.6, 11.2, 12.8, 11.9, 13.5, 12.6, 13.0, 12.8, 15.2, 14.6, 14.1, 16.5, 15.0, 14.2, 14.8, 16.2, 18.5
    ]; // in Thousands (0 to 20k)

    final linePath = Path();
    final nodePoints = <Offset>[];

    for (int i = 0; i < revenue.length; i++) {
      final x = leftMargin + (i * dx);
      final normalized = revenue[i] / 20.0;
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
      ..color = const Color(0xFF881337) // Deep Royal Crimson
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawPath(linePath, strokePaint);

    // Draw circular dots at key nodes
    final dotFillPaint = Paint()..color = const Color(0xFF881337);
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodePoints.length; i += 2) {
      final pt = nodePoints[i];
      canvas.drawCircle(pt, 3.5, dotFillPaint);
      canvas.drawCircle(pt, 3.5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
