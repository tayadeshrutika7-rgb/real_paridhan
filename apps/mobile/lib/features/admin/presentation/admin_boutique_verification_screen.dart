import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/admin_metrics_model.dart';
import 'admin_controller.dart';

class AdminBoutiqueVerificationScreen extends ConsumerStatefulWidget {
  const AdminBoutiqueVerificationScreen({super.key});

  @override
  ConsumerState<AdminBoutiqueVerificationScreen> createState() =>
      _AdminBoutiqueVerificationScreenState();
}

class _AdminBoutiqueVerificationScreenState
    extends ConsumerState<AdminBoutiqueVerificationScreen> {
  KycStatus? _selectedFilter = KycStatus.pending;

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final boutiques = adminState.metrics.pendingBoutiques;

    final filtered = _selectedFilter == null
        ? boutiques
        : boutiques.where((b) => b.status == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boutique KYC Verification'),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Pending Review',
                  isSelected: _selectedFilter == KycStatus.pending,
                  onTap: () => setState(() => _selectedFilter = KycStatus.pending),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Approved',
                  isSelected: _selectedFilter == KycStatus.approved,
                  onTap: () => setState(() => _selectedFilter = KycStatus.approved),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'All Stores',
                  isSelected: _selectedFilter == null,
                  onTap: () => setState(() => _selectedFilter = null),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Boutique List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 64, color: AppTheme.successColor),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == KycStatus.pending
                              ? 'All boutique KYC verifications are up to date!'
                              : 'No boutiques found for selected filter.',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _BoutiqueKycCard(
                        item: item,
                        onApprove: () async {
                          final success = await ref
                              .read(adminProvider.notifier)
                              .approveBoutique(item.id);
                          if (success && mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('Approved "${item.shopName}". Store is now live on discovery radar.'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          }
                        },
                        onReject: () async {
                          final success = await ref
                              .read(adminProvider.notifier)
                              .rejectBoutique(item.id);
                          if (success && mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('Rejected KYC for "${item.shopName}".'),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}

class _BoutiqueKycCard extends StatelessWidget {
  final BoutiqueVerificationItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _BoutiqueKycCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = item.status == KycStatus.pending;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPending ? AppTheme.accentColor.withValues(alpha: 0.5) : AppTheme.borderSubtle,
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
                Expanded(
                  child: Text(
                    item.shopName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending ? AppTheme.accentLight : AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPending ? AppTheme.accentColor : AppTheme.successColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Owner: ${item.ownerName} • ${item.ownerPhone}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              'Email: ${item.ownerEmail}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),

            const Divider(height: 20),

            // KYC Document & Address Details
            Row(
              children: [
                const Icon(Icons.badge_outlined, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text('GSTIN: ${item.gstin}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${item.address} (${item.cityZone})',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),

            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 16, color: AppTheme.errorColor),
                      label: const Text('Reject', style: TextStyle(color: AppTheme.errorColor)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve & Activate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
