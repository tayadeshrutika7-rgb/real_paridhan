import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';

class DeliveryHomeScreen extends ConsumerStatefulWidget {
  const DeliveryHomeScreen({super.key});

  @override
  ConsumerState<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends ConsumerState<DeliveryHomeScreen> {
  bool _isOnline = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Partner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Availability Toggle Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isOnline ? AppTheme.successColor.withValues(alpha: 0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isOnline ? AppTheme.successColor : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _isOnline ? AppTheme.successColor : Colors.grey,
                    radius: 8,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isOnline ? 'You are Online' : 'You are Offline',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _isOnline ? AppTheme.successColor : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          _isOnline ? 'Ready to accept local pickup & delivery tasks' : 'Switch on to start receiving orders',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isOnline,
                    activeThumbColor: AppTheme.successColor,
                    onChanged: (val) {
                      setState(() => _isOnline = val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(val ? 'Status set to Online' : 'Status set to Offline')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Verification Notice
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: AppTheme.warningColor, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Verification Queue', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            'Vehicle & License verification will be reviewed by admin in Phase 6.',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text('Today\'s Overview', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),

            const Row(
              children: [
                Expanded(
                  child: _DeliveryStat(title: 'Trips Completed', value: '0', icon: Icons.motorcycle),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _DeliveryStat(title: 'Earnings', value: '₹0.00', icon: Icons.currency_rupee),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _DeliveryStat(title: 'COD Collected', value: '₹0.00', icon: Icons.payments_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DeliveryStat({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
