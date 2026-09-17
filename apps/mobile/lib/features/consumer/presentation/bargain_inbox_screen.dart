import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';
import '../domain/bargain_model.dart';
import 'bargain_controller.dart';

/// Bargain inbox — shows all active bargains for consumer or seller.
class BargainInboxScreen extends ConsumerStatefulWidget {
  final bool isSellerView;

  const BargainInboxScreen({super.key, this.isSellerView = false});

  @override
  ConsumerState<BargainInboxScreen> createState() => _BargainInboxScreenState();
}

class _BargainInboxScreenState extends ConsumerState<BargainInboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) return;

      if (widget.isSellerView) {
        ref.read(bargainProvider.notifier).loadSellerBargains(userId);
      } else {
        ref.read(bargainProvider.notifier).loadConsumerBargains(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bargainState = ref.watch(bargainProvider);
    final bargains = widget.isSellerView
        ? bargainState.sellerBargains
        : bargainState.consumerBargains;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(
          widget.isSellerView ? 'Bargain Requests' : 'My Bargains',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final userId = ref.read(authProvider).user?.id;
              if (userId == null) return;
              if (widget.isSellerView) {
                ref.read(bargainProvider.notifier).loadSellerBargains(userId);
              } else {
                ref.read(bargainProvider.notifier).loadConsumerBargains(userId);
              }
            },
          ),
        ],
      ),
      body: bargainState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : bargains.isEmpty
              ? _EmptyState(isSellerView: widget.isSellerView)
              : RefreshIndicator(
                  onRefresh: () async {
                    final userId = ref.read(authProvider).user?.id;
                    if (userId == null) return;
                    if (widget.isSellerView) {
                      await ref.read(bargainProvider.notifier).loadSellerBargains(userId);
                    } else {
                      await ref.read(bargainProvider.notifier).loadConsumerBargains(userId);
                    }
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: bargains.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final bargain = bargains[index];
                      return _BargainCard(
                        bargain: bargain,
                        isSellerView: widget.isSellerView,
                        onTap: () => context.push(
                          '/bargain/${bargain.id}?seller=${widget.isSellerView}',
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _BargainCard extends StatelessWidget {
  final Bargain bargain;
  final bool isSellerView;
  final VoidCallback onTap;

  const _BargainCard({
    required this.bargain,
    required this.isSellerView,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(bargain.status);
    final savings = bargain.basePrice - bargain.consumerOffer;
    final savingsPct = savings / bargain.basePrice * 100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Status bar at top
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _statusLabel(bargain.status),
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _timeAgo(bargain.updatedAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Product image placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      image: bargain.productImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(bargain.productImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: bargain.productImageUrl == null
                        ? const Icon(Icons.checkroom,
                            color: AppTheme.primaryColor, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bargain.productTitle ?? 'Product',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '₹${bargain.basePrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '₹${bargain.consumerOffer.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${savingsPct.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (bargain.counterOffer != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Counter: ₹${bargain.counterOffer!.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(BargainStatus status) {
    switch (status) {
      case BargainStatus.open:
        return Colors.blue;
      case BargainStatus.countered:
        return Colors.orange;
      case BargainStatus.accepted:
        return Colors.green;
      case BargainStatus.rejected:
        return Colors.red;
      case BargainStatus.expired:
        return Colors.grey;
    }
  }

  String _statusLabel(BargainStatus status) {
    switch (status) {
      case BargainStatus.open:
        return 'Offer Sent';
      case BargainStatus.countered:
        return 'Counter Offer Received';
      case BargainStatus.accepted:
        return 'Deal Accepted';
      case BargainStatus.rejected:
        return 'Rejected';
      case BargainStatus.expired:
        return 'Expired';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSellerView;
  const _EmptyState({required this.isSellerView});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.handshake_outlined,
              size: 56,
              color: AppTheme.primaryColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSellerView
                ? 'No bargain requests yet'
                : 'No active bargains',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSellerView
                ? 'When customers make offers on your products,\nthey will appear here.'
                : 'Browse products and tap "Make an Offer"\nto start negotiating.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          if (!isSellerView) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.explore, color: Colors.white),
              label: const Text('Explore Products',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
