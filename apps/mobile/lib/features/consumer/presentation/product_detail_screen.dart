import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_state.dart';
import '../../seller/domain/product_model.dart';
import '../../seller/domain/variant_model.dart';
import '../data/consumer_repository.dart';
import 'cart_controller.dart';
import 'bargain_controller.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  ProductModel? _product;
  VariantModel? _selectedVariant;
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
        _isLoading = false;
      });
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

    return Scaffold(
      appBar: AppBar(
        title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primary Image Gallery
            Container(
              height: 380,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: Image.network(
                variant?.imageUrls.isNotEmpty == true
                    ? variant!.imageUrls.first
                    : product.primaryImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.checkroom, size: 80, color: AppTheme.textMuted),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and Bargain Tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${currentPrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (product.bargainEnabled)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.handshake_outlined, size: 14, color: AppTheme.accentColor),
                              SizedBox(width: 4),
                              Text(
                                'Bargaining Available',
                                style: TextStyle(
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),

                  if (product.shopName != null) ...[
                    InkWell(
                      onTap: () => context.push('/shop/${product.shopId}'),
                      child: Row(
                        children: [
                          const Icon(Icons.store, size: 18, color: AppTheme.primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            product.shopName!,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(),
                  const SizedBox(height: 12),

                  // Size & Variant Selector
                  Text('Select Size', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.variants.map((v) {
                      final isSelected = v.id == _selectedVariant?.id;
                      final isOutOfStock = v.stockQty <= 0;

                      return ChoiceChip(
                        label: Text('${v.size} (${v.color})'),
                        selected: isSelected,
                        onSelected: isOutOfStock
                            ? null
                            : (selected) {
                                if (selected) {
                                  setState(() => _selectedVariant = v);
                                }
                              },
                        backgroundColor: isOutOfStock ? Colors.grey.shade200 : Colors.white,
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isOutOfStock ? Colors.grey : AppTheme.textPrimary),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          decoration: isOutOfStock ? TextDecoration.lineThrough : null,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Stock Status
                  if (variant != null)
                    Row(
                      children: [
                        Icon(
                          variant.stockQty > 0 ? Icons.check_circle_outline : Icons.cancel_outlined,
                          size: 16,
                          color: variant.stockQty > 0 ? AppTheme.successColor : AppTheme.errorColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          variant.stockQty > 0 ? '${variant.stockQty} in stock near you' : 'Out of Stock',
                          style: TextStyle(
                            color: variant.stockQty > 0 ? AppTheme.successColor : AppTheme.errorColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Product Description
                  Text('Description', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    product.description?.isNotEmpty == true ? product.description! : 'No description provided.',
                    style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (product.bargainEnabled) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleBargain,
                    icon: const Icon(Icons.handshake_outlined, color: AppTheme.accentColor),
                    label: const Text('Bargain', style: TextStyle(color: AppTheme.accentColor)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.accentColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: variant?.stockQty != null && variant!.stockQty > 0
                      ? _handleAddToCart
                      : null,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Add to Bag'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
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
      setState(() => _error = 'Your offer should be lower than the listed price.');
      return;
    }
    setState(() => _error = null);
    widget.onSubmit(val);
  }

  @override
  Widget build(BuildContext context) {
    final savings = _variantPrice - _minPrice;
    final maxDiscount =
        (savings / _variantPrice * 100).toStringAsFixed(0);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Icon(Icons.handshake_outlined, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Make an Offer',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.product.title} - ${widget.variant.size} ${widget.variant.color}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Listed Price',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    Text(
                      '₹${_variantPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.lineThrough,
                          color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward, size: 18, color: AppTheme.textSecondary),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Your Best Range',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    Text(
                      'Up to $maxDiscount% off',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: 'Your Offer Amount',
              prefixText: '₹ ',
              errorText: _error,
              filled: true,
              fillColor: AppTheme.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Minimum: ₹${_minPrice.toStringAsFixed(0)} - Seller may accept or counter your offer.',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send_outlined, color: Colors.white),
              label: const Text('Send Offer',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
