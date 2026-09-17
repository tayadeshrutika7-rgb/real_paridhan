import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'cart_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final items = cartState.items;

    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping Bag (${cartState.totalItems})'),
      ),
      body: cartState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 72, color: AppTheme.textMuted),
                      const SizedBox(height: 16),
                      Text('Your shopping bag is empty', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text('Discover authentic garments from local boutiques near you.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Start Exploring'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final item = items[idx];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 80,
                                      height: 90,
                                      color: Colors.grey.shade100,
                                      child: Image.network(
                                        item.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.checkroom, color: AppTheme.textMuted),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Details & Stepper
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Size: ${item.size} • Color: ${item.color}',
                                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'From: ${item.shopName}',
                                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                        ),
                                        const SizedBox(height: 8),

                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '₹${item.effectivePrice.toStringAsFixed(0)}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryColor),
                                                ),
                                                if (item.hasBargainPrice)
                                                  Text(
                                                    'Bargain Price (₹${item.unitPrice.toStringAsFixed(0)})',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: AppTheme.accentColor,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                              ],
                                            ),

                                            // Stepper
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                                  onPressed: () {
                                                    ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity - 1);
                                                  },
                                                ),
                                                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                IconButton(
                                                  icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.primaryColor),
                                                  onPressed: () {
                                                    ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity + 1);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Order Summary Bottom Sheet
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal', style: TextStyle(fontSize: 14)),
                                Text('₹${cartState.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Estimated Local Delivery', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                Text('Free', style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text(
                                  '₹${cartState.subtotal.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => context.push('/checkout'),
                                child: const Text('Proceed to Checkout'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
