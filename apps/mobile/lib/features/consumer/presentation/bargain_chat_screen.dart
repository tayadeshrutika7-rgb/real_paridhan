import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';
import '../domain/bargain_model.dart';
import 'bargain_controller.dart';

/// Consumer-facing bargain chat screen.
/// Shows the real-time negotiation thread and controls for accepting / re-offering.
class BargainChatScreen extends ConsumerStatefulWidget {
  final String bargainId;
  final bool isSellerView;

  const BargainChatScreen({
    super.key,
    required this.bargainId,
    this.isSellerView = false,
  });

  @override
  ConsumerState<BargainChatScreen> createState() => _BargainChatScreenState();
}

class _BargainChatScreenState extends ConsumerState<BargainChatScreen> {
  final _counterController = TextEditingController();
  bool _showCounterInput = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bargainProvider.notifier).openBargain(widget.bargainId);
    });
  }

  @override
  void dispose() {
    _counterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bargainState = ref.watch(bargainProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id ?? '';

    final bargain = bargainState.activeBargain;
    final messages = bargainState.messages;

    // Show snackbars for errors / success
    ref.listen<BargainState>(bargainProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red.shade700,
          ),
        );
        ref.read(bargainProvider.notifier).clearMessages();
      }
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green.shade700,
          ),
        );
        ref.read(bargainProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: bargain == null
            ? const Text('Bargaining')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bargain.productTitle ?? 'Product',
                    style: const TextStyle(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  _StatusChip(status: bargain.status),
                ],
              ),
        actions: [
          if (bargain != null && bargain.isActive)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Reject Bargain',
              onPressed: () => _confirmReject(context, bargain, currentUserId),
            ),
        ],
      ),
      body: bargainState.isLoading && bargain == null
          ? const Center(child: CircularProgressIndicator())
          : bargain == null
              ? const Center(child: Text('Bargain not found.'))
              : Column(
                  children: [
                    // Price summary bar
                    _PriceSummaryBar(bargain: bargain),

                    // Messages list
                    Expanded(
                      child: messages.isEmpty
                          ? const Center(
                              child: Text(
                                'No messages yet.',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                final isMe = msg.senderId == currentUserId;
                                return _MessageBubble(
                                  message: msg,
                                  isMe: isMe,
                                );
                              },
                            ),
                    ),

                    // Bottom action bar (only when bargain is active)
                    if (bargain.isActive)
                      _BottomActionBar(
                        bargain: bargain,
                        isSellerView: widget.isSellerView,
                        currentUserId: currentUserId,
                        showCounterInput: _showCounterInput,
                        counterController: _counterController,
                        onToggleCounter: () {
                          setState(() {
                            _showCounterInput = !_showCounterInput;
                          });
                        },
                        onSubmitCounter: () => _submitCounter(bargain, currentUserId),
                        onAccept: () => _acceptBargain(bargain, currentUserId),
                        isLoading: bargainState.isLoading,
                      ),

                    // Terminal state footer
                    if (bargain.isTerminal) _TerminalBanner(bargain: bargain),
                  ],
                ),
    );
  }

  Future<void> _submitCounter(Bargain bargain, String sellerId) async {
    final amount = double.tryParse(_counterController.text.trim());
    if (amount == null) return;

    await ref.read(bargainProvider.notifier).counterOffer(
          bargainId: bargain.id,
          sellerId: sellerId,
          counterAmount: amount,
          minBargainPrice: bargain.minBargainPrice,
        );
    _counterController.clear();
    setState(() => _showCounterInput = false);
  }

  Future<void> _acceptBargain(Bargain bargain, String actorId) async {
    // Decide which price to agree on
    double agreedPrice;
    if (widget.isSellerView) {
      // Seller accepts the consumer's latest offer
      agreedPrice = bargain.consumerOffer;
    } else {
      // Consumer accepts the seller's counter offer
      agreedPrice = bargain.counterOffer ?? bargain.consumerOffer;
    }

    await ref.read(bargainProvider.notifier).acceptBargain(
          bargainId: bargain.id,
          actorId: actorId,
          agreedPrice: agreedPrice,
        );
  }

  Future<void> _confirmReject(
      BuildContext context, Bargain bargain, String actorId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Bargain?'),
        content: const Text(
            'This will reject the current bargaining session. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(bargainProvider.notifier).rejectBargain(
            bargainId: bargain.id,
            actorId: actorId,
          );
      if (!mounted) return;
      if (context.mounted) {
        context.pop();
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  final BargainStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case BargainStatus.open:
        color = Colors.blue;
        label = '● Open';
        break;
      case BargainStatus.countered:
        color = Colors.orange;
        label = '● Counter Offered';
        break;
      case BargainStatus.accepted:
        color = Colors.green;
        label = '✓ Accepted';
        break;
      case BargainStatus.rejected:
        color = Colors.red;
        label = '✗ Rejected';
        break;
      case BargainStatus.expired:
        color = Colors.grey;
        label = '⏱ Expired';
        break;
    }
    return Text(
      label,
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
    );
  }
}

class _PriceSummaryBar extends StatelessWidget {
  final Bargain bargain;
  const _PriceSummaryBar({required this.bargain});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.primaryColor.withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _PriceItem(
              label: 'Listed', value: '₹${bargain.basePrice.toStringAsFixed(0)}'),
          const Icon(Icons.arrow_forward, size: 16, color: AppTheme.textSecondary),
          _PriceItem(
              label: 'Your Offer',
              value: '₹${bargain.consumerOffer.toStringAsFixed(0)}',
              highlight: true),
          if (bargain.counterOffer != null) ...[
            const Icon(Icons.arrow_forward,
                size: 16, color: AppTheme.textSecondary),
            _PriceItem(
              label: 'Counter',
              value: '₹${bargain.counterOffer!.toStringAsFixed(0)}',
              highlight: true,
              color: Colors.orange,
            ),
          ],
          if (bargain.agreedPrice != null) ...[
            const Icon(Icons.arrow_forward,
                size: 16, color: AppTheme.textSecondary),
            _PriceItem(
              label: 'Agreed',
              value: '₹${bargain.agreedPrice!.toStringAsFixed(0)}',
              highlight: true,
              color: Colors.green,
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? color;

  const _PriceItem({
    required this.label,
    required this.value,
    this.highlight = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color ?? (highlight ? AppTheme.primaryColor : AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final BargainMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isOfferType = message.messageType == BargainMessageType.offer ||
        message.messageType == BargainMessageType.counter;
    final isAccept = message.messageType == BargainMessageType.accept;
    final isReject = message.messageType == BargainMessageType.reject;

    Color bubbleColor;
    if (isAccept) {
      bubbleColor = Colors.green.shade100;
    } else if (isReject) {
      bubbleColor = Colors.red.shade100;
    } else if (isMe) {
      bubbleColor = AppTheme.primaryColor.withValues(alpha: 0.15);
    } else {
      bubbleColor = Colors.grey.shade100;
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isOfferType
              ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOfferType && message.offerAmount != null)
              Text(
                '₹${message.offerAmount!.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: message.messageType == BargainMessageType.counter
                      ? Colors.orange.shade700
                      : AppTheme.primaryColor,
                ),
              ),
            if (message.text != null)
              Text(
                message.text!,
                style: TextStyle(
                  fontSize: 13,
                  color: isAccept
                      ? Colors.green.shade800
                      : isReject
                          ? Colors.red.shade800
                          : AppTheme.textPrimary,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _BottomActionBar extends StatelessWidget {
  final Bargain bargain;
  final bool isSellerView;
  final String currentUserId;
  final bool showCounterInput;
  final TextEditingController counterController;
  final VoidCallback onToggleCounter;
  final VoidCallback onSubmitCounter;
  final VoidCallback onAccept;
  final bool isLoading;

  const _BottomActionBar({
    required this.bargain,
    required this.isSellerView,
    required this.currentUserId,
    required this.showCounterInput,
    required this.counterController,
    required this.onToggleCounter,
    required this.onSubmitCounter,
    required this.onAccept,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final canAccept = isSellerView
        ? bargain.status == BargainStatus.open
        : bargain.status == BargainStatus.countered;
    final canCounter = isSellerView && bargain.status == BargainStatus.open;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Counter input field
          if (showCounterInput) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: counterController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'Your counter amount (min ₹${bargain.minBargainPrice.toStringAsFixed(0)})',
                      prefixText: '₹ ',
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isLoading ? null : onSubmitCounter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(14),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Action buttons
          Row(
            children: [
              if (canCounter) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onToggleCounter,
                    icon: Icon(showCounterInput ? Icons.close : Icons.compare_arrows),
                    label: Text(showCounterInput ? 'Cancel' : 'Counter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (canAccept)
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onAccept,
                    icon: const Icon(Icons.handshake_outlined, color: Colors.white),
                    label: Text(
                      isSellerView
                          ? 'Accept ₹${bargain.consumerOffer.toStringAsFixed(0)}'
                          : 'Accept ₹${(bargain.counterOffer ?? bargain.consumerOffer).toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              if (!canAccept && !canCounter && !showCounterInput)
                Expanded(
                  child: Text(
                    isSellerView
                        ? 'Waiting for customer response...'
                        : 'Waiting for seller response...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TerminalBanner extends StatelessWidget {
  final Bargain bargain;
  const _TerminalBanner({required this.bargain});

  @override
  Widget build(BuildContext context) {
    Color color;
    String message;
    IconData icon;

    switch (bargain.status) {
      case BargainStatus.accepted:
        color = Colors.green.shade600;
        message = 'Deal at ₹${bargain.agreedPrice?.toStringAsFixed(0) ?? '—'} — Added to cart!';
        icon = Icons.check_circle_outline;
        break;
      case BargainStatus.rejected:
        color = Colors.red.shade600;
        message = 'This bargain was rejected.';
        icon = Icons.cancel_outlined;
        break;
      case BargainStatus.expired:
        color = Colors.grey.shade600;
        message = 'This bargain has expired.';
        icon = Icons.timer_off_outlined;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      color: color.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
