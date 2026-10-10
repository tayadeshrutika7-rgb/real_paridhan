import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'admin_controller.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);
    final metrics = adminState.metrics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('City & Financial Analytics (Jaipur)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminProvider.notifier).loadDashboard(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Today', '7 Days', '30 Days', 'This Month'].map((period) {
                  final isSelected = adminState.filterPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(period),
                      selected: isSelected,
                      onSelected: (_) => ref.read(adminProvider.notifier).setFilterPeriod(period),
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Key KPI Grid
            Row(
              children: [
                Expanded(
                  child: _KpiBox(
                    label: 'Gross GMV',
                    value: '₹${metrics.totalGmv.toStringAsFixed(0)}',
                    icon: Icons.currency_rupee,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiBox(
                    label: 'Commission (3%)',
                    value: '₹${metrics.totalCommissionEarned.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiBox(
                    label: 'Ad Revenue',
                    value: '₹${metrics.totalAdRevenue.toStringAsFixed(0)}',
                    icon: Icons.campaign_outlined,
                    color: const Color(0xFFE11D48),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _KpiBox(
                    label: 'Seller Payouts',
                    value: '₹${metrics.sellerEarnings.toStringAsFixed(0)}',
                    icon: Icons.storefront,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiBox(
                    label: 'Net Platform Earnings',
                    value: '₹${metrics.netPlatformEarnings.toStringAsFixed(0)}',
                    icon: Icons.trending_up,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Financial P&L Ledger Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Platform Financial Breakdown',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Icon(Icons.pie_chart_outline, size: 18, color: AppTheme.primaryColor),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFinancialLine('Gross Sales Merchandise (GMV)', '₹${metrics.totalGmv.toStringAsFixed(2)}', isBold: true),
                  _buildFinancialLine('Platform Commission Earned (+3%)', '+₹${metrics.totalCommissionEarned.toStringAsFixed(2)}', color: AppTheme.successColor),
                  _buildFinancialLine('Advertisement Revenue', '+₹${metrics.totalAdRevenue.toStringAsFixed(2)}', color: AppTheme.successColor),
                  _buildFinancialLine('Delivery & Convenience Charges', '+₹${metrics.totalDeliveryCharges.toStringAsFixed(2)}', color: AppTheme.successColor),
                  _buildFinancialLine('Gateway & Processing Charges (2%)', '-₹${metrics.gatewayCharges.toStringAsFixed(2)}', color: AppTheme.errorColor),
                  _buildFinancialLine('Processed Refunds & Disputes', '-₹${metrics.totalRefundsAmount.toStringAsFixed(2)}', color: AppTheme.errorColor),
                  const Divider(height: 16),
                  _buildFinancialLine('Net Platform Revenue / Earnings', '₹${metrics.netPlatformEarnings.toStringAsFixed(2)}', isBold: true, color: AppTheme.primaryColor),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Zone Performance Section
            Text('Jaipur Hyperlocal Zones', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),

            ...metrics.zoneMetrics.map((zone) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(zone.zoneName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(
                              '₹${zone.gmvAmount.toStringAsFixed(0)} GMV',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${zone.activeBoutiques} Boutiques • ${zone.totalOrders} Orders',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            Text(
                              '+₹${zone.platformRevenue.toStringAsFixed(0)} (3% Fee)',
                              style: const TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: metrics.totalGmv > 0 ? (zone.gmvAmount / metrics.totalGmv).clamp(0.0, 1.0) : 0.0,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),

            const SizedBox(height: 24),

            // Category Distribution
            Text('Top Fashion Categories', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),

            ...metrics.categorySalesDistribution.map((c) => _CategoryBar(
                  name: c.label,
                  share: '${((c.value / (metrics.totalGmv > 0 ? metrics.totalGmv : 1)) * 100).toStringAsFixed(1)}%',
                  count: '₹${c.value.toStringAsFixed(0)} GMV',
                )),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialLine(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String name;
  final String share;
  final String count;

  const _CategoryBar({required this.name, required this.share, required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(count, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
            Text(share, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.accentColor)),
          ],
        ),
      ),
    );
  }
}
