import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';
import '../domain/delivery_task_model.dart';
import 'delivery_controller.dart';

class DeliveryHomeScreen extends ConsumerStatefulWidget {
  const DeliveryHomeScreen({super.key});

  @override
  ConsumerState<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends ConsumerState<DeliveryHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarAnimController;

  @override
  void initState() {
    super.initState();
    _radarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _radarAnimController.dispose();
    super.dispose();
  }

  void _handleAccept(DeliveryTaskModel task) async {
    final success = await ref.read(deliveryProvider.notifier).acceptIncomingTask(task.id);
    if (success && mounted) {
      context.push('/delivery/trip/${task.orderId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryProvider);
    final user = ref.watch(authProvider).user;
    final isOnline = deliveryState.isOnline;
    final activeTrip = deliveryState.activeTrip;
    final incomingRequests = deliveryState.incomingRequests;
    final earnings = deliveryState.earnings;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delivery Partner Radar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              user?.fullName ?? 'Fleet Partner',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Earnings & COD',
            onPressed: () => context.push('/delivery/earnings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(deliveryProvider.notifier).loadDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Online / Offline Duty Radar Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isOnline
                      ? AppTheme.successColor.withValues(alpha: 0.08)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOnline
                        ? AppTheme.successColor.withValues(alpha: 0.5)
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _radarAnimController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline
                                ? AppTheme.successColor.withValues(
                                    alpha: 0.2 + (_radarAnimController.value * 0.3))
                                : Colors.grey.shade300,
                          ),
                          child: Icon(
                            isOnline ? Icons.radar : Icons.power_settings_new,
                            color: isOnline ? AppTheme.successColor : Colors.grey,
                            size: 24,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOnline ? 'You are ON DUTY' : 'You are OFF DUTY',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isOnline ? AppTheme.successColor : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOnline
                                ? 'Scanning 10km radius for boutique orders'
                                : 'Switch on to start receiving delivery requests',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isOnline,
                      activeThumbColor: AppTheme.successColor,
                      onChanged: (val) {
                        ref.read(deliveryProvider.notifier).toggleDuty(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Active Trip Banner (if any)
              if (activeTrip != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.25),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'TRIP IN PROGRESS',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '₹${activeTrip.deliveryPayout.toStringAsFixed(0)} Payout',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        activeTrip.orderNumber,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pickup: ${activeTrip.shopName} → Drop: ${activeTrip.customerName}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/delivery/trip/${activeTrip.orderId}'),
                          icon: const Icon(Icons.navigation_outlined, color: AppTheme.primaryColor),
                          label: const Text('Resume Active Trip', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Quick Performance Metrics (Tap to open full Earnings Screen)
              InkWell(
                onTap: () => context.push('/delivery/earnings'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuickStatItem(
                        icon: Icons.motorcycle,
                        label: 'Trips',
                        value: '${earnings.todayTripsCount}',
                      ),
                      Container(width: 1, height: 32, color: AppTheme.borderSubtle),
                      _QuickStatItem(
                        icon: Icons.currency_rupee,
                        label: 'Earnings',
                        value: '₹${earnings.todayTotalEarnings.toStringAsFixed(0)}',
                      ),
                      Container(width: 1, height: 32, color: AppTheme.borderSubtle),
                      _QuickStatItem(
                        icon: Icons.payments_outlined,
                        label: 'COD Held',
                        value: '₹${earnings.pendingCodRemittance.toStringAsFixed(0)}',
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 4. Dispatch Radar: Incoming Order Requests
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nearby Order Radar', style: Theme.of(context).textTheme.headlineSmall),
                  if (incomingRequests.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${incomingRequests.length} Available',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (!isOnline)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.bedtime_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('You are currently Offline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text(
                            'Toggle duty status to Online above to receive hyperlocal pickup orders.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (incomingRequests.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Center(
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 16),
                          const Text('Radar Active • Searching nearby stores...', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text(
                            'New fashion orders from Jaipur boutiques will appear here automatically.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...incomingRequests.map((task) => _IncomingTaskCard(
                      task: task,
                      onAccept: () => _handleAccept(task),
                      onDecline: () => ref.read(deliveryProvider.notifier).dismissRequest(task.id),
                    )),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickStatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primaryColor),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _IncomingTaskCard extends StatelessWidget {
  final DeliveryTaskModel task;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingTaskCard({
    required this.task,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.primaryColor, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payout & Distance Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹${task.deliveryPayout.toStringAsFixed(0)} Payout',
                        style: const TextStyle(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (task.isCod)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'COD: ₹${task.codCashToCollect.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  '${task.totalDistanceKm.toStringAsFixed(1)} km total',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),

            const Divider(height: 20),

            // Pickup Store
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.store, color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        '${task.shopAddress} (${task.distanceToShopKm} km away)',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Customer Drop
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: AppTheme.accentColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deliver to: ${task.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(task.dropAddress, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Pass'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept Order'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
