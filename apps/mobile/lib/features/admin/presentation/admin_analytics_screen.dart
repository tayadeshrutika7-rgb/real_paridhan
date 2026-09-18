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
        title: const Text('City-Level Analytics (Jaipur)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            Row(
              children: ['Today', 'This Week', 'This Month'].map((period) {
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

            const SizedBox(height: 16),

            // Key KPI Trio
            Row(
              children: [
                Expanded(
                  child: _KpiBox(
                    label: 'Platform GMV',
                    value: '₹${metrics.totalGmv.toStringAsFixed(0)}',
                    icon: Icons.currency_rupee,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiBox(
                    label: 'Platform Net (10%)',
                    value: '₹${metrics.platformRevenue.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: _KpiBox(
                    label: 'Bargain Conv.',
                    value: '68.4%',
                    icon: Icons.handshake_outlined,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
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
                              '+₹${zone.platformRevenue.toStringAsFixed(0)} (10% Fee)',
                              style: const TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (zone.gmvAmount / metrics.totalGmv).clamp(0.0, 1.0),
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

            const _CategoryBar(name: 'Handblock Anarkali Kurtas', share: '38%', count: '62 orders'),
            const _CategoryBar(name: 'Bandhani & Georgette Dupatta Sets', share: '26%', count: '43 orders'),
            const _CategoryBar(name: 'Pure Silk & Zari Sarees', share: '20%', count: '32 orders'),
            const _CategoryBar(name: 'Bridal Heritage Lehengas', share: '16%', count: '25 orders'),

            const SizedBox(height: 40),
          ],
        ),
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
