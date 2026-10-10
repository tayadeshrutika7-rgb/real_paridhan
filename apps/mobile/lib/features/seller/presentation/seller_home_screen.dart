import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/notifications/presentation/role_notification_badge.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';
import '../domain/product_model.dart';
import 'seller_controller.dart';
import 'widgets/seller_analytics_charts.dart';

class SellerHomeScreen extends ConsumerStatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  ConsumerState<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends ConsumerState<SellerHomeScreen> {
  PerformanceTimeframe _selectedTimeframe = PerformanceTimeframe.today;
  String _selectedCategoryFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final sellerState = ref.watch(sellerProvider);
    final user = authState.user;
    final shop = sellerState.shop;
    final products = sellerState.products;

    // Categorization logic for products
    final Map<String, List<ProductModel>> categoryMap = {};
    int totalInventoryUnits = 0;

    for (final p in products) {
      final cat = _resolveGarmentType(p);
      categoryMap.putIfAbsent(cat, () => []).add(p);
      totalInventoryUnits += p.totalStock;
    }

    // Prepare Inventory Pie Slices
    final List<PieSliceData> inventorySlices = _buildInventorySlices(categoryMap);

    // Prepare Revenue Slices based on selected timeframe
    final List<PieSliceData> revenueSlices = _buildRevenueSlices(categoryMap, _selectedTimeframe);

    // Timeframe-specific KPI metrics derived from real database records
    final _TimeframeMetrics metrics = _calculateMetrics(
      timeframe: _selectedTimeframe,
      products: products,
      totalUnits: totalInventoryUnits,
      orders: sellerState.orders,
      bargains: sellerState.bargains,
      wishlistSaves: sellerState.wishlistSavesCount,
      storeViews: sellerState.storeViewsCount,
    );

    // Filtered products list for the catalog section
    final filteredProducts = _selectedCategoryFilter == 'All'
        ? products
        : products.where((p) => _resolveGarmentType(p) == _selectedCategoryFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync Shop & KYC Status',
            onPressed: () async {
              await ref.read(sellerProvider.notifier).refreshShop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Shop inventory & verification status refreshed!'),
                    duration: Duration(milliseconds: 900),
                  ),
                );
              }
            },
          ),
          const RoleNotificationBadge(role: UserRole.seller),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Shop Settings',
            onPressed: () => context.push('/seller/shop'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () => ref.read(sellerProvider.notifier).refreshShop(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop Card Header
              Card(
                color: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.storefront_rounded, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop?.name ?? user?.fullName ?? 'Local Boutique Store',
                              style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: shop?.isVerified == true
                                        ? AppTheme.successColor
                                        : (shop?.status == 'rejected' || shop?.kycStatus == 'rejected'
                                            ? AppTheme.errorColor
                                            : AppTheme.warningColor),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        shop?.isVerified == true
                                            ? Icons.verified
                                            : (shop?.status == 'rejected' || shop?.kycStatus == 'rejected'
                                                ? Icons.cancel_outlined
                                                : Icons.hourglass_top_rounded),
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        shop?.isVerified == true
                                            ? 'Shop Verified'
                                            : (shop?.status == 'rejected' || shop?.kycStatus == 'rejected'
                                                ? 'KYC Rejected'
                                                : 'KYC Pending Verification'),
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: () => context.push('/seller/shop'),
                                  child: const Text(
                                    'Edit Profile',
                                    style: TextStyle(color: Colors.white70, fontSize: 12, decoration: TextDecoration.underline),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

            // Performance Section with Timeframe Filter Switcher
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTimeframeTitle(_selectedTimeframe),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getTimeframeSubtitle(_selectedTimeframe),
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                // Timeframe Selector Chip Row
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTimeframeTab(
                        label: 'Today',
                        timeframe: PerformanceTimeframe.today,
                      ),
                      const SizedBox(width: 4),
                      _buildTimeframeTab(
                        label: '1 Month',
                        timeframe: PerformanceTimeframe.month,
                      ),
                      const SizedBox(width: 4),
                      _buildTimeframeTab(
                        label: 'Yearly',
                        timeframe: PerformanceTimeframe.year,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // KPI Stat Cards Grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Gross Sales',
                    value: metrics.grossSales,
                    subtext: metrics.salesGrowth,
                    icon: Icons.currency_rupee,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Active Products',
                    value: '${products.length}',
                    subtext: '$totalInventoryUnits items in stock',
                    icon: Icons.checkroom_outlined,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Pending Orders',
                    value: '${metrics.pendingOrders}',
                    subtext: metrics.ordersStatus,
                    icon: Icons.shopping_bag_outlined,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Pending Payout',
                    value: metrics.pendingPayout,
                    subtext: 'Razorpay Route 90%',
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Catalog & Operations Shortcuts
            Text('Catalog & Operations', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),

            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              leading: const CircleAvatar(
                backgroundColor: AppTheme.accentLight,
                child: Icon(Icons.add_photo_alternate, color: AppTheme.accentColor),
              ),
              title: const Text('Add New Garment / Product'),
              subtitle: const Text('With client-side image compression & bargaining floor price'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/seller/add-product'),
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.inventory_2_outlined, color: AppTheme.primaryColor),
              ),
              title: const Text('Inventory & Stock Units'),
              subtitle: const Text('Manage variant sizes, colors, and live counts'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/seller/inventory'),
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFEF3C7),
                child: Icon(Icons.forum_outlined, color: AppTheme.secondaryColor),
              ),
              title: const Text('Bargain Requests & Negotiations'),
              subtitle: const Text('Accept, reject, or counter buyer price offers'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/bargains?seller=true'),
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFDCFCE7),
                child: Icon(Icons.shopping_bag_outlined, color: AppTheme.successColor),
              ),
              title: const Text('Order Fulfillment & Packing Queue'),
              subtitle: const Text('Confirm orders and mark ready for partner pickup'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/seller/orders'),
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFDE8EC),
                child: Icon(Icons.campaign_outlined, color: AppTheme.primaryColor),
              ),
              title: const Text('Promote & Request Advertisements'),
              subtitle: const Text('Get featured in Customer Home Carousel with custom banners'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/seller/advertisements'),
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF3F4F6),
                child: Icon(Icons.account_balance, color: AppTheme.primaryColor),
              ),
              title: const Text('Razorpay Route Split Onboarding'),
              subtitle: const Text('Bank account linked for instant 90% payout splits'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Razorpay Route Sub-Merchant Account is active and linked.')),
                );
              },
            ),

            const SizedBox(height: 24),

            // Interactive Analytics & Visual Charts Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.pie_chart_outline_rounded, color: AppTheme.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Inventory & Sales Breakdown',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Donut Chart 1: Product Inventory & Cloth Type Breakdown
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF0F0F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '👗 Cloth Types & Garment Inventory',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                              ),
                              Text('Total In-Stock', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          PieDonutChart(
                            slices: inventorySlices,
                            centerValue: '$totalInventoryUnits',
                            centerTitle: 'Garments\nIn-Stock',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Donut Chart 2: Category Revenue Share
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF0F0F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '💰 Revenue Share by Garment Type',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                              ),
                              Text(
                                _selectedTimeframe == PerformanceTimeframe.today
                                    ? 'Today'
                                    : (_selectedTimeframe == PerformanceTimeframe.month ? '30 Days' : '1 Year'),
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          PieDonutChart(
                            slices: revenueSlices,
                            centerValue: metrics.grossSales,
                            centerTitle: 'Total\nRevenue',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Bar Chart: Customer Engagement & Bargaining Activity
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF0F0F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📊 Customer Engagement & Bargains',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 14),
                          EngagementBarChart(
                            views: metrics.storeViews,
                            wishlistAdds: metrics.wishlistSaves,
                            bargainsReceived: metrics.bargainsReceived,
                            bargainsAccepted: metrics.bargainsAccepted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Order Fulfillment Status Breakdown
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF0F0F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📦 Order Fulfillment Pipeline',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPipelineStep(
                                  count: metrics.pendingOrders,
                                  label: 'Pending Packing',
                                  color: const Color(0xFFF59E0B),
                                  icon: Icons.inventory_2_outlined,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildPipelineStep(
                                  count: metrics.inTransitOrders,
                                  label: 'In-Transit',
                                  color: const Color(0xFF3B82F6),
                                  icon: Icons.local_shipping_outlined,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildPipelineStep(
                                  count: metrics.deliveredOrders,
                                  label: 'Delivered',
                                  color: AppTheme.successColor,
                                  icon: Icons.check_circle_outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // MY SHOP PRODUCTS & INVENTORY SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Shop Garments & Stock', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${products.length} Products • $totalInventoryUnits Units in Stock',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => context.push('/seller/add-product'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Product'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Garment Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('All', products.length),
                  ...categoryMap.keys.map((cat) {
                    final count = categoryMap[cat]?.length ?? 0;
                    return _buildCategoryChip(cat, count);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Products Catalog Cards List
            if (filteredProducts.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.checkroom_outlined, size: 48, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        const Text('No products found in this category', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Click "Add Product" to start building your boutique catalog', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/seller/add-product'),
                          icon: const Icon(Icons.add_photo_alternate, size: 18),
                          label: const Text('Add Garment / Product'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredProducts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final clothType = _resolveGarmentType(product);
                  final stock = product.totalStock;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppTheme.borderSubtle),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Thumbnail Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  color: const Color(0xFFF3F4F6),
                                  child: Image.network(
                                    product.primaryImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFFF3F4F6),
                                      child: const Icon(Icons.checkroom, color: AppTheme.textMuted, size: 32),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Product Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getCategoryColor(clothType).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            clothType,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _getCategoryColor(clothType),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        // Stock Health Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: stock > 5
                                                ? AppTheme.successColor.withValues(alpha: 0.12)
                                                : (stock > 0
                                                    ? AppTheme.warningColor.withValues(alpha: 0.12)
                                                    : AppTheme.primaryColor.withValues(alpha: 0.12)),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: stock > 5
                                                      ? AppTheme.successColor
                                                      : (stock > 0 ? AppTheme.warningColor : AppTheme.primaryColor),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                stock > 0 ? '$stock in stock' : 'Out of stock',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: stock > 5
                                                      ? AppTheme.successColor
                                                      : (stock > 0 ? AppTheme.warningColor : AppTheme.primaryColor),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      product.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '₹${product.basePrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        if (product.bargainEnabled) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Min: ₹${product.minBargainPrice.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFB45309),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Variants preview (Sizes & Colors)
                          if (product.variants.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1, color: AppTheme.borderSubtle),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Sizes & Units:', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: product.variants.map((v) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFE5E7EB)),
                                        ),
                                        child: Text(
                                          '${v.size}: ${v.stockQty}',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 10),
                          // Action Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => context.push('/seller/inventory'),
                                icon: const Icon(Icons.edit_note, size: 16),
                                label: const Text('Manage Stock', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildTimeframeTab({
    required String label,
    required PerformanceTimeframe timeframe,
  }) {
    final bool isSelected = _selectedTimeframe == timeframe;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTimeframe = timeframe;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, int count) {
    final bool isSelected = _selectedCategoryFilter == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text('$category ($count)'),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : AppTheme.textPrimary,
        ),
        selectedColor: AppTheme.primaryColor,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : AppTheme.borderSubtle,
        ),
        onSelected: (val) {
          setState(() {
            _selectedCategoryFilter = category;
          });
        },
      ),
    );
  }

  Widget _buildPipelineStep({
    required int count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  String _getTimeframeTitle(PerformanceTimeframe timeframe) {
    switch (timeframe) {
      case PerformanceTimeframe.today:
        return 'Today\'s Performance';
      case PerformanceTimeframe.month:
        return '1 Month\'s Performance';
      case PerformanceTimeframe.year:
        return 'Yearly Performance';
    }
  }

  String _getTimeframeSubtitle(PerformanceTimeframe timeframe) {
    switch (timeframe) {
      case PerformanceTimeframe.today:
        return 'Live metrics for today';
      case PerformanceTimeframe.month:
        return 'Past 30 days summary';
      case PerformanceTimeframe.year:
        return 'Annual revenue & trends';
    }
  }

  _TimeframeMetrics _calculateMetrics({
    required PerformanceTimeframe timeframe,
    required List<ProductModel> products,
    required int totalUnits,
    required List<Map<String, dynamic>> orders,
    required List<Map<String, dynamic>> bargains,
    required int wishlistSaves,
    required int storeViews,
  }) {
    final now = DateTime.now();
    DateTime cutoff;
    switch (timeframe) {
      case PerformanceTimeframe.today:
        cutoff = DateTime(now.year, now.month, now.day);
        break;
      case PerformanceTimeframe.month:
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case PerformanceTimeframe.year:
        cutoff = now.subtract(const Duration(days: 365));
        break;
    }

    bool isWithinTimeframe(Map<String, dynamic> item) {
      final raw = item['created_at'];
      if (raw == null) return true;
      final dt = DateTime.tryParse(raw.toString());
      if (dt == null) return true;
      return dt.isAfter(cutoff);
    }

    // 1. Order fulfillment pipeline:
    // "Pending Packing" -> active orders awaiting packing (placed, confirmed)
    // "In-Transit" -> active orders out for delivery / packed
    // "Delivered" -> completed delivered orders
    int pendingPackingCount = 0;
    int inTransitCount = 0;
    int deliveredCount = 0;
    double grossSalesTotal = 0.0;
    double pendingPayoutTotal = 0.0;

    for (final o in orders) {
      final status = (o['status'] ?? '').toString().toLowerCase();
      final total = (o['total_amount'] as num?)?.toDouble() ??
          (o['total'] as num?)?.toDouble() ??
          (o['subtotal'] as num?)?.toDouble() ??
          0.0;
      final payout = (o['seller_payout_amount'] as num?)?.toDouble() ?? (total * 0.90);

      if (status == 'placed' || status == 'confirmed') {
        pendingPackingCount++;
      } else if (status == 'packed' || status == 'out_for_delivery') {
        inTransitCount++;
      } else if (status == 'delivered') {
        deliveredCount++;
      }

      // Sales calculation based on selected timeframe
      if (isWithinTimeframe(o)) {
        if (status == 'delivered' || status == 'confirmed' || status == 'out_for_delivery') {
          grossSalesTotal += total;
        }
        if (status == 'delivered' || status == 'placed' || status == 'confirmed' || status == 'out_for_delivery') {
          if (o['payment_status'] != 'paid' || status != 'delivered') {
            pendingPayoutTotal += payout;
          }
        }
      }
    }

    // 2. Bargains:
    // Count received & accepted within timeframe
    int bargainsReceived = 0;
    int bargainsAccepted = 0;

    for (final b in bargains) {
      if (isWithinTimeframe(b)) {
        bargainsReceived++;
        final bStatus = (b['status'] ?? '').toString().toLowerCase();
        if (bStatus == 'accepted' || bStatus == 'agreed') {
          bargainsAccepted++;
        }
      }
    }

    final formattedGross = '₹${grossSalesTotal.toStringAsFixed(2)}';
    final formattedPayout = '₹${pendingPayoutTotal.toStringAsFixed(2)}';
    final ordersStatus = pendingPackingCount == 0
        ? '0 orders waiting'
        : '$pendingPackingCount ready to pack';

    final String salesGrowth;
    if (orders.isEmpty) {
      salesGrowth = '0 orders in queue';
    } else if (timeframe == PerformanceTimeframe.today) {
      salesGrowth = 'Live metrics today';
    } else if (timeframe == PerformanceTimeframe.month) {
      salesGrowth = '${orders.length} total orders (30d)';
    } else {
      salesGrowth = '${orders.length} total orders (1y)';
    }

    return _TimeframeMetrics(
      grossSales: formattedGross,
      salesGrowth: salesGrowth,
      pendingOrders: pendingPackingCount,
      ordersStatus: ordersStatus,
      pendingPayout: formattedPayout,
      storeViews: storeViews,
      wishlistSaves: wishlistSaves,
      bargainsReceived: bargainsReceived,
      bargainsAccepted: bargainsAccepted,
      inTransitOrders: inTransitCount,
      deliveredOrders: deliveredCount,
    );
  }

  List<PieSliceData> _buildInventorySlices(Map<String, List<ProductModel>> categoryMap) {
    if (categoryMap.isEmpty) {
      return [
        const PieSliceData(label: 'Saree', value: 24, color: Color(0xFFEC4899), detail: '24 units'),
        const PieSliceData(label: 'Lehenga', value: 12, color: Color(0xFF8B5CF6), detail: '12 units'),
        const PieSliceData(label: 'Kurti', value: 18, color: Color(0xFF3B82F6), detail: '18 units'),
        const PieSliceData(label: 'Sherwani', value: 8, color: Color(0xFFF59E0B), detail: '8 units'),
      ];
    }

    final List<PieSliceData> slices = [];
    categoryMap.forEach((category, list) {
      final totalStock = list.fold(0, (sum, p) => sum + p.totalStock);
      final count = totalStock > 0 ? totalStock : list.length;
      slices.add(
        PieSliceData(
          label: category,
          value: count.toDouble(),
          color: _getCategoryColor(category),
          detail: '$count units',
        ),
      );
    });

    return slices;
  }

  List<PieSliceData> _buildRevenueSlices(Map<String, List<ProductModel>> categoryMap, PerformanceTimeframe timeframe) {
    final double multiplier = timeframe == PerformanceTimeframe.today
        ? 1.0
        : (timeframe == PerformanceTimeframe.month ? 30.0 : 365.0);

    if (categoryMap.isEmpty) {
      return [
        PieSliceData(label: 'Saree', value: 45 * multiplier, color: const Color(0xFFEC4899)),
        PieSliceData(label: 'Lehenga', value: 30 * multiplier, color: const Color(0xFF8B5CF6)),
        PieSliceData(label: 'Kurti', value: 15 * multiplier, color: const Color(0xFF3B82F6)),
        PieSliceData(label: 'Sherwani', value: 10 * multiplier, color: const Color(0xFFF59E0B)),
      ];
    }

    final List<PieSliceData> slices = [];
    categoryMap.forEach((category, list) {
      final double totalValue = list.fold(0.0, (sum, p) => sum + (p.basePrice * (p.totalStock > 0 ? p.totalStock : 1)));
      slices.add(
        PieSliceData(
          label: category,
          value: totalValue * (multiplier / 10),
          color: _getCategoryColor(category),
        ),
      );
    });

    return slices;
  }

  String _resolveGarmentType(ProductModel p) {
    final title = p.title.toLowerCase();
    final cat = p.categoryId.toLowerCase();
    if (title.contains('saree') || cat.contains('saree')) return 'Saree';
    if (title.contains('lehenga') || cat.contains('lehenga')) return 'Lehenga';
    if (title.contains('kurti') || title.contains('kurta') || cat.contains('kurti') || cat.contains('kurta')) return 'Kurti & Kurta';
    if (title.contains('sherwani') || cat.contains('sherwani')) return 'Sherwani';
    if (title.contains('suit') || title.contains('anarkali') || cat.contains('suit')) return 'Ethnic Suits';
    if (title.contains('gown') || title.contains('indo') || cat.contains('western')) return 'Indo-Western';
    return 'Ethnic Wear';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Saree':
        return const Color(0xFFEC4899);
      case 'Lehenga':
        return const Color(0xFF8B5CF6);
      case 'Kurti & Kurta':
        return const Color(0xFF3B82F6);
      case 'Sherwani':
        return const Color(0xFFF59E0B);
      case 'Ethnic Suits':
        return const Color(0xFF10B981);
      case 'Indo-Western':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF14B8A6);
    }
  }
}

class _TimeframeMetrics {
  final String grossSales;
  final String salesGrowth;
  final int pendingOrders;
  final String ordersStatus;
  final String pendingPayout;
  final int storeViews;
  final int wishlistSaves;
  final int bargainsReceived;
  final int bargainsAccepted;
  final int inTransitOrders;
  final int deliveredOrders;

  const _TimeframeMetrics({
    required this.grossSales,
    required this.salesGrowth,
    required this.pendingOrders,
    required this.ordersStatus,
    required this.pendingPayout,
    required this.storeViews,
    required this.wishlistSaves,
    required this.bargainsReceived,
    required this.bargainsAccepted,
    required this.inTransitOrders,
    required this.deliveredOrders,
  });
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtext;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtext,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (subtext != null) ...[
              const SizedBox(height: 4),
              Text(
                subtext!,
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
