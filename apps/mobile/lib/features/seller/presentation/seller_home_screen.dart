import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';
import 'seller_controller.dart';

class SellerHomeScreen extends ConsumerWidget {
  const SellerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final sellerState = ref.watch(sellerProvider);
    final user = authState.user;
    final shop = sellerState.shop;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/seller/shop'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Card Header
            Card(
              color: AppTheme.primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.store, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop?.name ?? user?.fullName ?? 'Local Boutique',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: shop?.isVerified == true ? AppTheme.successColor : AppTheme.warningColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  shop?.isVerified == true ? 'Shop Verified' : 'KYC Pending Verification',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => context.push('/seller/shop'),
                                child: const Text(
                                  'Edit Profile',
                                  style: TextStyle(color: Colors.white70, fontSize: 12, decoration: TextDecoration.underline),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text('Today\'s Performance', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),

            Row(
              children: [
                const Expanded(
                  child: _StatCard(
                    title: 'Gross Sales',
                    value: '₹0.00',
                    icon: Icons.currency_rupee,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Active Products',
                    value: '${sellerState.products.length}',
                    icon: Icons.checkroom_outlined,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Pending Orders',
                    value: '0',
                    icon: Icons.shopping_bag_outlined,
                    color: AppTheme.primaryLight,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Pending Payout',
                    value: '₹0.00',
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Text('Catalog & Operations', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),

            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              leading: const CircleAvatar(
                backgroundColor: AppTheme.accentLight,
                child: Icon(Icons.add_photo_alternate, color: AppTheme.accentColor),
              ),
              title: const Text('Add New Garment / Product'),
              subtitle: const Text('With client-side image compression & bargaining floor price'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/seller/add-product'),
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.inventory_2_outlined, color: AppTheme.primaryColor),
              ),
              title: const Text('Inventory & Stock Units'),
              subtitle: const Text('Manage variant sizes, colors, and live counts'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/seller/inventory'),
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFEF3C7),
                child: Icon(Icons.forum_outlined, color: AppTheme.secondaryColor),
              ),
              title: const Text('Bargain Requests & Negotiations'),
              subtitle: const Text('Accept, reject, or counter buyer price offers'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/bargains?seller=true'),
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFDCFCE7),
                child: Icon(Icons.shopping_bag_outlined, color: AppTheme.successColor),
              ),
              title: const Text('Order Fulfillment & Packing Queue'),
              subtitle: const Text('Confirm orders and mark ready for partner pickup'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/seller/orders'),
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF3F4F6),
                child: Icon(Icons.account_balance, color: AppTheme.primaryColor),
              ),
              title: const Text('Razorpay Route Split Onboarding'),
              subtitle: const Text('Bank account linked for instant 90% payout splits'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Razorpay Route Sub-Merchant Account is active and linked.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
