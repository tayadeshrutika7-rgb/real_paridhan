import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'seller_controller.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerState = ref.watch(sellerProvider);
    final products = sellerState.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory & Stock Management'),
      ),
      body: sellerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      const Text('No products in your catalog yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text('Add your first garment from the Seller Studio home.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, idx) {
                    final product = products[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Base: ₹${product.basePrice.toStringAsFixed(2)} • Floor: ₹${product.minBargainPrice.toStringAsFixed(2)}',
                                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: product.totalStock > 0
                                        ? AppTheme.successColor.withValues(alpha: 0.1)
                                        : AppTheme.errorColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${product.totalStock} in stock',
                                    style: TextStyle(
                                      color: product.totalStock > 0 ? AppTheme.successColor : AppTheme.errorColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text('Variant Stock Units:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                            const SizedBox(height: 8),

                            ...product.variants.map((variant) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        variant.size,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentColor, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        variant.color,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                                          onPressed: variant.stockQty > 0
                                              ? () {
                                                  ref.read(sellerProvider.notifier).updateStock(variant.id, variant.stockQty - 1);
                                                }
                                              : null,
                                        ),
                                        SizedBox(
                                          width: 32,
                                          child: Text(
                                            '${variant.stockQty}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.primaryColor),
                                          onPressed: () {
                                            ref.read(sellerProvider.notifier).updateStock(variant.id, variant.stockQty + 1);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
