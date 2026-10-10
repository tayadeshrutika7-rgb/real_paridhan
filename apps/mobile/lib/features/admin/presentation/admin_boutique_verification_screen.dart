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
    final boutiques = adminState.metrics.allBoutiques.isNotEmpty
        ? adminState.metrics.allBoutiques
        : adminState.metrics.pendingBoutiques;

    final filtered = _selectedFilter == null
        ? boutiques
        : boutiques.where((b) => b.status == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boutique KYC Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminProvider.notifier).loadDashboard(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Pending Review (${boutiques.where((b) => b.status == KycStatus.pending).length})',
                    isSelected: _selectedFilter == KycStatus.pending,
                    onTap: () => setState(() => _selectedFilter = KycStatus.pending),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Approved (${boutiques.where((b) => b.status == KycStatus.approved).length})',
                    isSelected: _selectedFilter == KycStatus.approved,
                    onTap: () => setState(() => _selectedFilter = KycStatus.approved),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Correction Needed',
                    isSelected: _selectedFilter == KycStatus.correctionRequested,
                    onTap: () => setState(() => _selectedFilter = KycStatus.correctionRequested),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'All (${boutiques.length})',
                    isSelected: _selectedFilter == null,
                    onTap: () => setState(() => _selectedFilter = null),
                  ),
                ],
              ),
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
                      final isUnmasked = adminState.unmaskedKycShops.contains(item.id);

                      return _BoutiqueKycCard(
                        item: item,
                        isUnmasked: isUnmasked,
                        onToggleUnmask: () {
                          ref.read(adminProvider.notifier).toggleUnmaskKyc(item.id);
                        },
                        onApprove: () => _showApproveDialog(context, item),
                        onReject: () => _showRejectDialog(context, item),
                        onRequestCorrection: () => _showCorrectionDialog(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context, BoutiqueVerificationItem item) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Approve KYC: ${item.shopName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Approving will immediately mark this shop as verified and make all its active products visible on customer discovery radar.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Internal Verification Notes (Optional)',
                hintText: 'e.g. Physical store verified at Johari Bazaar.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(adminProvider.notifier).approveBoutique(
                    item.id,
                    notes: notesController.text.trim(),
                  );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Approved "${item.shopName}". Boutique is now live!'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text('Approve & Activate'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, BoutiqueVerificationItem item) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject KYC: ${item.shopName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please specify the exact rejection reason so the seller can address discrepancies.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                hintText: 'e.g. GSTIN mismatch with trade name on certificate.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a rejection reason.')),
                );
                return;
              }
              Navigator.pop(ctx);
              final success = await ref.read(adminProvider.notifier).rejectBoutique(
                    item.id,
                    reason: reasonController.text.trim(),
                  );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Rejected KYC for "${item.shopName}". Feedback logged.'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Reject KYC'),
          ),
        ],
      ),
    );
  }

  void _showCorrectionDialog(BuildContext context, BoutiqueVerificationItem item) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Request Correction: ${item.shopName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notify the seller to upload clearer document copies or update bank details without completely rejecting.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Correction Request Instructions *',
                hintText: 'e.g. Please re-upload a clear scan of the canceled cheque.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
            onPressed: () async {
              if (notesController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter correction instructions.')),
                );
                return;
              }
              Navigator.pop(ctx);
              final success = await ref.read(adminProvider.notifier).requestKycCorrection(
                    item.id,
                    notes: notesController.text.trim(),
                  );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Correction requested for "${item.shopName}".'),
                    backgroundColor: AppTheme.accentColor,
                  ),
                );
              }
            },
            child: const Text('Send Request'),
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
  final bool isUnmasked;
  final VoidCallback onToggleUnmask;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRequestCorrection;

  const _BoutiqueKycCard({
    required this.item,
    required this.isUnmasked,
    required this.onToggleUnmask,
    required this.onApprove,
    required this.onReject,
    required this.onRequestCorrection,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = item.status == KycStatus.pending || item.status == KycStatus.correctionRequested;

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
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.shopName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          if (item.businessType != null && item.businessType!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.businessType!.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Owner: ${item.ownerName} • Phone: ${item.ownerPhone}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.status == KycStatus.approved
                        ? const Color(0xFFDCFCE7)
                        : (item.status == KycStatus.rejected
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFFEF3C7)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: item.status == KycStatus.approved
                          ? const Color(0xFF166534)
                          : (item.status == KycStatus.rejected
                              ? const Color(0xFF991B1B)
                              : const Color(0xFF92400E)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Email: ${item.ownerEmail} • Submitted: ${item.submittedAt.day}/${item.submittedAt.month}/${item.submittedAt.year}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),

            const Divider(height: 20),

            // Business & Tax Identifiers
            Row(
              children: [
                const Icon(Icons.badge_outlined, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text('GSTIN: ${item.gstin}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'monospace')),
                const Spacer(),
                Text('Trade License: ${item.businessRegNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${item.address}${item.landmark != null && item.landmark!.isNotEmpty ? " (Near ${item.landmark})" : ""}, ${item.cityZone}${item.pincode != null && item.pincode!.isNotEmpty ? " - ${item.pincode}" : ""}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Financial & Government Identity Card (Unmasked Full Details - No Stars)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.security, size: 16, color: AppTheme.primaryColor),
                          SizedBox(width: 6),
                          Text(
                            'Financial & Identity Documents (Protected)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: onToggleUnmask,
                        icon: Icon(isUnmasked ? Icons.visibility_off : Icons.visibility, size: 14),
                        label: Text(isUnmasked ? 'Mask' : 'Reveal', style: const TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'PAN: ${item.panNumber}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Aadhaar: ${item.aadhaarNumber}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bank: ${item.bankName}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'A/C No: ${item.bankAccountNumber}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: AppTheme.primaryColor),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'IFSC: ${item.bankIfsc}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  if (item.bankAccountName != null && item.bankAccountName!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Account Holder: ${item.bankAccountName}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ],
              ),
            ),

            // Attached KYC Documents List
            if (item.submittedDocuments.isNotEmpty || (item.licenseDocumentUrl != null && item.licenseDocumentUrl!.isNotEmpty)) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.file_present_rounded, size: 16, color: AppTheme.successColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Attached KYC Proofs (${item.submittedDocuments.isNotEmpty ? item.submittedDocuments.length : 1} Document${(item.submittedDocuments.length > 1) ? "s" : ""} on file)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final docUrl = item.submittedDocuments.isNotEmpty
                            ? item.submittedDocuments.first
                            : (item.licenseDocumentUrl ?? '');
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('KYC Document: ${item.shopName}'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Document Reference:\n$docUrl', style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 12),
                                if (docUrl.startsWith('http'))
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      docUrl,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Text('Document image preview unavailable.'),
                                    ),
                                  ),
                              ],
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                            ],
                          ),
                        );
                      },
                      child: const Text('View Proof', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    ),
                  ],
                ),
              ),
            ],

            if (item.rejectionReason != null && item.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.errorColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Rejection Feedback: ${item.rejectionReason}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Reject', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onRequestCorrection,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentColor,
                        side: const BorderSide(color: AppTheme.accentColor),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Correction', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
