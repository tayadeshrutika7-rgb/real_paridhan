import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';
import '../../seller/domain/product_model.dart';
import '../../seller/domain/variant_model.dart';
import '../data/consumer_repository.dart';
import '../domain/review_model.dart';
import 'cart_controller.dart';
import 'bargain_controller.dart';
import 'review_controller.dart';
import 'widgets/rating_star_bar.dart';
import 'widgets/product_rating_sheet.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  ProductModel? _product;
  VariantModel? _selectedVariant;
  String? _selectedImageUrl;
  bool _isLoading = true;
  final int _selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final repo = ConsumerRepository();
    final p = await repo.getProductDetails(widget.productId);
    if (mounted) {
      setState(() {
        _product = p;
        _selectedVariant = p?.variants.isNotEmpty == true ? p!.variants.first : null;
        _selectedImageUrl = _selectedVariant?.imageUrls.isNotEmpty == true
            ? _selectedVariant!.imageUrls.first
            : p?.primaryImageUrl;
        _isLoading = false;
      });

      // Load reviews & check user purchase eligibility
      ref.read(reviewProvider.notifier).loadProductReviews(widget.productId);
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(reviewProvider.notifier).checkPurchaseEligibility(
          userId: user.id,
          productId: widget.productId,
        );
      }
    }
  }

  void _handleAddToCart() {
    if (_product == null || _selectedVariant == null) return;

    final authState = ref.read(authProvider);
    if (authState.isGuest) {
      _showLoginPrompt('Sign in to add items to your shopping bag.');
      return;
    }

    ref.read(cartProvider.notifier).addItem(
      product: _product!,
      variant: _selectedVariant!,
      quantity: _selectedQuantity,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${_product!.title} (${_selectedVariant!.size})" to Bag'),
        backgroundColor: AppTheme.successColor,
        action: SnackBarAction(
          label: 'View Bag',
          textColor: Colors.white,
          onPressed: () => context.push('/cart'),
        ),
      ),
    );
  }

  void _handleBargain() {
    final authState = ref.read(authProvider);
    if (authState.isGuest) {
      _showLoginPrompt('Sign in to bargain directly with local boutiques.');
      return;
    }

    if (_product == null || _selectedVariant == null) return;

    final product = _product!;
    final variant = _selectedVariant!;
    final variantPrice = variant.effectivePrice(product.basePrice);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BargainOfferSheet(
        product: product,
        variant: variant,
        consumerId: authState.user!.id,
        sellerId: product.sellerId,
        onSubmit: (offerAmount) async {
          Navigator.pop(context);
          final bargainId = await ref
              .read(bargainProvider.notifier)
              .initiateBargain(
                consumerId: authState.user!.id,
                sellerId: product.sellerId,
                productId: product.id,
                variantId: variant.id,
                offerAmount: offerAmount,
                basePrice: variantPrice,
                minBargainPrice: product.minBargainPrice > 0 ? product.minBargainPrice : (variantPrice * 0.7),
              );
          if (bargainId != null && mounted) {
            context.push('/bargain/$bargainId?seller=false');
          }
        },
      ),
    );
  }

  void _showLoginPrompt(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/login');
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Product not found')),
      );
    }

    final product = _product!;
    final variant = _selectedVariant;
    final currentPrice = variant?.effectivePrice(product.basePrice) ?? product.basePrice;
    final originalPrice = (currentPrice * 1.35).roundToDouble();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth >= 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          product.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: AppTheme.textPrimary),
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktopOrTablet ? 24 : 16,
              vertical: isDesktopOrTablet ? 24 : 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktopOrTablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Product Image Gallery
                      Expanded(
                        flex: 5,
                        child: _buildImageGallery(product, variant),
                      ),
                      const SizedBox(width: 36),
                      // Right Column: Product Details & Purchase Actions
                      Expanded(
                        flex: 6,
                        child: _buildProductDetailsPanel(
                          product,
                          variant,
                          currentPrice,
                          originalPrice,
                          includeInlineActions: true,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildImageGallery(product, variant),
                  const SizedBox(height: 16),
                  _buildProductDetailsPanel(
                    product,
                    variant,
                    currentPrice,
                    originalPrice,
                    includeInlineActions: false,
                  ),
                ],
                const SizedBox(height: 24),
                _buildReviewsSection(product),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: isDesktopOrTablet
          ? null
          : _buildBottomActionBar(product, variant),
    );
  }

  Widget _buildImageGallery(ProductModel product, VariantModel? variant) {
    final List<String> allImages = [
      if (variant?.imageUrls.isNotEmpty == true) ...variant!.imageUrls,
      for (final v in product.variants) ...v.imageUrls,
      if (product.primaryImageUrl.isNotEmpty) product.primaryImageUrl,
    ].where((url) => url.isNotEmpty).toSet().toList();

    final currentDisplayImage = (_selectedImageUrl != null && allImages.contains(_selectedImageUrl))
        ? _selectedImageUrl!
        : (allImages.isNotEmpty ? allImages.first : product.primaryImageUrl);

    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Main Preview Image
          Container(
            height: 440,
            width: double.infinity,
            color: const Color(0xFFFCFDFD),
            child: Stack(
              children: [
                Center(
                  child: _buildGarmentImageWidget(currentDisplayImage, fit: BoxFit.contain),
                ),
                // Hyperlocal Tag Badge
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified_outlined, size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          '100% Authentic Handloom',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (allImages.length > 1)
                  Positioned(
                    bottom: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${allImages.indexOf(currentDisplayImage) + 1} / ${allImages.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Multi-Image Thumbnails
          if (allImages.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: allImages.map((img) {
                    final isSelected = img == currentDisplayImage;
                    return InkWell(
                      onTap: () => setState(() => _selectedImageUrl = img),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE5E7EB),
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildGarmentImageWidget(img, fit: BoxFit.cover),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGarmentImageWidget(String url, {BoxFit fit = BoxFit.contain}) {
    if (url.startsWith('data:image')) {
      try {
        final base64Data = url.split(',').last;
        return Image.memory(
          base64Decode(base64Data),
          fit: fit,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.checkroom, size: 80, color: AppTheme.textMuted),
          ),
        );
      } catch (_) {}
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(Icons.checkroom, size: 80, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _buildProductDetailsPanel(
    ProductModel product,
    VariantModel? variant,
    double currentPrice,
    double originalPrice, {
    required bool includeInlineActions,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price and Bargain Tag Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹${currentPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${originalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 15,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
              if (product.bargainEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD1D8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.diamond_outlined, size: 14, color: AppTheme.primaryColor),
                      SizedBox(width: 5),
                      Text(
                        'Bargaining Available',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Product Title
          Text(
            product.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),

          // Shop / Boutique Link
          InkWell(
            onTap: () => context.push('/shop/${product.shopId}'),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_rounded, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    product.shopName ?? 'Johari Royal Heritage Boutique',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.primaryColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Rating Preview Bar
          Consumer(
            builder: (context, ref, child) {
              final reviewState = ref.watch(reviewProvider);
              final reviews = reviewState.reviewsByProduct[product.id] ?? [];
              final summary = reviewState.summariesByProduct[product.id] ?? ProductRatingSummary.fromReviews(reviews);
              final effectiveRating = summary.totalReviews > 0 ? summary.averageRating : product.avgRating;
              final effectiveCount = summary.totalReviews > 0 ? summary.totalReviews : (reviews.isNotEmpty ? reviews.length : 3);

              return Row(
                children: [
                  RatingStarBar(
                    rating: effectiveRating,
                    starSize: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${effectiveRating.toStringAsFixed(1)} ($effectiveCount verified ratings)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          const Divider(color: Color(0xFFF3F4F6), thickness: 1.2),
          const SizedBox(height: 14),

          // Select Size Section
          const Text(
            'Select Size',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Size Chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: product.variants.map((v) {
              final isSelected = v.id == _selectedVariant?.id;
              final isOutOfStock = v.stockQty <= 0;
              final sizeLabel = '${v.size} (${v.color})';

              return InkWell(
                onTap: isOutOfStock
                    ? null
                    : () {
                        setState(() => _selectedVariant = v);
                      },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : (isOutOfStock ? Colors.grey.shade100 : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (isOutOfStock ? Colors.grey.shade300 : const Color(0xFF111827)),
                      width: isSelected ? 1.5 : 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        sizeLabel,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isOutOfStock ? Colors.grey : const Color(0xFF111827)),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                          decoration: isOutOfStock ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // In Stock Status
          if (variant != null)
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Text(
                  variant.stockQty > 0
                      ? '${variant.stockQty} in stock near you'
                      : 'Out of stock',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // Inline Action Buttons (when displayed on desktop/tablet)
          if (includeInlineActions) ...[
            Row(
              children: [
                if (product.bargainEnabled) ...[
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _handleBargain,
                        icon: const Icon(Icons.local_offer_outlined, size: 18, color: AppTheme.primaryColor),
                        label: const Text(
                          'Bargain',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  flex: product.bargainEnabled ? 2 : 1,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: variant?.stockQty != null && variant!.stockQty > 0
                          ? _handleAddToCart
                          : null,
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.white),
                      label: const Text(
                        'Add to Bag',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Boutique Highlights & Delivery Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Row(
                  children: const [
                    Icon(Icons.electric_moped_outlined, size: 18, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hyperlocal Same-Day Dispatch (45-90 min delivery)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.store_mall_directory_outlined, size: 18, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Direct from Verified Jaipur Boutique Artisan',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (product.description != null && product.description!.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Product Description',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              product.description!,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsSection(ProductModel product) {
    final reviewState = ref.watch(reviewProvider);
    final reviews = reviewState.reviewsByProduct[product.id] ?? [];
    final summary = reviewState.summariesByProduct[product.id] ?? ProductRatingSummary.fromReviews(reviews);

    final authState = ref.watch(authProvider);
    final user = authState.user;
    final key = user != null ? '${user.id}-${product.id}' : '';
    final purchasedOrderId = reviewState.purchasedOrderIds[key];
    final userReview = reviewState.userReviews[key];
    final canRate = user != null && purchasedOrderId != null;

    final effectiveAvgRating = summary.totalReviews > 0 ? summary.averageRating : product.avgRating;
    final effectiveTotalReviews = summary.totalReviews > 0 ? summary.totalReviews : (reviews.isNotEmpty ? reviews.length : 3);

    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Customer Ratings & Reviews',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified, size: 14, color: AppTheme.successColor),
                    SizedBox(width: 4),
                    Text(
                      '100% Verified Buyers',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Rating Score Breakdown Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Score Box
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      effectiveAvgRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RatingStarBar(
                      rating: effectiveAvgRating,
                      starSize: 18,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$effectiveTotalReviews verified ratings',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                // Star Distribution Bars (5 down to 1)
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((star) {
                      final count = summary.starDistribution[star] ?? 0;
                      final pct = summary.totalReviews > 0 ? (count / summary.totalReviews) : (star == 5 ? 0.75 : (star == 4 ? 0.25 : 0.0));
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.5),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                '$star ★',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 7,
                                  backgroundColor: const Color(0xFFE5E7EB),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    star >= 4
                                        ? const Color(0xFFF59E0B)
                                        : (star == 3 ? const Color(0xFFFBBF24) : Colors.grey.shade400),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 24,
                              child: Text(
                                '${(pct * 100).toInt()}%',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Rating CTA Box (Enforcing "only the purchased product can be rated by the person")
          if (canRate) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.successColor.withValues(alpha: 0.15),
                    child: const Icon(Icons.rate_review_outlined, color: AppTheme.successColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userReview != null ? 'You have rated this purchase' : 'You purchased this product',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userReview != null
                              ? 'Your rating: ${userReview.rating} ★ ("${userReview.comment ?? "No comment"}")'
                              : 'Share your feedback on quality, sizing & fabric with other shoppers.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => ProductRatingSheet.show(
                      context,
                      orderId: purchasedOrderId!,
                      productId: product.id,
                      productTitle: product.title,
                      shopName: product.shopName,
                      imageUrl: product.primaryImageUrl,
                      shopId: product.shopId,
                      initialReview: userReview,
                    ),
                    icon: Icon(userReview != null ? Icons.edit_note : Icons.star_outline, size: 16),
                    label: Text(userReview != null ? 'Edit Review' : 'Rate (1-5★)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (user != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.lock_outline, size: 18, color: Color(0xFF6B7280)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Verified Purchase Required: Only customers who bought this garment can submit a 1 to 5 star rating.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Sign in to verify your purchase history and leave a verified product review.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Reviews List
          if (reviews.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.reviews_outlined, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text(
                      'No reviews yet for this product',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Be the first verified customer to purchase and rate this artisan creation!',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Text(
              'Verified Buyer Reviews (${reviews.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            ...reviews.map((r) => _buildReviewCard(r)),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : 'V',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    review.reviewerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified, size: 11, color: AppTheme.successColor),
                        SizedBox(width: 3),
                        Text(
                          'Verified Buyer',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                dateFormat.format(review.createdAt),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RatingStarBar(
            rating: review.rating.toDouble(),
            starSize: 14,
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(ProductModel product, VariantModel? variant) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Bargain Button (Left)
            if (product.bargainEnabled) ...[
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _handleBargain,
                    icon: const Icon(Icons.local_offer_outlined, size: 18, color: AppTheme.primaryColor),
                    label: const Text(
                      'Bargain',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],

            // Add to Bag Button (Right)
            Expanded(
              flex: product.bargainEnabled ? 2 : 1,
              child: SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: variant?.stockQty != null && variant!.stockQty > 0
                      ? _handleAddToCart
                      : null,
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.white),
                  label: const Text(
                    'Add to Bag',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
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
}

// ---------------------------------------------------------------------------
// Bargain Offer Sheet — modal for consumer to enter their offer
// ---------------------------------------------------------------------------

class _BargainOfferSheet extends StatefulWidget {
  final ProductModel product;
  final VariantModel variant;
  final String consumerId;
  final String sellerId;
  final void Function(double offerAmount) onSubmit;

  const _BargainOfferSheet({
    required this.product,
    required this.variant,
    required this.consumerId,
    required this.sellerId,
    required this.onSubmit,
  });

  @override
  State<_BargainOfferSheet> createState() => _BargainOfferSheetState();
}

class _BargainOfferSheetState extends State<_BargainOfferSheet> {
  final _controller = TextEditingController();
  String? _error;

  double get _variantPrice =>
      widget.variant.effectivePrice(widget.product.basePrice);

  double get _minPrice => widget.product.minBargainPrice > 0
      ? widget.product.minBargainPrice
      : _variantPrice * 0.7;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final val = double.tryParse(_controller.text.trim());
    if (val == null || val <= 0) {
      setState(() => _error = 'Enter a valid price.');
      return;
    }
    if (val < _minPrice) {
      setState(() =>
          _error = 'Minimum acceptable price is ₹${_minPrice.toStringAsFixed(0)}');
      return;
    }
    if (val >= _variantPrice) {
      setState(() => _error = 'Offer must be lower than the current price.');
      return;
    }
    widget.onSubmit(val);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Make a Bargain Offer',
                  style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Negotiate directly with ${widget.product.shopName ?? "the seller"}. Offers within 30% of base price are typically reviewed faster.',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Current Price Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Original Base Price:'),
                Text(
                  '₹${_variantPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Offer Input
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Your Offer Amount (₹)',
              hintText: 'e.g. ${(_variantPrice * 0.85).toStringAsFixed(0)}',
              errorText: _error,
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Floor price limit: ₹${_minPrice.toStringAsFixed(0)}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Send Offer to Seller'),
            ),
          ),
        ],
      ),
    );
  }
}
