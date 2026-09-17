import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';
import '../../consumer/domain/order_model.dart';
import '../../consumer/presentation/order_controller.dart';

class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(orderProvider.notifier).loadSellerOrders(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final orders = orderState.sellerOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Operations & Fulfillment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final user = ref.read(authProvider).user;
              if (user != null) {
                ref.read(orderProvider.notifier).loadSellerOrders(user.id);
              }
            },
          ),
        ],
      ),
      body: orderState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 56, color: AppTheme.textMuted),
                      SizedBox(height: 16),
                      Text('No customer orders yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 6),
                      Text('When customers place orders, they will appear here.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    final user = ref.read(authProvider).user;
                    if (user != null) {
                      await ref.read(orderProvider.notifier).loadSellerOrders(user.id);
                    }
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, idx) {
                      final order = orders[idx];
                      return _SellerOrderCard(order: order);
                    },
                  ),
                ),
    );
  }
}

class _SellerOrderCard extends ConsumerWidget {
  final OrderModel order;
  const _SellerOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    final canConfirm = order.status == OrderStatus.pending;
    final canReadyPickup = order.status == OrderStatus.confirmed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID & Payment Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(dateFormat.format(order.createdAt), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.paymentMethod == PaymentMethod.razorpay
                        ? AppTheme.successColor.withValues(alpha: 0.12)
                        : AppTheme.warningColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.paymentMethod == PaymentMethod.razorpay ? 'PAID (Razorpay)' : 'COD (Cash to Collect)',
                    style: TextStyle(
                      color: order.paymentMethod == PaymentMethod.razorpay ? AppTheme.successColor : AppTheme.warningColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Items breakdown
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          item.imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.checkroom, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('Size: ${item.size} • Color: ${item.color} • Qty: ${item.quantity}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      Text('₹${item.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                )),

            const Divider(height: 20),

            // Customer details
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${order.deliveryAddress.fullName} • ${order.deliveryAddress.formattedAddress}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Actions
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Payout (90%): ₹${(order.subtotal * 0.9).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
                  ),
                ),
                if (canConfirm)
                  ElevatedButton(
                    onPressed: () {
                      ref.read(orderProvider.notifier).updateSellerOrderStatus(order.id, OrderStatus.confirmed);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order confirmed! Start packing the garment.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Confirm Order'),
                  )
                else if (canReadyPickup)
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(orderProvider.notifier).updateSellerOrderStatus(order.id, OrderStatus.readyForPickup);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marked ready for delivery partner pickup!')),
                      );
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Ready for Pickup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(order.statusLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
