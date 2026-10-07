import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'seller_controller.dart';

class ShopRegistrationScreen extends ConsumerStatefulWidget {
  const ShopRegistrationScreen({super.key});

  @override
  ConsumerState<ShopRegistrationScreen> createState() => _ShopRegistrationScreenState();
}

class _ShopRegistrationScreenState extends ConsumerState<ShopRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankIfscController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _tradeLicenseController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _latController = TextEditingController(text: '26.9200');
  final _lngController = TextEditingController(text: '75.8267');

  String _businessType = 'sole_proprietorship';
  String? _selectedAvatarUrl;
  final List<String> _kycDocumentUrls = [];

  static const List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1544717305-2782549b5136?w=400',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400',
    'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400',
  ];

  static const List<Map<String, String>> _businessTypes = [
    {'value': 'sole_proprietorship', 'label': 'Sole Proprietorship (Individual Store)'},
    {'value': 'partnership', 'label': 'Partnership Firm'},
    {'value': 'pvt_ltd', 'label': 'Private Limited (Pvt Ltd)'},
    {'value': 'llp', 'label': 'Limited Liability Partnership (LLP)'},
    {'value': 'artisan', 'label': 'Individual Handloom Artisan / Weaver'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shop = ref.read(sellerProvider).shop;
      if (shop != null) {
        _nameController.text = shop.name;
        _ownerNameController.text = shop.ownerName ?? 'Rajesh Sharma';
        _descriptionController.text = shop.description ?? '';
        _addressController.text = shop.address;
        _landmarkController.text = shop.landmark ?? 'Near Johari Bazaar Main Gate';
        _pincodeController.text = shop.pincode ?? '302003';
        _contactPhoneController.text = shop.contactPhone ?? '+91 98290 12345';
        _contactEmailController.text = shop.contactEmail ?? 'rajesh.handlooms@jaipur.in';
        _bankAccountNameController.text = shop.bankAccountName ?? shop.ownerName ?? 'Rajesh Sharma';
        _bankAccountController.text = shop.bankAccountNumber ?? '91827364501234';
        _bankIfscController.text = shop.bankIfsc ?? 'HDFC0001234';
        _bankNameController.text = shop.bankName ?? 'HDFC Bank - Johari Bazaar';
        _gstinController.text = shop.gstin ?? '08AABCT3524Q1Z8';
        _panController.text = shop.panNumber ?? 'AABCT3524Q';
        _tradeLicenseController.text = shop.tradeLicenseNumber ?? 'RJ-JP-2024-8842';
        _aadhaarController.text = shop.aadhaarNumber ?? '765432109876';
        _businessType = shop.businessType ?? 'sole_proprietorship';
        _logoUrlController.text = shop.logoUrl ?? _presetAvatars.first;
        _selectedAvatarUrl = shop.logoUrl ?? _presetAvatars.first;
        _latController.text = shop.latitude.toString();
        _lngController.text = shop.longitude.toString();
        _kycDocumentUrls.clear();
        _kycDocumentUrls.addAll(shop.kycDocuments.isNotEmpty
            ? shop.kycDocuments
            : [
                'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600',
              ]);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _bankAccountNameController.dispose();
    _bankAccountController.dispose();
    _bankIfscController.dispose();
    _bankNameController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _tradeLicenseController.dispose();
    _aadhaarController.dispose();
    _logoUrlController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latController.text.trim()) ?? 26.9200;
    final lng = double.tryParse(_lngController.text.trim()) ?? 75.8267;

    final success = await ref.read(sellerProvider.notifier).saveShopProfile(
      name: _nameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      landmark: _landmarkController.text.trim(),
      pincode: _pincodeController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
      contactEmail: _contactEmailController.text.trim(),
      bankAccountName: _bankAccountNameController.text.trim(),
      bankAccountNumber: _bankAccountController.text.trim(),
      bankIfsc: _bankIfscController.text.trim().toUpperCase(),
      bankName: _bankNameController.text.trim(),
      gstin: _gstinController.text.trim().toUpperCase(),
      panNumber: _panController.text.trim().toUpperCase(),
      businessType: _businessType,
      tradeLicenseNumber: _tradeLicenseController.text.trim(),
      aadhaarNumber: _aadhaarController.text.trim(),
      logoUrl: _selectedAvatarUrl ?? _logoUrlController.text.trim(),
      latitude: lat,
      longitude: lng,
      kycDocuments: _kycDocumentUrls,
      categoryIds: ['a0000001-0000-0000-0000-000000000004'], // Ethnic & Traditional
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop registration and KYC business documents submitted for Super Admin verification!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.pop();
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final urlController = TextEditingController(text: _selectedAvatarUrl ?? '');
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Profile & Boutique Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose a curated boutique avatar or enter a custom image URL:',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presetAvatars.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final url = _presetAvatars[i];
                    final isSelected = _selectedAvatarUrl == url;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedAvatarUrl = url;
                          _logoUrlController.text = url;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(url),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Custom Image URL',
                  hintText: 'https://example.com/my-photo.jpg',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final text = urlController.text.trim();
                  if (text.isNotEmpty) {
                    setState(() {
                      _selectedAvatarUrl = text;
                      _logoUrlController.text = text;
                    });
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Apply Custom Photo'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addKycDocumentUrl() {
    final docUrlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Document / Certificate URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload or paste link to GST Certificate, Trade License, or Shop Photo:',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: docUrlController,
              decoration: const InputDecoration(
                labelText: 'Document Image URL',
                hintText: 'https://images.unsplash.com/...',
                prefixIcon: Icon(Icons.attachment),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = docUrlController.text.trim();
              if (text.isNotEmpty) {
                setState(() => _kycDocumentUrls.add(text));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add Document'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sellerState = ref.watch(sellerProvider);
    final shop = sellerState.shop;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Registration & KYC'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Verification Status Banner
                    if (shop != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: shop.isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: shop.isVerified ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              shop.isVerified ? Icons.verified_rounded : Icons.pending_actions_rounded,
                              color: shop.isVerified ? AppTheme.successColor : const Color(0xFFB45309),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop.isVerified ? 'Boutique KYC Verified & Active' : 'KYC Verification Pending Review',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: shop.isVerified ? AppTheme.successColor : const Color(0xFFB45309),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    shop.isVerified
                                        ? 'Your shop is approved for live catalogue, instant orders, and promotions.'
                                        : 'Super Admin will verify your GSTIN, PAN, and trade registration.',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Avatar & Profile Photo Section
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.primaryColor, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFFF3F4F6),
                              backgroundImage: _selectedAvatarUrl != null && _selectedAvatarUrl!.isNotEmpty
                                  ? NetworkImage(_selectedAvatarUrl!)
                                  : null,
                              child: _selectedAvatarUrl == null || _selectedAvatarUrl!.isEmpty
                                  ? const Icon(Icons.storefront, size: 48, color: AppTheme.primaryColor)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _showImagePickerModal,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: _showImagePickerModal,
                        icon: const Icon(Icons.photo_library_outlined, size: 16),
                        label: const Text('Change Storefront Logo / Photo', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 1: Boutique & Owner Profile
                    _buildSectionHeader('1. Boutique & Owner Information', Icons.storefront_rounded),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Shop / Boutique Trade Name *',
                        hintText: 'e.g. Jaipur Heritage Handlooms',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Please enter your shop trade name' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Owner / Authorized Representative Name *',
                        hintText: 'e.g. Rajesh Sharma',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Please enter owner full name' : null,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: _businessType,
                      decoration: const InputDecoration(
                        labelText: 'Business Entity Constitution *',
                        prefixIcon: Icon(Icons.corporate_fare_outlined),
                      ),
                      items: _businessTypes.map((t) {
                        return DropdownMenuItem<String>(
                          value: t['value'],
                          child: Text(t['label']!, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _businessType = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Shop Bio, Heritage & Specialties',
                        hintText: 'Describe your authentic collections, craft heritage, and specialties...',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Business KYC & Tax Documents (What shopkeepers need to upload)
                    _buildSectionHeader('2. Tax Identification & KYC Proof (Required)', Icons.badge_outlined),
                    const SizedBox(height: 6),
                    const Text(
                      'Indian e-commerce compliance requires GSTIN and business PAN verification for instant seller payouts.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _gstinController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'GSTIN (15-digit) *',
                              hintText: '08AABCT3524Q1Z8',
                              prefixIcon: Icon(Icons.receipt_long_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter GSTIN';
                              if (val.trim().length < 15) return '15 chars required';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _panController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Business / Owner PAN *',
                              hintText: 'AABCT3524Q',
                              prefixIcon: Icon(Icons.credit_card_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter PAN';
                              if (val.trim().length != 10) return '10 chars required';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tradeLicenseController,
                            decoration: const InputDecoration(
                              labelText: 'Trade License / MSME Udyam No.',
                              hintText: 'RJ-JP-2024-8842',
                              prefixIcon: Icon(Icons.domain_verification_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _aadhaarController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Owner Aadhaar No.',
                              hintText: '7654 3210 9876',
                              prefixIcon: Icon(Icons.fingerprint_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Document Upload Cards
                    Card(
                      color: const Color(0xFFF9FAFB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Uploaded KYC Verification Documents',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                TextButton.icon(
                                  onPressed: _addKycDocumentUrl,
                                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                                  label: const Text('Add Document', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_kycDocumentUrls.isEmpty)
                              const Text(
                                'No documents attached yet. Click "Add Document" to attach your GST certificate or Trade License.',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              )
                            else
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _kycDocumentUrls.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final docUrl = entry.value;
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFCBD5E1)),
                                          image: DecorationImage(
                                            image: NetworkImage(docUrl),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: InkWell(
                                          onTap: () => setState(() => _kycDocumentUrls.removeAt(idx)),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.black87,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Contact Details
                    _buildSectionHeader('3. Contact Information', Icons.phone_android_rounded),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _contactPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Contact Phone / WhatsApp *',
                              hintText: '+91 98290 12345',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'Enter contact number' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _contactEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Business Email *',
                              hintText: 'seller@boutique.com',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'Enter email address' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 4: Bank Account & Payout Info
                    _buildSectionHeader('4. Bank Account & Settlement Payouts', Icons.account_balance_rounded),
                    const SizedBox(height: 6),
                    const Text(
                      'Used for instant automated 90% payout splits on every completed customer delivery.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _bankAccountNameController,
                      decoration: const InputDecoration(
                        labelText: 'Beneficiary Account Holder Name *',
                        hintText: 'e.g. Jaipur Heritage Handlooms or Rajesh Sharma',
                        prefixIcon: Icon(Icons.person_pin_outlined),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Enter account holder name' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _bankAccountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Bank Account Number *',
                        hintText: 'e.g. 91827364501234',
                        prefixIcon: Icon(Icons.tag),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Enter bank account number' : null,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _bankNameController,
                            decoration: const InputDecoration(
                              labelText: 'Bank Name & Branch *',
                              hintText: 'HDFC Bank - Johari Bazaar',
                              prefixIcon: Icon(Icons.account_balance_outlined),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'Enter bank name' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _bankIfscController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'IFSC Code *',
                              hintText: 'HDFC0001234',
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'Enter IFSC' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 5: Physical Address & Geolocation
                    _buildSectionHeader('5. Physical Pickup Location & Map Pin', Icons.location_on_rounded),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Store Pickup Address (Building/Street) *',
                        hintText: 'Plot 14, Johari Bazaar, Pink City, Jaipur',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Please enter physical address' : null,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _landmarkController,
                            decoration: const InputDecoration(
                              labelText: 'Landmark',
                              hintText: 'Opposite Sanganeri Gate',
                              prefixIcon: Icon(Icons.place_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _pincodeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Pincode *',
                              hintText: '302003',
                              prefixIcon: Icon(Icons.pin_drop_outlined),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'Enter pincode' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              prefixIcon: Icon(Icons.my_location),
                            ),
                            validator: (val) => val == null || double.tryParse(val) == null
                                ? 'Invalid latitude'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lngController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              prefixIcon: Icon(Icons.explore_outlined),
                            ),
                            validator: (val) => val == null || double.tryParse(val) == null
                                ? 'Invalid longitude'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: sellerState.isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: sellerState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit Shop Profile & KYC for Admin Verification', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}

