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
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController(text: '26.9200');
  final _lngController = TextEditingController(text: '75.8267');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shop = ref.read(sellerProvider).shop;
      if (shop != null) {
        _nameController.text = shop.name;
        _descriptionController.text = shop.description ?? '';
        _addressController.text = shop.address;
        _latController.text = shop.latitude.toString();
        _lngController.text = shop.longitude.toString();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
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
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      latitude: lat,
      longitude: lng,
      categoryIds: ['a0000001-0000-0000-0000-000000000004'], // Ethnic & Traditional
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop Profile saved with PostGIS coordinates!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerState = ref.watch(sellerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Profile & Location'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.share_location_outlined, color: AppTheme.accentColor, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PostGIS Geospatial Discovery',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Your shop coordinates power the hyperlocal radius search for buyers within 5-10 km.',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Shop / Boutique Name',
                        hintText: 'e.g. Royal Jaipur Weaves',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Please enter your shop name' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Shop Description',
                        hintText: 'Describe your authentic collections, craft heritage, and specialties...',
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Street Address',
                        hintText: 'Plot/Shop No., Market Name, City, State, Pincode',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Please enter physical address' : null,
                    ),
                    const SizedBox(height: 16),

                    Text('Geographical Coordinates (PostGIS 4326)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),

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
                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: sellerState.isLoading ? null : _handleSave,
                      child: sellerState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Shop & Activate Location'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
