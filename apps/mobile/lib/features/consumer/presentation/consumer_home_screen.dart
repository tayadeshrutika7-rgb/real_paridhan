import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';
import 'consumer_controller.dart';
import 'cart_controller.dart';

class ConsumerHomeScreen extends ConsumerWidget {
  const ConsumerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final consumerState = ref.watch(consumerProvider);
    final cartState = ref.watch(cartProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppTheme.accentColor),
                const SizedBox(width: 4),
                Text(
                  consumerState.locationLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 18),
              ],
            ),
            Text(
              'Hyperlocal Delivery within 5-10 km',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
            ),
          ],
        ),
        actions: [
          // My Bargains
          IconButton(
            tooltip: 'My Bargains',
            icon: const Icon(Icons.forum_outlined),
            onPressed: () => context.push('/bargains?seller=false'),
          ),
          // Cart Icon with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () => context.push('/cart'),
              ),
              if (cartState.totalItems > 0)
                Positioned(
                  right: 6,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cartState.totalItems}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          if (authState.isGuest)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => context.push('/login'),
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Sign In'),
              ),
            )
          else ...[
            PopupMenuButton<String>(
              icon: CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  user?.fullName?.isNotEmpty == true ? user!.fullName![0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              onSelected: (val) {
                if (val == 'orders') {
                  context.push('/orders');
                } else if (val == 'logout') {
                  ref.read(authProvider.notifier).signOut();
                } else if (val == 'terms') {
                  context.push('/legal/terms');
                } else if (val == 'privacy') {
                  context.push('/legal/privacy');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(user?.fullName ?? user?.email ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'orders', child: Text('My Orders')),
                const PopupMenuItem(value: 'terms', child: Text('Terms of Service')),
                const PopupMenuItem(value: 'privacy', child: Text('Privacy Policy')),
                const PopupMenuItem(value: 'logout', child: Text('Sign Out', style: TextStyle(color: AppTheme.errorColor))),
              ],
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(consumerProvider.notifier).loadDiscovery(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: InkWell(
                  onTap: () => context.push('/search'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppTheme.textSecondary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Search Kurtas, Sarees, Handlooms...',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Local', style: TextStyle(color: AppTheme.accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Hero Banner: Wear Local. Support Local.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E2640), Color(0xFF2F3B66)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'HYPERLOCAL DEALS',
                          style: TextStyle(color: AppTheme.secondaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Bargain Directly with Local Boutiques',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Support neighbourhood creators with verified same-day local delivery.',
                        style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // PostGIS Geospatial Nearby Boutiques Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nearby Boutiques (PostGIS)', style: Theme.of(context).textTheme.headlineSmall),
                    Text(
                      '${consumerState.nearbyShops.length} Found',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: consumerState.nearbyShops.length,
                  itemBuilder: (context, idx) {
                    final shop = consumerState.nearbyShops[idx];
                    return InkWell(
                      onTap: () => context.push('/shop/${shop.id}'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 220,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 80,
                                width: double.infinity,
                                color: AppTheme.primaryLight,
                                child: shop.bannerUrl != null
                                    ? Image.network(shop.bannerUrl!, fit: BoxFit.cover)
                                    : const Icon(Icons.store, color: Colors.white54, size: 36),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shop.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.near_me, size: 12, color: AppTheme.accentColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          shop.formattedDistance,
                                          style: const TextStyle(
                                            color: AppTheme.accentColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.star, size: 12, color: AppTheme.secondaryColor),
                                        const SizedBox(width: 2),
                                        Text('${shop.avgRating}', style: const TextStyle(fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Categories Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Shop by Category', style: Theme.of(context).textTheme.headlineSmall),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: const [
                    _CategoryChip(icon: Icons.woman, label: 'Women Ethnic'),
                    _CategoryChip(icon: Icons.man, label: 'Men Apparel'),
                    _CategoryChip(icon: Icons.child_care, label: 'Kids Wear'),
                    _CategoryChip(icon: Icons.checkroom, label: 'Kurtas & Sarees'),
                    _CategoryChip(icon: Icons.snowshoeing, label: 'Footwear'),
                    _CategoryChip(icon: Icons.watch, label: 'Accessories'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Featured Garments Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Popular Near You', style: Theme.of(context).textTheme.headlineSmall),
                    TextButton(
                      onPressed: () => context.push('/search'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.68,
                ),
                itemCount: consumerState.featuredProducts.length,
                itemBuilder: (context, idx) {
                  final product = consumerState.featuredProducts[idx];
                  return InkWell(
                    onTap: () => context.push('/product/${product.id}'),
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              color: Colors.grey.shade100,
                              width: double.infinity,
                              child: Image.network(
                                product.primaryImageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '₹${product.basePrice.toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                                    ),
                                    if (product.bargainEnabled)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentLight,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('Bargain', style: TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CategoryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 85,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
