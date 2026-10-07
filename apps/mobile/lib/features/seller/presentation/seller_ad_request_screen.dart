import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/device_image_picker.dart';
import '../../advertising/domain/advertisement_model.dart';
import '../../advertising/presentation/advertisement_controller.dart';
import 'seller_controller.dart';

class SellerAdRequestScreen extends ConsumerStatefulWidget {
  const SellerAdRequestScreen({super.key});

  @override
  ConsumerState<SellerAdRequestScreen> createState() => _SellerAdRequestScreenState();
}

class _SellerAdRequestScreenState extends ConsumerState<SellerAdRequestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // What to promote: 'shop', 'product', 'offer'
  String _promoteType = 'shop';
  String? _selectedProductId;
  String _selectedCategory = 'Women Ethnic';

  final _titleController = TextEditingController(text: 'Grand Festive Silk & Saree Utsav');
  final _subtitleController = TextEditingController(
      text: 'Handcrafted Bandhani & Banarasi sarees with instant doorstep trial. Special festive price.');
  final _tagController = TextEditingController(text: 'BOUTIQUE SPOTLIGHT');
  final _badgeController = TextEditingController(text: 'FLAT\n30%\nOFF');
  final _buttonTextController = TextEditingController(text: 'Explore Collection');
  final _bannerUrlController = TextEditingController(
      text: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=1200&auto=format&fit=crop&q=80');

  String _selectedPlacement = 'home_hero';
  int _selectedDurationDays = 15;
  double _selectedBudget = 1499.00;
  bool _isUploadingImage = false;

  static const List<String> _presetBanners = [
    'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=1200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=1200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=1200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=1200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?w=1200&auto=format&fit=crop&q=80',
  ];

  static const List<String> _categoryOptions = [
    'Women Ethnic',
    'Sarees',
    'Lehenga Choli',
    'Men Ethnic',
    'Kids Wear',
    'Western',
    'Ethnic',
    'Footwear & Juttis',
    'Accessories',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _tagController.dispose();
    _badgeController.dispose();
    _buttonTextController.dispose();
    _bannerUrlController.dispose();
    super.dispose();
  }

  Future<void> _handlePickAndUploadBanner() async {
    setState(() => _isUploadingImage = true);
    try {
      final Uint8List? imageBytes = await DeviceImagePicker.pickImage();
      if (imageBytes != null) {
        if (imageBytes.lengthInBytes > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Banner image size must be under 5MB.')),
            );
          }
          return;
        }

        final uploadedUrl = await ref
            .read(advertisementProvider.notifier)
            .uploadBannerImage(imageBytes, 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg');

        if (uploadedUrl != null && mounted) {
          setState(() {
            _bannerUrlController.text = uploadedUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Banner image uploaded to Supabase storage!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _onPromoteTypeChanged(String type) {
    setState(() {
      _promoteType = type;
      if (type == 'shop') {
        _tagController.text = 'BOUTIQUE SPOTLIGHT';
        _titleController.text = 'Grand Festive Silk & Saree Utsav';
        _buttonTextController.text = 'Explore Collection';
      } else if (type == 'product') {
        _tagController.text = 'TRENDING PIECE';
        _titleController.text = 'Royal Designer Handcrafted Ensemble';
        _buttonTextController.text = 'Shop Now';
      } else if (type == 'offer') {
        _tagController.text = 'LIMITED OFFER';
        _titleController.text = 'Jaipur Heritage Mega Sale';
        _buttonTextController.text = 'Claim Deal';
      }
    });
  }

  void _showReviewAndPaymentModal() {
    if (!_formKey.currentState!.validate()) return;

    final sellerState = ref.watch(sellerProvider);
    final shop = sellerState.shop;

    if (shop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please register your boutique shop profile before creating ad campaigns.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: _selectedDurationDays));
    final dateFormat = DateFormat('dd MMM yyyy');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Modal Handle
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
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFFDE8EC),
                          child: Icon(Icons.verified_outlined, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Review & Razorpay Payment',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Promoting: ${shop.name}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Live Miniature Banner Preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Image.network(
                            _bannerUrlController.text.trim(),
                            height: 110,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 110,
                              color: const Color(0xFFF3F4F6),
                              child: const Icon(Icons.image, color: AppTheme.textMuted),
                            ),
                          ),
                          Container(
                            height: 110,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            bottom: 12,
                            right: 60,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tagController.text.toUpperCase(),
                                  style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _titleController.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          if (_badgeController.text.isNotEmpty)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _badgeController.text.replaceAll('\n', ' '),
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campaign Specs Table
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Placement', _getPlacementName(_selectedPlacement)),
                          const Divider(height: 16),
                          _buildSummaryRow('Promote Type', _promoteType.toUpperCase()),
                          if (_selectedPlacement == 'category_header' || _promoteType == 'category') ...[
                            const Divider(height: 16),
                            _buildSummaryRow('Target Category', _selectedCategory),
                          ],
                          const Divider(height: 16),
                          _buildSummaryRow('Campaign Duration', '$_selectedDurationDays Days'),
                          const Divider(height: 16),
                          _buildSummaryRow(
                            'Estimated Schedule',
                            '${dateFormat.format(startDate)} → ${dateFormat.format(endDate)}',
                          ),
                          const Divider(height: 16),
                          _buildSummaryRow(
                            'Package Price (Net)',
                            '₹${_selectedBudget.toStringAsFixed(2)}',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Razorpay Security Notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_outline, color: AppTheme.successColor, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Payment processed securely via Razorpay. Ad request is queued for Super Admin activation upon verification.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Razorpay Trigger Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C2340), // Razorpay navy brand color
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _processRazorpayPaymentAndSubmit(shop);
                      },
                      icon: const Icon(Icons.payment, size: 18),
                      label: Text(
                        'Pay ₹${_selectedBudget.toStringAsFixed(0)} via Razorpay',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? AppTheme.primaryColor : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  String _getPlacementName(String placement) {
    switch (placement) {
      case 'home_hero':
        return '🌟 Home Hero Carousel';
      case 'category_header':
        return '🏷️ Category Header Banner';
      case 'featured_feed':
      case 'boutique_spotlight':
        return '💎 Boutique Spotlight';
      default:
        return 'Home Banner';
    }
  }

  Future<void> _processRazorpayPaymentAndSubmit(dynamic shop) async {
    // Generate realistic Razorpay transaction IDs
    final razorpayPaymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';

    final success = await ref.read(advertisementProvider.notifier).submitAdRequest(
          title: _titleController.text.trim(),
          subtitle: _subtitleController.text.trim(),
          tag: _tagController.text.trim(),
          bannerImageUrl: _bannerUrlController.text.trim(),
          placement: _selectedPlacement,
          targetType: _promoteType,
          targetId: _promoteType == 'product' ? _selectedProductId : (shop?.id ?? 'shop-jaipur-01'),
          targetCategory: _selectedCategory,
          buttonText: _buttonTextController.text.trim(),
          badgeText: _badgeController.text.trim(),
          durationDays: _selectedDurationDays,
          budget: _selectedBudget,
          paymentId: razorpayPaymentId,
          paymentMethod: 'razorpay',
          shopId: shop?.id ?? 'shop-jaipur-01',
          shopName: shop?.name ?? 'Jaipur Boutique',
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment Verified ($razorpayPaymentId)! Advertisement submitted for Admin Approval.',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
      _tabController.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adState = ref.watch(advertisementProvider);
    final sellerState = ref.watch(sellerProvider);
    final shop = sellerState.shop;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promote & Advertisements'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            const Tab(icon: Icon(Icons.add_photo_alternate_outlined), text: 'Create Ad Request'),
            Tab(
              icon: const Icon(Icons.history_edu_outlined),
              text: 'My Campaigns (${adState.sellerAds.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Create Ad Form
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Promotional Announcement
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFF59E0B),
                              child: Icon(Icons.campaign, color: Colors.white),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Get Featured on Customer Home & Discovery',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Reach 50,000+ local buyers across Jaipur. Campaigns are reviewed by Super Admin and activated immediately upon approval.',
                                    style: TextStyle(fontSize: 11, color: Colors.brown[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section 1: What to Promote
                      _buildSectionTitle('1. What would you like to promote?', Icons.storefront_outlined),
                      const SizedBox(height: 10),
                      _buildPromoteTypeSelector(),
                      const SizedBox(height: 12),

                      // If promoting specific product, show product picker
                      if (_promoteType == 'product') ...[
                        _buildProductDropdown(sellerState.products),
                        const SizedBox(height: 16),
                      ],

                      // Section 2: Ad Position & Placement
                      _buildSectionTitle('2. Advertisement Placement', Icons.view_carousel_outlined),
                      const SizedBox(height: 10),
                      _buildPlacementSelector(),
                      const SizedBox(height: 12),

                      // If category header, show category selector
                      if (_selectedPlacement == 'category_header' || _promoteType == 'category') ...[
                        _buildCategoryDropdown(),
                        const SizedBox(height: 16),
                      ],

                      // Section 3: Banner Graphic & Presets
                      _buildSectionTitle('3. Advertisement Banner Image', Icons.image_outlined),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Select from curated presets or upload custom banner:',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _isUploadingImage ? null : _handlePickAndUploadBanner,
                            icon: _isUploadingImage
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.upload_file, size: 16),
                            label: const Text('Upload File', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Presets selector
                      SizedBox(
                        height: 70,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _presetBanners.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (ctx, i) {
                            final url = _presetBanners[i];
                            final isSelected = _bannerUrlController.text == url;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _bannerUrlController.text = url;
                                });
                              },
                              child: Container(
                                width: 110,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primaryColor : const Color(0xFFE5E7EB),
                                    width: isSelected ? 3 : 1,
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(url),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _bannerUrlController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Banner Image URL (HTTPS / Supabase)',
                          hintText: 'https://images.unsplash.com/...',
                          prefixIcon: Icon(Icons.link),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter banner image URL' : null,
                      ),
                      const SizedBox(height: 20),

                      // Live Customer Side Preview Card
                      _buildSectionTitle('Live Customer Screen Preview', Icons.preview_outlined),
                      const SizedBox(height: 10),
                      _buildLiveBannerPreview(),
                      const SizedBox(height: 24),

                      // Section 4: Campaign Content & Copywriting
                      _buildSectionTitle('4. Campaign Text & Call to Action', Icons.edit_note_outlined),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _titleController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Campaign Headline / Title',
                                hintText: 'e.g. Royal Bridal Saree Dhamaka',
                                prefixIcon: Icon(Icons.title),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Enter headline' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _tagController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Header Tag',
                                hintText: 'e.g. FESTIVE EDIT',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _subtitleController,
                        maxLines: 2,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Offer Subtitle & Description',
                          hintText: 'e.g. Up to 40% OFF on authentic handcrafted ethnic wear with free delivery.',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter offer description' : null,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _buttonTextController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Button Text',
                                hintText: 'Explore Collection',
                                prefixIcon: Icon(Icons.touch_app_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _badgeController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Discount Badge Text',
                                hintText: '30% OFF',
                                prefixIcon: Icon(Icons.local_offer_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Section 5: Duration & Budget Packages
                      _buildSectionTitle('5. Campaign Duration & Package', Icons.monetization_on_outlined),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDurationCard(days: 7, price: 799.00),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDurationCard(days: 15, price: 1499.00, isPopular: true),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDurationCard(days: 30, price: 2799.00),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildScheduleNotice(),
                      const SizedBox(height: 24),

                      // Contact info confirmation
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.email_outlined, color: AppTheme.textSecondary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Admin will send status updates & invoices to: ${shop?.contactEmail ?? "seller@boutique.com"}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton.icon(
                        onPressed: adState.isLoading ? null : _showReviewAndPaymentModal,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: adState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Review & Pay with Razorpay', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tab 2: Seller's Submitted Ad Requests & Analytics
          _buildMyCampaignsList(adState.sellerAds),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildPromoteTypeSelector() {
    final types = [
      {'id': 'shop', 'label': '🏪 Entire Boutique Storefront', 'sub': 'Link ad directly to your boutique profile'},
      {'id': 'product', 'label': '👗 Featured Catalog Product', 'sub': 'Promote a specific high-demand outfit'},
      {'id': 'offer', 'label': '🏷️ Festive / Seasonal Clearance', 'sub': 'Promote flat discounts & clearance sales'},
    ];

    return Column(
      children: types.map((t) {
        final isSelected = _promoteType == t['id'];
        return InkWell(
          onTap: () => _onPromoteTypeChanged(t['id'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryLight.withValues(alpha: 0.12) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : AppTheme.borderSubtle,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['label'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        t['sub'] as String,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProductDropdown(List products) {
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No products found in catalog yet. You can promote your storefront in the meantime.',
          style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedProductId ?? (products.isNotEmpty ? products.first.id : null),
      decoration: const InputDecoration(
        labelText: 'Select Product to Feature',
        prefixIcon: Icon(Icons.checkroom),
      ),
      items: products.map<DropdownMenuItem<String>>((p) {
        return DropdownMenuItem<String>(
          value: p.id as String,
          child: Text('${p.title} (₹${p.basePrice.toStringAsFixed(0)})', style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          _selectedProductId = val;
        });
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Target Category Placement',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: _categoryOptions.map((cat) {
        return DropdownMenuItem<String>(
          value: cat,
          child: Text(cat, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedCategory = val);
      },
    );
  }

  Widget _buildPlacementSelector() {
    final placements = [
      {
        'id': 'home_hero',
        'title': '🌟 Home Hero Carousel (Top Position)',
        'desc': 'Prime showcase on top of customer homepage with full visibility',
      },
      {
        'id': 'category_header',
        'title': '🏷️ Category Header Banner',
        'desc': 'Promote at the top of category browsing (e.g. Sarees, Women Ethnic)',
      },
      {
        'id': 'featured_feed',
        'title': '💎 Boutique Spotlight Feed',
        'desc': 'Prominent sponsored card in the "Recommended For You" boutique list',
      },
    ];

    return Column(
      children: placements.map((p) {
        final isSelected = _selectedPlacement == p['id'];
        return InkWell(
          onTap: () {
            setState(() {
              _selectedPlacement = p['id'] as String;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryLight.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : AppTheme.borderSubtle,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p['desc'] as String,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLiveBannerPreview() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 180,
          color: const Color(0xFFFDE8EC),
          child: Stack(
            children: [
              // Right side banner image
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 220,
                child: Image.network(
                  _bannerUrlController.text.trim(),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Center(child: Icon(Icons.broken_image, color: AppTheme.textMuted)),
                  ),
                ),
              ),

              // Gradient fade overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFFFDE8EC),
                        const Color(0xFFFDE8EC).withValues(alpha: 0.95),
                        const Color(0xFFFDE8EC).withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // Left text content
              Positioned(
                left: 16,
                top: 16,
                bottom: 16,
                right: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _tagController.text.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _titleController.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitleController.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _buttonTextController.text,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Discount Badge on top-right
              if (_badgeController.text.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _badgeController.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationCard({required int days, required double price, bool isPopular = false}) {
    final isSelected = _selectedDurationDays == days;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDurationDays = days;
          _selectedBudget = price;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (isPopular)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('POPULAR', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            Text(
              '$days Days',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${price.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleNotice() {
    final start = DateTime.now();
    final end = start.add(Duration(days: _selectedDurationDays));
    final fmt = DateFormat('dd MMM');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Active period: ${fmt.format(start)} – ${fmt.format(end)} ($_selectedDurationDays Days)',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCampaignsList(List<AdvertisementModel> ads) {
    if (ads.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 56, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text('No advertisement requests submitted yet', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Switch to "Create Ad Request" to promote your shop.', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: ads.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (ctx, i) {
        final ad = ads[i];
        return _buildCampaignCard(ad);
      },
    );
  }

  Widget _buildCampaignCard(AdvertisementModel ad) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ad.bannerImageUrl,
                    width: 80,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 56,
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(Icons.image, color: AppTheme.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ad.tag,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                          ),
                          const Spacer(),
                          _buildStatusBadge(ad),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(ad.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        '${_getPlacementName(ad.placement)} • ${ad.durationDays} Days (₹${ad.budget.toStringAsFixed(0)})',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Metrics Strip
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricCell('Impressions', '${ad.impressions}'),
                  _buildMetricCell('Clicks', '${ad.clicks}'),
                  _buildMetricCell('CTR', '${ad.ctr.toStringAsFixed(1)}%'),
                  _buildMetricCell('Orders', '${ad.ordersCount}'),
                ],
              ),
            ),

            if (ad.adminNotes != null && ad.adminNotes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ad.isRejected ? const Color(0xFFFEF2F2) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ad.isRejected ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Icon(
                      ad.isRejected ? Icons.warning_amber_rounded : Icons.admin_panel_settings_outlined,
                      size: 14,
                      color: ad.isRejected ? AppTheme.primaryColor : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Admin Note: ${ad.adminNotes}',
                        style: TextStyle(
                          fontSize: 11,
                          color: ad.isRejected ? const Color(0xFF991B1B) : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1, color: AppTheme.borderSubtle),
            const SizedBox(height: 8),

            // Action Buttons
            Row(
              children: [
                if (ad.approvedAt != null && ad.expiresAt != null)
                  Text(
                    'Expires: ${dateFormat.format(ad.expiresAt!)}',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  )
                else
                  Text(
                    'Created: ${dateFormat.format(ad.createdAt)}',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  ),
                const Spacer(),

                // Analytics Dialog Button
                TextButton.icon(
                  onPressed: () => _showAnalyticsModal(ad),
                  icon: const Icon(Icons.insights, size: 14),
                  label: const Text('Analytics', style: TextStyle(fontSize: 11)),
                ),

                // Pause / Resume Button
                if (ad.isApproved && !ad.isExpired)
                  IconButton(
                    tooltip: ad.isPaused ? 'Resume Campaign' : 'Pause Campaign',
                    icon: Icon(
                      ad.isPaused ? Icons.play_arrow_rounded : Icons.pause_circle_outline,
                      color: ad.isPaused ? AppTheme.successColor : AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      ref.read(advertisementProvider.notifier).toggleAdPause(ad.id, !ad.isPaused);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCell(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildStatusBadge(AdvertisementModel ad) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    final status = ad.effectiveStatus;

    switch (status) {
      case 'approved':
      case 'live':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        label = 'LIVE & ACTIVE';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        label = 'REJECTED';
        icon = Icons.cancel;
        break;
      case 'paused':
        bg = const Color(0xFFE5E7EB);
        fg = const Color(0xFF374151);
        label = 'PAUSED';
        icon = Icons.pause;
        break;
      case 'completed':
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
        label = 'COMPLETED';
        icon = Icons.done_all;
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = 'PENDING REVIEW';
        icon = Icons.hourglass_top;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAnalyticsModal(AdvertisementModel ad) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Campaign Performance: ${ad.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticCard('Total Impressions', '${ad.impressions}', Icons.visibility_outlined, Colors.blue),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildAnalyticCard('Total Clicks', '${ad.clicks}', Icons.touch_app_outlined, Colors.purple),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticCard('Click-Through (CTR)', '${ad.ctr.toStringAsFixed(1)}%', Icons.insights, AppTheme.accentColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildAnalyticCard('Attributed Orders', '${ad.ordersCount}', Icons.shopping_bag_outlined, AppTheme.successColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.currency_rupee, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estimated Gross Sales Generated: ₹${ad.revenueGenerated.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
