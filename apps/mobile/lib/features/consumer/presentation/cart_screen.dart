import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';
import '../domain/cart_item_model.dart';
import 'cart_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isGuest = authState.isGuest || authState.user == null || (authState.user?.id.startsWith('guest') ?? true);
    final cartState = ref.watch(cartProvider);
    final items = isGuest ? <CartItemModel>[] : cartState.items;

    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping Bag (${isGuest ? 0 : cartState.totalItems})'),
      ),
      body: isGuest
          ? _buildGuestLockedState(context)
          : cartState.isLoading
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
                                        child: item.imageUrl.isNotEmpty
                                            ? Image.network(
                                                item.imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const Icon(Icons.checkroom, color: AppTheme.textMuted),
                                              )
                                            : const Icon(Icons.checkroom, color: AppTheme.textMuted),
                                      ),
                                    ),
                                  const SizedBox(width: 12),

                                  // Details & Stepper
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.productTitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                                              tooltip: 'Remove from Bag',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () async {
                                                await ref.read(cartProvider.notifier).removeItem(item.id);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Removed "${item.productTitle}" from bag'),
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
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
                                                Row(
                                                  children: [
                                                    Text(
                                                      '₹${item.effectivePrice.toStringAsFixed(0)}',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        color: item.hasBargainPrice ? Colors.green.shade700 : AppTheme.primaryColor,
                                                      ),
                                                    ),
                                                    if (item.hasBargainPrice) ...[
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '₹${item.unitPrice.toStringAsFixed(0)}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: AppTheme.textSecondary,
                                                          decoration: TextDecoration.lineThrough,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                if (item.hasBargainPrice)
                                                  Container(
                                                    margin: const EdgeInsets.only(top: 2),
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.shade50,
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: Colors.green.shade200),
                                                    ),
                                                    child: Text(
                                                      '🏷️ Bargain Accepted (Save ₹${((item.unitPrice - item.effectivePrice) * item.quantity).toStringAsFixed(0)})',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.green.shade800,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),

                                            // Stepper
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    item.quantity <= 1 ? Icons.delete_outline : Icons.remove_circle_outline,
                                                    size: 20,
                                                    color: item.quantity <= 1 ? Colors.red.shade400 : null,
                                                  ),
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
                                const Text('Estimated Local Delivery (Amravati)', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                Text('Free', style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Proceed to Checkout'),
                                onPressed: () => context.push('/checkout'),
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

  Widget _buildGuestLockedState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sign In to Access Your Bag',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Guest users cannot add items or checkout. Please sign in to your Paridhan account to add items, bargain, and place orders.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text(
                    'Sign In to Account',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
