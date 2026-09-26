import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';
import '../domain/nearby_shop.dart';
import 'consumer_controller.dart';
import 'cart_controller.dart';

class ConsumerHomeScreen extends ConsumerStatefulWidget {
  const ConsumerHomeScreen({super.key});

  @override
  ConsumerState<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends ConsumerState<ConsumerHomeScreen> {
  String _selectedCategory = 'All';
  int _selectedBottomNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final PageController _heroPageController = PageController();
  int _currentHeroPage = 0;
  Timer? _heroTimer;

  // Hero Banners Data matching real high fashion store aesthetics
  static const List<Map<String, dynamic>> _heroSlides = [
    {
      'tag': 'NEW COLLECTION',
      'titleLine1': 'Your ',
      'titleLine1Highlight': 'style.',
      'titleLine2': 'Your ',
      'titleLine2Highlight': 'local',
      'titleLine3': 'store.',
      'subtitle': 'Discover fashion from your favourite local shops in',
      'buttonText': 'Explore Collection',
      'badgeText': 'UP TO\n50%\nOFF',
      'imageUrl': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=1200&auto=format&fit=crop&q=80',
      'bgGradient': [Color(0xFFFDE8EC), Color(0xFFFBF0F2)],
    },
    {
      'tag': 'FESTIVE EDIT',
      'titleLine1': 'Real ',
      'titleLine1Highlight': 'Bargain.',
      'titleLine2': 'Direct ',
      'titleLine2Highlight': 'Sellers.',
      'titleLine3': '',
      'subtitle': 'Negotiate prices directly with boutique owners in real-time.',
      'buttonText': 'Start Bargaining',
      'badgeText': 'LIVE\nDEALS',
      'imageUrl': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=1200&auto=format&fit=crop&q=80',
      'bgGradient': [Color(0xFFFDF4E7), Color(0xFFFAF0E6)],
    },
    {
      'tag': 'HYPERLOCAL DISPATCH',
      'titleLine1': 'Fastest ',
      'titleLine1Highlight': 'Local',
      'titleLine2': 'Same Day ',
      'titleLine2Highlight': 'Drop.',
      'titleLine3': '',
      'subtitle': 'Support neighborhood artisan boutiques with verified local delivery.',
      'buttonText': 'Find Nearby',
      'badgeText': '5-10\nKM',
      'imageUrl': 'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=1200&auto=format&fit=crop&q=80',
      'bgGradient': [Color(0xFFEEF2FF), Color(0xFFF5F7FF)],
    },
  ];

  // Curated boutique dataset matching the user interface design
  static const List<Map<String, dynamic>> _curatedBoutiques = [
    {
      'id': 'boutique-01',
      'name': 'Fashion Point',
      'discount': '20% OFF',
      'rating': 4.5,
      'distance': '1.2 km',
      'tags': 'Women · Ethnic · Western',
      'isOpen': true,
      'imageUrl': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&auto=format&fit=crop&q=80',
      'category': 'Women',
    },
    {
      'id': 'boutique-02',
      'name': 'Style Hub',
      'discount': '15% OFF',
      'rating': 4.4,
      'distance': '1.8 km',
      'tags': 'Men · Women · Kids',
      'isOpen': true,
      'imageUrl': 'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=800&auto=format&fit=crop&q=80',
      'category': 'Men',
    },
    {
      'id': 'boutique-03',
      'name': 'Trendy Wear',
      'discount': '10% OFF',
      'rating': 4.3,
      'distance': '2.1 km',
      'tags': 'Western · Casual · Party',
      'isOpen': true,
      'imageUrl': 'https://images.unsplash.com/photo-1472851294608-062f824d29cc?w=800&auto=format&fit=crop&q=80',
      'category': 'Western',
    },
    {
      'id': 'boutique-04',
      'name': 'Sakhi Sarees',
      'discount': '25% OFF',
      'rating': 4.6,
      'distance': '1.5 km',
      'tags': 'Sarees · Ethnic · Dupatta',
      'isOpen': true,
      'imageUrl': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800&auto=format&fit=crop&q=80',
      'category': 'Ethnic',
    },
    {
      'id': 'boutique-05',
      'name': 'Urban Closet',
      'discount': '20% OFF',
      'rating': 4.2,
      'distance': '2.3 km',
      'tags': 'Men · Women · Streetwear',
      'isOpen': true,
      'imageUrl': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=800&auto=format&fit=crop&q=80',
      'category': 'Men',
    },
    {
      'id': 'boutique-06',
      'name': 'City Fashion',
      'discount': '20% OFF',
      'rating': 4.4,
      'distance': '2.8 km',
      'tags': 'Women · Kids · Ethnic',
      'isOpen': true,
      'imageUrl': 'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?w=800&auto=format&fit=crop&q=80',
      'category': 'Kids',
    },
    {
      'id': 'boutique-07',
      'name': 'Mojari & Jutti Palace',
      'discount': '30% OFF',
      'rating': 4.7,
      'distance': '1.1 km',
      'tags': 'Footwear · Juttis · Leather Mojari',
      'isOpen': true,
      'imageUrl': 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=800&auto=format&fit=crop&q=80',
      'category': 'Footwear',
    },
    {
      'id': 'boutique-08',
      'name': 'Royal Jaipur Jewels & Accessories',
      'discount': '15% OFF',
      'rating': 4.8,
      'distance': '0.9 km',
      'tags': 'Accessories · Kundan · Jewelry · Dupatta',
      'isOpen': true,
      'imageUrl': 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=800&auto=format&fit=crop&q=80',
      'category': 'Accessories',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startHeroAutoSlide();
  }

  void _startHeroAutoSlide() {
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_heroPageController.hasClients) {
        final nextPage = (_currentHeroPage + 1) % _heroSlides.length;
        _heroPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showLocationPicker(BuildContext context, String currentLabel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final locations = [
          {'name': 'Amravati City Center', 'lat': 20.9374, 'lng': 77.7796},
          {'name': 'Johari Bazaar, Jaipur', 'lat': 26.9124, 'lng': 75.7873},
          {'name': 'Bapu Bazaar, Jaipur', 'lat': 26.9200, 'lng': 75.8200},
          {'name': 'MI Road, Jaipur', 'lat': 26.9150, 'lng': 75.8050},
          {'name': 'Malviya Nagar, Jaipur', 'lat': 26.8500, 'lng': 75.8150},
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Delivery Location',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose your location to discover hyperlocal boutiques near you:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ...locations.map((loc) {
                  final isSelected = currentLabel.contains(loc['name'] as String) ||
                      (loc['name'] as String).contains(currentLabel);
                  return ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
                    ),
                    title: Text(
                      loc['name'] as String,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onTap: () {
                      ref.read(consumerProvider.notifier).updateLocation(
                            loc['lat'] as double,
                            loc['lng'] as double,
                            loc['name'] as String,
                          );
                      Navigator.pop(ctx);
                    },
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHelpModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paridhan Help & Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Have a query regarding your order, bargain, or delivery?', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(backgroundColor: AppTheme.primaryLight, child: Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor)),
                title: const Text('Live Support Chat'),
                subtitle: const Text('Connect with Paridhan Care instantly'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: AppTheme.primaryLight, child: Icon(Icons.description_outlined, color: AppTheme.primaryColor)),
                title: const Text('Terms of Service & Policies'),
                subtitle: const Text('Read buyer & seller guarantees'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/legal/terms');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final consumerState = ref.watch(consumerProvider);
    final cartState = ref.watch(cartProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 800;

    // Combine database PostGIS shops and curated boutique cards
    final List<Map<String, dynamic>> combinedStores = [];

    for (final shop in consumerState.nearbyShops) {
      combinedStores.add({
        'id': shop.id,
        'name': shop.name,
        'discount': '20% OFF',
        'rating': shop.avgRating > 0 ? shop.avgRating : 4.6,
        'distance': shop.formattedDistance,
        'tags': 'Ethnic · Traditional · Heritage',
        'isOpen': true,
        'imageUrl': shop.bannerUrl ?? 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800&auto=format&fit=crop&q=80',
        'category': 'Ethnic',
      });
    }

    for (final cb in _curatedBoutiques) {
      if (!combinedStores.any((s) => s['name'] == cb['name'])) {
        combinedStores.add(cb);
      }
    }

    // Filtered store list
    final displayedStores = combinedStores.where((store) {
      if (_selectedCategory == 'All' || _selectedCategory == 'More') return true;
      final cat = (store['category'] ?? '').toString().toLowerCase();
      final tags = (store['tags'] ?? '').toString().toLowerCase();
      final name = (store['name'] ?? '').toString().toLowerCase();
      final query = _selectedCategory.toLowerCase();

      if (query == 'women' || query == 'women ethnic') {
        return cat.contains('women') || tags.contains('women') || tags.contains('ethnic') || tags.contains('saree') || cat.contains('ethnic');
      }
      if (query == 'men') {
        return cat.contains('men') || tags.contains('men') || tags.contains('sherwani') || tags.contains('kurta');
      }
      if (query == 'kids') {
        return cat.contains('kids') || tags.contains('kids') || tags.contains('child');
      }
      if (query == 'western') {
        return cat.contains('western') || tags.contains('western') || tags.contains('party') || tags.contains('casual');
      }
      if (query == 'ethnic') {
        return cat.contains('ethnic') || tags.contains('ethnic') || tags.contains('saree') || tags.contains('traditional') || tags.contains('lehenga');
      }
      if (query == 'footwear') {
        return cat.contains('footwear') || tags.contains('footwear') || tags.contains('jutti') || tags.contains('mojari') || tags.contains('shoe');
      }
      if (query == 'accessories') {
        return cat.contains('accessories') || tags.contains('accessories') || tags.contains('jewel') || tags.contains('dupatta') || tags.contains('bag');
      }
      return cat.contains(query) || tags.contains(query) || name.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            _buildTopNavBar(context, authState, cartState, consumerState, isWideScreen),

            // Scrollable Content Body
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primaryColor,
                onRefresh: () => ref.read(consumerProvider.notifier).loadDiscovery(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mobile Search Bar (only visible when not wide screen)
                      if (!isWideScreen)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: _buildSearchBar(context),
                        ),

                      const SizedBox(height: 12),

                      // Hero Banner Carousel
                      _buildHeroBanner(context, consumerState, isWideScreen),

                      const SizedBox(height: 18),

                      // Shop by Category Section
                      _buildCategorySection(context),

                      const SizedBox(height: 18),

                      // Recommended for you / Nearby Boutiques (PostGIS) Section
                      _buildRecommendedSection(context, displayedStores, consumerState),

                      const SizedBox(height: 20),

                      // Popular Trending Garments Section
                      if (consumerState.featuredProducts.isNotEmpty)
                        _buildFeaturedProductsSection(context, consumerState),

                      const SizedBox(height: 90), // Space for floating bottom nav
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFloatingBottomNav(context, authState),
    );
  }

  Widget _buildTopNavBar(
    BuildContext context,
    AuthState authState,
    CartState cartState,
    ConsumerDiscoveryState consumerState,
    bool isWideScreen,
  ) {
    final user = authState.user;
    final locationName = consumerState.locationLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Brand Logo
          InkWell(
            onTap: () {
              setState(() => _selectedCategory = 'All');
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.checkroom_rounded,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Paridhan',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Your style. Your story.',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Location Selector Pill
          InkWell(
            onTap: () => _showLocationPicker(context, consumerState.locationLabel),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Deliver to',
                        style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                      Row(
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 130),
                            child: Text(
                              locationName.isEmpty ? 'Amravati' : locationName.split(',').first.trim(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.textSecondary),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Center Search Bar on Wide Screen
          if (isWideScreen) ...[
            const SizedBox(width: 16),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _buildSearchBar(context),
              ),
            ),
            const SizedBox(width: 16),
          ] else
            const Spacer(),

          // Right Menu Actions
          if (isWideScreen) ...[
            TextButton(
              onPressed: () => setState(() => _selectedCategory = 'Women Ethnic'),
              child: Text(
                'Women',
                style: TextStyle(
                  color: (_selectedCategory == 'Women' || _selectedCategory == 'Women Ethnic')
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimary,
                  fontWeight: (_selectedCategory == 'Women' || _selectedCategory == 'Women Ethnic')
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedCategory = 'Men'),
              child: Text(
                'Men',
                style: TextStyle(
                  color: _selectedCategory == 'Men' ? AppTheme.primaryColor : AppTheme.textPrimary,
                  fontWeight: _selectedCategory == 'Men' ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedCategory = 'Kids'),
              child: Text(
                'Kids',
                style: TextStyle(
                  color: _selectedCategory == 'Kids' ? AppTheme.primaryColor : AppTheme.textPrimary,
                  fontWeight: _selectedCategory == 'Kids' ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],

          // Wishlist Icon Button
          IconButton(
            tooltip: 'Wishlist',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF3F4F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.favorite_outline_rounded, size: 20, color: AppTheme.textPrimary),
            onPressed: () => context.push('/bargains?seller=false'),
          ),

          const SizedBox(width: 8),

          // Login or Account Profile
          if (authState.isGuest)
            OutlinedButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.person_outline_rounded, size: 18),
              label: const Text('Sign In'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )
          else
            PopupMenuButton<String>(
              tooltip: 'Account Menu',
              offset: const Offset(0, 45),
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  user?.fullName?.isNotEmpty == true ? user!.fullName![0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              onSelected: (val) {
                if (val == 'orders') {
                  context.push('/orders');
                } else if (val == 'bargains') {
                  context.push('/bargains?seller=false');
                } else if (val == 'terms') {
                  context.push('/legal/terms');
                } else if (val == 'privacy') {
                  context.push('/legal/privacy');
                } else if (val == 'logout') {
                  ref.read(authProvider.notifier).signOut();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    user?.fullName ?? user?.email ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'orders', child: Text('My Orders')),
                const PopupMenuItem(value: 'bargains', child: Text('My Bargains')),
                const PopupMenuItem(value: 'terms', child: Text('Terms of Service')),
                const PopupMenuItem(value: 'privacy', child: Text('Privacy Policy')),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Sign Out', style: TextStyle(color: AppTheme.errorColor)),
                ),
              ],
            ),

          const SizedBox(width: 8),

          // Shopping Bag / Cart Icon with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Shopping Cart',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.shopping_bag_outlined, size: 20, color: AppTheme.textPrimary),
                onPressed: () => context.push('/cart'),
              ),
              Positioned(
                right: 2,
                top: 2,
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
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (query) {
          if (query.trim().isNotEmpty) {
            context.push('/search?q=${Uri.encodeComponent(query.trim())}');
          }
        },
        decoration: InputDecoration(
          hintText: 'Search clothes, shops, brands...',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280), size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildHeroBanner(
    BuildContext context,
    ConsumerDiscoveryState consumerState,
    bool isWideScreen,
  ) {
    final cityName = consumerState.locationLabel.split(',').first.trim();
    final effectiveCity = cityName.isEmpty ? 'Amravati' : cityName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: isWideScreen ? 250 : 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            PageView.builder(
              controller: _heroPageController,
              onPageChanged: (idx) {
                setState(() => _currentHeroPage = idx);
              },
              itemCount: _heroSlides.length,
              itemBuilder: (context, index) {
                final slide = _heroSlides[index];
                final tag = slide['tag'] as String;
                final line1 = slide['titleLine1'] as String;
                final line1H = slide['titleLine1Highlight'] as String;
                final line2 = slide['titleLine2'] as String;
                final line2H = slide['titleLine2Highlight'] as String;
                final line3 = slide['titleLine3'] as String;
                final subtitle = '${slide['subtitle']} $effectiveCity.';
                final buttonText = slide['buttonText'] as String;
                final badgeText = slide['badgeText'] as String;
                final imageUrl = slide['imageUrl'] as String;
                final bgGradient = slide['bgGradient'] as List<Color>;

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: bgGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Left Content (Headline, Subtitle, CTA)
                      Expanded(
                        flex: isWideScreen ? 56 : 52,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWideScreen ? 22 : 14,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Tag Pill
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    tag,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.auto_awesome, size: 12, color: AppTheme.primaryColor),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // Big Headline
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: isWideScreen ? 25 : 19,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                    color: const Color(0xFF111827),
                                  ),
                                  children: [
                                    TextSpan(text: line1),
                                    TextSpan(
                                      text: line1H,
                                      style: const TextStyle(color: AppTheme.primaryColor),
                                    ),
                                    const TextSpan(text: '\n'),
                                    TextSpan(text: line2),
                                    TextSpan(
                                      text: line2H,
                                      style: const TextStyle(color: AppTheme.primaryColor),
                                    ),
                                    if (line3.isNotEmpty) ...[
                                      const TextSpan(text: '\n'),
                                      TextSpan(text: line3),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(height: 5),

                              // Subtitle
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isWideScreen ? 11 : 10,
                                  color: const Color(0xFF4B5563),
                                  height: 1.2,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Explore Collection Button
                              ElevatedButton(
                                onPressed: () => context.push('/search'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isWideScreen ? 16 : 10,
                                    vertical: isWideScreen ? 8 : 6,
                                  ),
                                  elevation: 2,
                                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  buttonText,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right Image with Floating Discount Badge
                      Expanded(
                        flex: isWideScreen ? 44 : 48,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                color: AppTheme.primaryLight,
                                child: const Icon(Icons.image_outlined, size: 36, color: AppTheme.primaryColor),
                              ),
                            ),
                            // Gradient shadow on left edge of photo
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    bgGradient[0],
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.25],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                            // Circular 50% OFF Badge
                            Positioned(
                              top: isWideScreen ? 24 : 14,
                              right: isWideScreen ? 16 : 8,
                              child: Container(
                                width: isWideScreen ? 56 : 46,
                                height: isWideScreen ? 56 : 46,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  badgeText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isWideScreen ? 9 : 8,
                                    fontWeight: FontWeight.w900,
                                    height: 1.15,
                                    letterSpacing: 0.5,
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
              },
            ),

            // Carousel Dots Indicator
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _heroSlides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentHeroPage == index ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentHeroPage == index
                          ? AppTheme.primaryColor
                          : AppTheme.primaryColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context) {
    final categories = [
      {'label': 'All', 'icon': Icons.auto_awesome_rounded},
      {'label': 'Women Ethnic', 'icon': Icons.favorite_border_rounded},
      {'label': 'Men', 'icon': Icons.checkroom_rounded},
      {'label': 'Kids', 'icon': Icons.star_border_rounded},
      {'label': 'Western', 'icon': Icons.dry_cleaning_rounded},
      {'label': 'Ethnic', 'icon': Icons.spa_outlined},
      {'label': 'Footwear', 'icon': Icons.roller_skating_outlined},
      {'label': 'Accessories', 'icon': Icons.watch_outlined},
      {'label': 'More', 'icon': Icons.grid_view_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Text(
                    'Shop by Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.auto_awesome, size: 15, color: AppTheme.primaryColor),
                ],
              ),
              InkWell(
                onTap: () => context.push('/search'),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final label = cat['label'] as String;
                final icon = cat['icon'] as IconData;
                final isSelected = _selectedCategory == label || (_selectedCategory == 'Women' && label == 'Women Ethnic');

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = label;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : const Color(0xFFE5E7EB),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 15,
                          color: isSelected ? AppTheme.primaryColor : const Color(0xFF4B5563),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppTheme.primaryColor : const Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection(
    BuildContext context,
    List<Map<String, dynamic>> displayedStores,
    ConsumerDiscoveryState consumerState,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text(
                        'Recommended for you',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.favorite_border_rounded, size: 15, color: AppTheme.primaryColor),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Text(
                        'Handpicked clothing stores just for you',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Nearby Boutiques (PostGIS)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.push('/search'),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal Store Cards Carousel
          SizedBox(
            height: 245,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displayedStores.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, idx) {
                final store = displayedStores[idx];
                final storeId = store['id'] as String;
                final name = store['name'] as String;
                final discount = store['discount'] as String;
                final rating = (store['rating'] as num).toDouble();
                final distance = store['distance'] as String;
                final tags = store['tags'] as String;
                final isOpen = store['isOpen'] as bool;
                final imageUrl = store['imageUrl'] as String;

                return _buildStoreCard(
                  context: context,
                  id: storeId,
                  name: name,
                  discount: discount,
                  rating: rating,
                  distance: distance,
                  tags: tags,
                  isOpen: isOpen,
                  imageUrl: imageUrl,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard({
    required BuildContext context,
    required String id,
    required String name,
    required String discount,
    required double rating,
    required String distance,
    required String tags,
    required bool isOpen,
    required String imageUrl,
  }) {
    return Container(
      width: 185,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Image with Discount Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: Image.network(
                  imageUrl,
                  height: 95,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 95,
                    color: AppTheme.primaryLight,
                    alignment: Alignment.center,
                    child: const Icon(Icons.storefront_rounded, size: 32, color: AppTheme.primaryColor),
                  ),
                ),
              ),
              // Discount Tag on Top Right
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    discount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Store Details
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Name
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),

                // Rating & Distance
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppTheme.secondaryColor),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('·', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Text(
                      distance,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Tags
                Text(
                  tags,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 3),

                // Open Status
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isOpen ? AppTheme.successColor : AppTheme.errorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isOpen ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // View Store Button
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: OutlinedButton(
                    onPressed: () => context.push('/shop/$id'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: Color(0xFFFFD1D8)),
                      backgroundColor: const Color(0xFFFFF7F8),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'View Store',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
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

  Widget _buildFeaturedProductsSection(BuildContext context, ConsumerDiscoveryState consumerState) {
    final filteredProducts = consumerState.featuredProducts.where((p) {
      if (_selectedCategory == 'All' || _selectedCategory == 'More') return true;
      final title = p.title.toLowerCase();
      final desc = (p.description ?? '').toLowerCase();
      final query = _selectedCategory.toLowerCase();

      if (query == 'women' || query == 'women ethnic') {
        return title.contains('anarkali') || title.contains('saree') || title.contains('lehenga') || title.contains('kurta') || title.contains('women') || desc.contains('women') || desc.contains('saree');
      }
      if (query == 'men') {
        return title.contains('sherwani') || title.contains('kurta') || title.contains('men') || title.contains('shirt') || desc.contains('men') || desc.contains('sherwani');
      }
      if (query == 'kids') {
        return title.contains('kids') || title.contains('boy') || title.contains('girl') || title.contains('child') || desc.contains('kids');
      }
      if (query == 'western') {
        return title.contains('western') || title.contains('dress') || title.contains('top') || title.contains('jeans') || title.contains('kurta') || desc.contains('western');
      }
      if (query == 'ethnic') {
        return title.contains('bandhani') || title.contains('anarkali') || title.contains('saree') || title.contains('lehenga') || title.contains('sherwani') || title.contains('ethnic') || title.contains('silk') || title.contains('handblock');
      }
      if (query == 'footwear') {
        return title.contains('jutti') || title.contains('mojari') || title.contains('footwear') || title.contains('shoe');
      }
      if (query == 'accessories') {
        return title.contains('accessories') || title.contains('jewelry') || title.contains('kundan') || title.contains('dupatta') || title.contains('jutti');
      }
      return title.contains(query) || desc.contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Text(
                    'Popular Trending Garments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.local_fire_department_rounded, size: 16, color: AppTheme.primaryColor),
                ],
              ),
              InkWell(
                onTap: () => context.push('/search'),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filteredProducts.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.checkroom_outlined, size: 36, color: AppTheme.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'No $_selectedCategory garments currently listed nearby.',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredProducts.length.clamp(0, 8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.68,
              ),
              itemBuilder: (context, idx) {
                final product = filteredProducts[idx];
                final originalPrice = (product.basePrice * 1.4).roundToDouble();

              return InkWell(
                onTap: () => context.push('/product/${product.id}'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image Container
                      Expanded(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                              child: Image.network(
                                product.primaryImageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  color: AppTheme.primaryLight,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.checkroom_rounded, color: AppTheme.primaryColor, size: 28),
                                ),
                              ),
                            ),
                            // Bargain Badge on Top-Left
                            if (product.bargainEnabled)
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.forum_outlined, size: 10, color: AppTheme.primaryColor),
                                      SizedBox(width: 3),
                                      Text(
                                        'Bargain',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Product Details
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Boutique Brand
                            const Text(
                              'LOCAL BOUTIQUE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),

                            // Product Title
                            Text(
                              product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Price Row (Offer + Original + Discount)
                            Row(
                              children: [
                                Text(
                                  '₹${product.basePrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '₹${originalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: AppTheme.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '30% OFF',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomNav(BuildContext context, AuthState authState) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isSelected: _selectedBottomNavIndex == 0,
            onTap: () => setState(() => _selectedBottomNavIndex = 0),
          ),
          _buildNavItem(
            icon: Icons.grid_view_rounded,
            label: 'Categories',
            isSelected: _selectedBottomNavIndex == 1,
            onTap: () {
              setState(() => _selectedBottomNavIndex = 1);
              context.push('/search');
            },
          ),
          _buildNavItem(
            icon: Icons.inventory_2_outlined,
            label: 'Orders',
            isSelected: _selectedBottomNavIndex == 2,
            onTap: () {
              setState(() => _selectedBottomNavIndex = 2);
              context.push('/orders');
            },
          ),
          _buildNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Account',
            isSelected: _selectedBottomNavIndex == 3,
            onTap: () {
              setState(() => _selectedBottomNavIndex = 3);
              if (authState.isGuest) {
                context.push('/login');
              } else {
                context.push('/orders');
              }
            },
          ),
          _buildNavItem(
            icon: Icons.help_outline_rounded,
            label: 'Help',
            isSelected: _selectedBottomNavIndex == 4,
            onTap: () => _showHelpModal(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: isSelected ? AppTheme.primaryColor : const Color(0xFF6B7280),
            ),
            if (isSelected) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
