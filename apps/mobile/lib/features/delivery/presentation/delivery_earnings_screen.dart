import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import 'delivery_controller.dart';

class DeliveryEarningsScreen extends ConsumerWidget {
  const DeliveryEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryState = ref.watch(deliveryProvider);
    final earnings = deliveryState.earnings;
    final timeFormat = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings & COD Settlement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Earnings Card
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
                  const Text(
                    'Today\'s Net Payout',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${earnings.todayTotalEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _EarningsMiniStat(
                        label: 'Base Pay',
                        value: '₹${earnings.todayBaseEarnings.toStringAsFixed(0)}',
                      ),
                      _EarningsMiniStat(
                        label: 'Distance Bonus',
                        value: '₹${earnings.todayDistanceIncentive.toStringAsFixed(0)}',
                      ),
                      _EarningsMiniStat(
                        label: 'Tips',
                        value: '₹${earnings.todayTips.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // COD Cash Held & Remittance Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: earnings.pendingCodRemittance > 0 ? Colors.amber.shade300 : AppTheme.borderSubtle,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, color: Colors.amber, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Cash on Delivery (COD) Held',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const Spacer(),
                        Text(
                          '₹${earnings.pendingCodRemittance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Physical cash collected from customers during deliveries that needs to be settled with Paridhan Platform.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    if (earnings.pendingCodRemittance > 0) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Opening UPI / Bank Remittance Gateway...'),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            );
                          },
                          icon: const Icon(Icons.upload_outlined),
                          label: const Text('Deposit / Remit Cash Online'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Key Stats
            Row(
              children: [
                Expanded(
                  child: _SummaryBox(
                    icon: Icons.delivery_dining,
                    label: 'Trips Completed',
                    value: '${earnings.todayTripsCount}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryBox(
                    icon: Icons.route_outlined,
                    label: 'Distance Covered',
                    value: '${earnings.totalDistanceTodayKm.toStringAsFixed(1)} km',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Trip History Section
            Text('Trip History', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),

            if (earnings.trips.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('No trips completed yet today.', style: TextStyle(color: AppTheme.textSecondary)),
                ),
              )
            else
              ...earnings.trips.map((trip) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(trip.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(
                                '+₹${trip.payout.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successColor,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.store, size: 14, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  trip.shopName,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  trip.dropArea,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${trip.distanceKm} km • ${timeFormat.format(trip.completedAt)}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                              if (trip.isCod)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'COD: ₹${trip.codAmount.toStringAsFixed(0)}',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                  ),
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
}

class _EarningsMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _EarningsMiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryBox({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 22),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
