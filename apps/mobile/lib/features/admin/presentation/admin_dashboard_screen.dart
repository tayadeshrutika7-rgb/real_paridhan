import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';
import 'admin_controller.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);
    final metrics = adminState.metrics;
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Super Admin Portal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              '${user?.fullName ?? "Platform Operator"} (City Ops: Jaipur)',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Metrics',
            onPressed: () => ref.read(adminProvider.notifier).loadDashboard(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminProvider.notifier).loadDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Revenue & GMV Banner
              Container(
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
                        const Text(
                          'Gross Merchandise Value (GMV)',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            adminState.filterPeriod,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${metrics.totalGmv.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _AdminMiniStat(
                          label: '10% Platform Revenue',
                          value: '₹${metrics.platformRevenue.toStringAsFixed(0)}',
                          highlight: true,
                        ),
                        _AdminMiniStat(
                          label: 'Total Orders',
                          value: '${metrics.totalOrdersCount}',
                        ),
                        _AdminMiniStat(
                          label: 'Active Boutiques',
                          value: '${metrics.activeBoutiquesCount}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Pending KYC Approvals Alert Banner
              if (metrics.pendingKycCount > 0) ...[
                InkWell(
                  onTap: () => context.push('/admin/boutiques'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppTheme.accentColor,
                          radius: 20,
                          child: Icon(Icons.verified_user_outlined, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${metrics.pendingKycCount} Boutiques Awaiting KYC Approval',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.accentColor),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Verify business GSTIN, store address & catalog licenses to activate stores.',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.accentColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 3. Quick Navigation Hub
              Text('Operations Hub', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _HubCard(
                      icon: Icons.storefront_outlined,
                      title: 'Boutique KYC',
                      subtitle: '${metrics.pendingKycCount} Pending Review',
                      color: AppTheme.primaryColor,
                      onTap: () => context.push('/admin/boutiques'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HubCard(
                      icon: Icons.analytics_outlined,
                      title: 'City Analytics',
                      subtitle: 'Hyperlocal Jaipur Trends',
                      color: AppTheme.accentColor,
                      onTap: () => context.push('/admin/analytics'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _HubCard(
                      icon: Icons.support_agent_outlined,
                      title: 'Disputes & Refunds',
                      subtitle: '${metrics.disputes.where((d) => !d.isResolved).length} Open Cases',
                      color: Colors.purple.shade700,
                      onTap: () => context.push('/admin/disputes'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HubCard(
                      icon: Icons.delivery_dining_outlined,
                      title: 'Fleet Radar',
                      subtitle: '${metrics.onDutyDeliveryFleetCount} Drivers on Duty',
                      color: AppTheme.successColor,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${metrics.onDutyDeliveryFleetCount} Delivery Partners actively on duty across Jaipur.')),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 4. City Zone Quick Preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Jaipur Zone Performance', style: Theme.of(context).textTheme.headlineSmall),
                  TextButton(
                    onPressed: () => context.push('/admin/analytics'),
                    child: const Text('View All'),
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
                                style: const TextStyle(fontSize: 11, color: AppTheme.successColor, fontWeight: FontWeight.w600),
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
      ),
    );
  }
}

class _AdminMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _AdminMiniStat({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppTheme.secondaryColor : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
