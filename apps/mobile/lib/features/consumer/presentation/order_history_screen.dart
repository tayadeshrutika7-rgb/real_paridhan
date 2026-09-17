import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';
import '../domain/order_model.dart';
import 'order_controller.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(orderProvider.notifier).loadConsumerOrders(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final orders = orderState.orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: orderState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, size: 56, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No orders placed yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Explore verified local boutiques in your neighborhood',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Start Exploring'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    final user = ref.read(authProvider).user;
                    if (user != null) {
                      await ref.read(orderProvider.notifier).loadConsumerOrders(user.id);
                    }
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, idx) {
                      final order = orders[idx];
                      return _OrderCard(order: order);
                    },
                  ),
                ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final isDelivered = order.status == OrderStatus.delivered;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Order number & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(order.createdAt),
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDelivered
                        ? AppTheme.successColor.withValues(alpha: 0.12)
                        : AppTheme.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(
                      color: isDelivered ? AppTheme.successColor : AppTheme.accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Boutique Name
            Row(
              children: [
                const Icon(Icons.store, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  order.shopName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Item Previews
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          item.imageUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 36,
                            height: 36,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.checkroom, size: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${item.productTitle} (${item.size})',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'x${item.quantity}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 12),

            // Bottom Row: Total & Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Amount', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/order/${order.id}'),
                  icon: const Icon(Icons.track_changes, size: 16),
                  label: const Text('Track Order'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
