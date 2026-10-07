import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../advertising/domain/advertisement_model.dart';
import '../../advertising/presentation/advertisement_controller.dart';

class AdminAdvertisementsScreen extends ConsumerStatefulWidget {
  const AdminAdvertisementsScreen({super.key});

  @override
  ConsumerState<AdminAdvertisementsScreen> createState() => _AdminAdvertisementsScreenState();
}

class _AdminAdvertisementsScreenState extends ConsumerState<AdminAdvertisementsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showApprovalDialog(BuildContext context, AdvertisementModel ad) {
    final emailController = TextEditingController(
      text: 'Dear ${ad.shopName},\n\n'
          'Congratulations! Your advertisement campaign "${ad.title}" has been APPROVED by the Paridhan Admin Team.\n\n'
          'Campaign Summary:\n'
          '• Title: ${ad.title}\n'
          '• Placement: ${_getPlacementTitle(ad.placement)}\n'
          '• Target: ${ad.targetCategory ?? ad.targetId ?? ad.targetType}\n'
          '• Duration: ${ad.durationDays} Days (Active from today)\n'
          '• Budget Paid: ₹${ad.budget.toStringAsFixed(2)} (Razorpay Ref: ${ad.paymentId ?? "VERIFIED"})\n'
          '• Status: ACTIVE & LIVE ON PARIDHAN APP\n\n'
          'Thank you for partnering with Paridhan Jaipur.\n\n'
          'Best Regards,\n'
          'Paridhan Platform Team',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppTheme.successColor),
              SizedBox(width: 8),
              Text('Approve Advertisement'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Approving this request will immediately activate the ad banner in the ${_getPlacementTitle(ad.placement)}.',
                    style: TextStyle(color: Colors.grey[800], fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mark_email_read_outlined, size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'SMTP Email will be sent to: ${ad.sellerEmail}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Email Notification Message:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await ref.read(advertisementProvider.notifier).approveAdRequest(
                      ad.id,
                      sendEmail: true,
                      customEmailBody: emailController.text.trim(),
                    );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Advertisement approved & live on Customer App! SMTP email dispatched to seller.'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Approve & Send SMTP Email'),
            ),
          ],
        );
      },
    );
  }

  void _showRejectionDialog(BuildContext context, AdvertisementModel ad) {
    final reasonController = TextEditingController(text: 'Banner resolution is too low or promotional text violates guidelines.');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Reject Ad Request'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter the reason for rejection to notify the seller:'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Rejection Reason / Feedback',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a rejection reason.')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final success = await ref.read(advertisementProvider.notifier).rejectAdRequest(
                      ad.id,
                      reason: reasonController.text.trim(),
                      sendEmail: true,
                    );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ad request rejected and rejection email sent to seller.'),
                    ),
                  );
                }
              },
              child: const Text('Reject & Send Email'),
            ),
          ],
        );
      },
    );
  }

  void _showEmailComposerDialog(BuildContext context, AdvertisementModel ad) {
    final subjectController = TextEditingController(text: 'Inquiry regarding your campaign: "${ad.title}"');
    final bodyController = TextEditingController(
      text: 'Dear ${ad.shopName},\n\n'
          'We are reviewing your advertisement request for "${ad.title}".\n\n'
          'Please reply with any updated banner creative or date preferences.\n\n'
          'Paridhan Operations Team',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.email, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text('Contact Seller (${ad.shopName})'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: TextEditingController(text: ad.sellerEmail),
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Email (SMTP)',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      prefixIcon: Icon(Icons.subject),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Message Body',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await ref.read(advertisementProvider.notifier).sendCustomSmtpEmail(
                      toEmail: ad.sellerEmail.isNotEmpty ? ad.sellerEmail : 'seller@boutique.com',
                      toName: ad.shopName,
                      subject: subjectController.text.trim(),
                      message: bodyController.text.trim(),
                    );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('SMTP Email delivered to ${ad.sellerEmail}!'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Send SMTP Email'),
            ),
          ],
        );
      },
    );
  }

  static String _getPlacementTitle(String placement) {
    switch (placement) {
      case 'home_hero':
        return '🌟 Home Hero Carousel';
      case 'category_header':
        return '🏷️ Category Header Banner';
      case 'featured_feed':
      case 'boutique_spotlight':
        return '💎 Boutique Spotlight Feed';
      default:
        return 'Promotional Banner';
    }
  }

  @override
  Widget build(BuildContext context) {
    final adState = ref.watch(advertisementProvider);
    final allAds = adState.adminAds;

    final filteredAds = _filter == 'all'
        ? allAds
        : allAds.where((ad) => ad.effectiveStatus == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Advertisements & Promotions'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(
              icon: const Icon(Icons.campaign_outlined),
              text: 'Ad Requests (${allAds.length})',
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: 'SMTP Email Logs (${adState.emailLogs.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Ad Requests
          Column(
            children: [
              // Filter Chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All (${allAds.length})', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Pending (${allAds.where((a) => a.effectiveStatus == "pending").length})',
                        'pending',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Approved & Live (${allAds.where((a) => a.effectiveStatus == "approved" || a.effectiveStatus == "live").length})',
                        'approved',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Rejected (${allAds.where((a) => a.effectiveStatus == "rejected").length})',
                        'rejected',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Paused / Expired (${allAds.where((a) => a.effectiveStatus == "paused" || a.effectiveStatus == "completed").length})',
                        'completed',
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderSubtle),

              Expanded(
                child: filteredAds.isEmpty
                    ? const Center(
                        child: Text('No advertisement requests found in this category'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredAds.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (ctx, i) {
                          final ad = filteredAds[i];
                          return _buildAdCard(context, ad);
                        },
                      ),
              ),
            ],
          ),

          // Tab 2: SMTP Email Delivery Logs
          _buildSmtpLogsList(adState.emailLogs),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : AppTheme.textPrimary,
      ),
      selectedColor: AppTheme.primaryColor,
      backgroundColor: const Color(0xFFF3F4F6),
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Widget _buildAdCard(BuildContext context, AdvertisementModel ad) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Shop info & status badge
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.accentLight,
                  child: Icon(Icons.storefront, size: 18, color: AppTheme.accentColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ad.shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        'Email: ${ad.sellerEmail} • Phone: ${ad.sellerPhone}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                _buildStatusPill(ad),
              ],
            ),
            const SizedBox(height: 14),

            // Banner Image & Ad Content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    ad.bannerImageUrl,
                    width: 120,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 120,
                      height: 80,
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(Icons.broken_image, color: AppTheme.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ad.tag,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(ad.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                        ad.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Placement, Duration, Budget, and Razorpay Tags
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildMetaChip(Icons.view_carousel, _getPlacementTitle(ad.placement)),
                _buildMetaChip(Icons.calendar_today, '${ad.durationDays} Days Duration'),
                _buildMetaChip(Icons.currency_rupee, 'Budget: ₹${ad.budget.toStringAsFixed(0)}'),
                if (ad.targetCategory != null)
                  _buildMetaChip(Icons.category, 'Category: ${ad.targetCategory}'),
                if (ad.badgeText != null)
                  _buildMetaChip(Icons.local_offer, 'Badge: ${ad.badgeText!.replaceAll("\n", " ")}'),
                _buildMetaChip(
                  Icons.verified,
                  'Razorpay: ${ad.paymentId ?? "PAID"}',
                  highlight: true,
                ),
              ],
            ),

            if (ad.adminNotes != null && ad.adminNotes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ad.isRejected ? const Color(0xFFFEF2F2) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ad.isRejected ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Icon(
                      ad.isRejected ? Icons.warning_amber_rounded : Icons.admin_panel_settings_outlined,
                      size: 16,
                      color: ad.isRejected ? AppTheme.primaryColor : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Review Notes / Feedback: ${ad.adminNotes}',
                        style: TextStyle(
                          fontSize: 12,
                          color: ad.isRejected ? const Color(0xFF991B1B) : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1, color: AppTheme.borderSubtle),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                // Contact via SMTP email button
                OutlinedButton.icon(
                  onPressed: () => _showEmailComposerDialog(context, ad),
                  icon: const Icon(Icons.email_outlined, size: 16),
                  label: const Text('Contact via SMTP', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const Spacer(),

                if (ad.isPending) ...[
                  OutlinedButton.icon(
                    onPressed: () => _showRejectionDialog(context, ad),
                    icon: const Icon(Icons.close, size: 16, color: AppTheme.primaryColor),
                    label: const Text('Reject', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => _showApprovalDialog(context, ad),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept & Make Live', style: TextStyle(fontSize: 12)),
                  ),
                ] else if (ad.isApproved && !ad.isExpired) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_tethering, color: AppTheme.successColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Live until ${dateFormat.format(ad.expiresAt ?? DateTime.now().add(const Duration(days: 15)))}',
                          style: const TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: highlight ? const Color(0xFF166534) : AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: highlight ? const Color(0xFF166534) : AppTheme.textSecondary,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(AdvertisementModel ad) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    final status = ad.effectiveStatus;

    switch (status) {
      case 'approved':
      case 'live':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        label = 'Approved & Live';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        label = 'Rejected';
        icon = Icons.cancel;
        break;
      case 'paused':
        bg = const Color(0xFFE5E7EB);
        fg = const Color(0xFF374151);
        label = 'Paused';
        icon = Icons.pause;
        break;
      case 'completed':
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
        label = 'Expired';
        icon = Icons.done_all;
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = 'Pending Review';
        icon = Icons.hourglass_top;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSmtpLogsList(List emailLogs) {
    if (emailLogs.isEmpty) {
      return const Center(
        child: Text('No SMTP email logs recorded yet'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: emailLogs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final log = emailLogs[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mark_email_read, color: AppTheme.successColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'To: ${log.toName} (${log.toEmail})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('DELIVERED (250 OK)', style: TextStyle(fontSize: 10, color: Color(0xFF166534), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Subject: ${log.subject}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  log.bodyText,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Server: ${log.smtpServer}', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    Text(
                      'Sent: ${log.sentAt.toString().substring(0, 16)}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
