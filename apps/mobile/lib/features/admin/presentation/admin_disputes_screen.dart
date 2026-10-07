import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/admin_metrics_model.dart';
import 'admin_controller.dart';

class AdminDisputesScreen extends ConsumerWidget {
  const AdminDisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);
    final disputes = adminState.metrics.disputes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disputes & Refund Escalations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminProvider.notifier).loadDashboard(),
          ),
        ],
      ),
      body: disputes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gavel_outlined, size: 64, color: AppTheme.successColor),
                  SizedBox(height: 16),
                  Text('No active disputes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('All consumer & seller orders are settled smoothly.', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: disputes.length,
              itemBuilder: (context, index) {
                final dispute = disputes[index];
                return _DisputeCard(
                  dispute: dispute,
                  onApproveRefund: () async {
                    final success = await ref
                        .read(adminProvider.notifier)
                        .resolveDispute(dispute.id, isRefundApproved: true);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Refund of ₹${dispute.amount.toStringAsFixed(2)} processed for "${dispute.orderNumber}".'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  },
                  onResolveWithoutRefund: () async {
                    final success = await ref
                        .read(adminProvider.notifier)
                        .resolveDispute(dispute.id, isRefundApproved: false);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Dispute for "${dispute.orderNumber}" resolved as mediated exchange.'),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}

class _DisputeCard extends StatelessWidget {
  final DisputeTicket dispute;
  final VoidCallback onApproveRefund;
  final VoidCallback onResolveWithoutRefund;

  const _DisputeCard({
    required this.dispute,
    required this.onApproveRefund,
    required this.onResolveWithoutRefund,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: dispute.isResolved ? AppTheme.borderSubtle : AppTheme.errorColor.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dispute.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: dispute.isResolved
                        ? (dispute.status == 'refunded' ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7))
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dispute.isResolved
                        ? (dispute.status == 'refunded' ? 'REFUNDED' : 'RESOLVED')
                        : 'ACTION REQUIRED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: dispute.isResolved
                          ? (dispute.status == 'refunded' ? const Color(0xFF92400E) : const Color(0xFF166534))
                          : const Color(0xFF991B1B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Consumer: ${dispute.consumerName} ↔ Boutique: ${dispute.boutiqueName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Issue: ${dispute.issueReason}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Claim Amount: ₹${dispute.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
                ),
                if (!dispute.isResolved)
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: onResolveWithoutRefund,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: const Text('Resolve', style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: onApproveRefund,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: const Text('Approve Refund', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
