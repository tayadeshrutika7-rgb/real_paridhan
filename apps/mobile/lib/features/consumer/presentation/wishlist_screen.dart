import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';
import '../domain/wishlist_item_model.dart';
import 'wishlist_controller.dart';
import 'cart_controller.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  String _filter = 'all'; // 'all', 'bargainable', 'in_stock'

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isGuest = authState.isGuest || authState.user == null || (authState.user?.id.startsWith('guest') ?? true);
    final wishlistState = ref.watch(wishlistProvider);
    final cartState = ref.watch(cartProvider);
    final items = isGuest ? <WishlistItemModel>[] : wishlistState.items;

    final filteredItems = items.where((item) {
      if (_filter == 'bargainable') return item.bargainEnabled;
      if (_filter == 'in_stock') return item.stockQty > 0;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Wishlist',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${items.length} ${items.length == 1 ? 'item' : 'items'} saved for discounts',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                tooltip: 'Shopping Bag',
                onPressed: () => context.push('/cart'),
              ),
              if (cartState.totalItems > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cartState.totalItems}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isGuest
          ? _buildGuestLockedState(context)
          : wishlistState.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : items.isEmpty
                  ? _buildEmptyState(context)
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: RefreshIndicator(
                      color: AppTheme.primaryColor,
                      onRefresh: () => ref.read(wishlistProvider.notifier).loadWishlist(),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        children: [
                          // 1. Discount Tracker Savings Banner
                          _buildDiscountSummaryBanner(context, wishlistState),

                          const SizedBox(height: 14),

                          // 2. Filter chips
                          _buildFilterRow(items),

                          const SizedBox(height: 14),

                          // 3. Wishlist Cards
                          if (filteredItems.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                  child: Text(
                                    'No items found for "$_filter" filter.',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                  ),
                              ),
                            )
                          else
                            ...filteredItems.map((item) => _buildWishlistItemCard(context, item)),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildDiscountSummaryBanner(BuildContext context, WishlistState state) {
    final totalSavings = state.totalSavingsPotential;
    final bargainCount = state.items.where((i) => i.bargainEnabled).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.percent_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discount & Price Drop Tracker',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF881337),
                      ),
                    ),
                    Text(
                      'Items you want to purchase when prices drop or deal matches',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9F1239)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '₹${totalSavings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Text('Total MRP Savings', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  ],
                ),
                Container(height: 24, width: 1, color: Colors.grey.shade300),
                Column(
                  children: [
                    Text(
                      '$bargainCount Items',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    const Text('Direct Bargain Ready', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(List<WishlistItemModel> items) {
    final bargainCount = items.where((i) => i.bargainEnabled).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All Items (${items.length})', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('🏷️ Bargainable ($bargainCount)', 'bargainable'),
          const SizedBox(width: 8),
          _buildFilterChip('In Stock', 'in_stock'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String key) {
    final isSelected = _filter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? AppTheme.primaryColor : const Color(0xFFE5E7EB)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (selected) {
        if (selected) setState(() => _filter = key);
      },
    );
  }

  Widget _buildWishlistItemCard(BuildContext context, WishlistItemModel item) {
    final discountPercent = item.discountPercentage.round();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image with discount badge
                GestureDetector(
                  onTap: () => context.push('/product/${item.productId}'),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.imageUrl,
                          width: 100,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            width: 100,
                            height: 120,
                            color: AppTheme.primaryLight,
                            alignment: Alignment.center,
                            child: const Icon(Icons.checkroom_rounded, color: AppTheme.primaryColor, size: 32),
                          ),
                        ),
                      ),
                      if (discountPercent > 0)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$discountPercent% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.push('/product/${item.productId}'),
                              child: Text(
                                item.productTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // Remove button
                          IconButton(
                            icon: const Icon(Icons.favorite, color: AppTheme.primaryColor, size: 20),
                            tooltip: 'Remove from Wishlist',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              await ref.read(wishlistProvider.notifier).removeFromWishlist(item.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Item removed from wishlist'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () {
                                        ref.read(wishlistProvider.notifier).addToWishlist(item);
                                      },
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Boutique Name
                      Row(
                        children: [
                          const Icon(Icons.storefront_outlined, size: 13, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.shopName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Size & Color badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Size: ${item.size} · Color: ${item.color}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563), fontWeight: FontWeight.w600),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Price Row
                      Row(
                        children: [
                          Text(
                            '₹${item.currentPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (item.originalPrice > item.currentPrice) ...[
                            Text(
                              '₹${item.originalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Save ₹${item.potentialSavings.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Waiting for discount tag & Bargaining Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(
                top: BorderSide(color: Color(0xFFF3F4F6)),
                bottom: BorderSide(color: Color(0xFFF3F4F6)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_outlined, size: 14, color: AppTheme.secondaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.targetDiscountNote,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.stockQty > 0)
                  const Text(
                    'In Stock',
                    style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                  )
                else
                  const Text(
                    'Out of Stock',
                    style: TextStyle(fontSize: 11, color: AppTheme.errorColor, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),

          // Action Buttons: Move to Bag & Bargain Now
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                if (item.bargainEnabled) ...[
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Navigate to product page to start bargain
                          context.push('/product/${item.productId}');
                        },
                        icon: const Icon(Icons.local_offer_outlined, size: 16, color: AppTheme.primaryColor),
                        label: const Text(
                          'Bargain Price',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryColor, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: item.stockQty > 0
                          ? () async {
                              final success = await ref.read(wishlistProvider.notifier).moveToCart(item);
                              if (context.mounted && success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Moved "${item.productTitle}" to your Shopping Bag!'),
                                    backgroundColor: Colors.green,
                                    action: SnackBarAction(
                                      label: 'View Bag',
                                      textColor: Colors.white,
                                      onPressed: () => context.push('/cart'),
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      icon: const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.white),
                      label: const Text(
                        'Move to Bag',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Wishlist is Empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Found ethnic clothes you love but waiting for the right discount or price drop? Tap the wishlist heart icon on any product to save it here and track offers!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.explore_outlined, color: Colors.white),
              label: const Text('Explore Ethnic Garments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestLockedState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 44,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sign In to Access Wishlist',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Guest users cannot add or view items in the wishlist. Please sign in to your Paridhan account to save your favourite ethnic outfits and track deals.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
              label: const Text('Sign In to Paridhan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
