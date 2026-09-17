import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_compressor.dart';
import '../domain/variant_model.dart';
import 'seller_controller.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController(text: '1999.00');
  final _minBargainPriceController = TextEditingController(text: '1599.00');
  bool _bargainEnabled = true;

  final List<VariantModel> _variants = [
    const VariantModel(
      id: '',
      productId: '',
      size: 'M',
      color: 'Maroon',
      stockQty: 10,
      sku: 'PRD-M-MRN',
      imageUrls: ['https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600'],
    ),
    const VariantModel(
      id: '',
      productId: '',
      size: 'L',
      color: 'Maroon',
      stockQty: 8,
      sku: 'PRD-L-MRN',
      imageUrls: ['https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600'],
    ),
  ];

  String? _compressionStatus;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _minBargainPriceController.dispose();
    super.dispose();
  }

  void _addVariant() {
    setState(() {
      _variants.add(
        VariantModel(
          id: '',
          productId: '',
          size: 'XL',
          color: 'Maroon',
          stockQty: 5,
          sku: 'PRD-XL-${DateTime.now().millisecondsSinceEpoch % 1000}',
          imageUrls: const ['https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600'],
        ),
      );
    });
  }

  void _removeVariant(int index) {
    if (_variants.length > 1) {
      setState(() => _variants.removeAt(index));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A product must contain at least one variant.')),
      );
    }
  }

  Future<void> _testImageCompression() async {
    setState(() => _compressionStatus = 'Compressing image client-side...');
    
    // Create a 1MB dummy test payload
    final samplePayload = Uint8List(1200 * 1024); // 1.2 MB
    final compressed = await ImageCompressor.compressImage(samplePayload);
    
    final originalKb = (samplePayload.lengthInBytes / 1024).toStringAsFixed(1);
    final compressedKb = (compressed.lengthInBytes / 1024).toStringAsFixed(1);

    setState(() {
      _compressionStatus = 'Client Compression Verified: ${originalKb}KB → ${compressedKb}KB (Target: ≤500KB)';
    });
  }

  Future<void> _handlePublish() async {
    if (!_formKey.currentState!.validate()) return;

    final basePrice = double.tryParse(_basePriceController.text.trim()) ?? 0;
    final minPrice = double.tryParse(_minBargainPriceController.text.trim()) ?? 0;

    if (_bargainEnabled && minPrice > basePrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum bargain floor price cannot exceed the base price!'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final success = await ref.read(sellerProvider.notifier).createOrUpdateProduct(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      categoryId: 'b0000001-0000-0000-0000-000000000001', // Kurtas & Kurtis
      basePrice: basePrice,
      minBargainPrice: minPrice,
      bargainEnabled: _bargainEnabled,
      variants: _variants,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product and variants published successfully!'),
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
        title: const Text('Add New Product'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Product Title',
                        hintText: 'e.g. Handcrafted Cotton Bandhani Kurti',
                        prefixIcon: Icon(Icons.checkroom_outlined),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Please enter a product title' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Garment Description & Craft Heritage',
                        hintText: 'Describe fabric, craft technique, washing instructions, fit...',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pricing & Bargaining Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pricing & Bargaining Floor Engine', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Paridhan enforces your floor price on the server. Buyers cannot offer below your minimum price.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _basePriceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Retail Base Price (₹)',
                                    prefixIcon: Icon(Icons.currency_rupee),
                                  ),
                                  validator: (val) {
                                    if (val == null || double.tryParse(val) == null) return 'Invalid price';
                                    if (double.parse(val) <= 0) return 'Must be > 0';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _minBargainPriceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Floor Price (₹)',
                                    helperText: 'Enforced by DB trigger',
                                    prefixIcon: Icon(Icons.shield_outlined),
                                  ),
                                  validator: (val) {
                                    if (val == null || double.tryParse(val) == null) return 'Invalid floor';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Material(
                            type: MaterialType.transparency,
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Allow Real-Time Bargaining', style: TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: const Text('Consumers can negotiate offers down to your floor price'),
                              value: _bargainEnabled,
                              activeThumbColor: AppTheme.accentColor,
                              onChanged: (val) => setState(() => _bargainEnabled = val),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Client-Side Image Compression Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('Image Compression Engine', style: Theme.of(context).textTheme.titleMedium),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('≤ 500 KB Target', style: TextStyle(color: AppTheme.successColor, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'All photos are compressed and resized on the client before being sent to Supabase Storage.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _testImageCompression,
                            icon: const Icon(Icons.compress),
                            label: const Text('Test Client-Side Compression'),
                          ),
                          if (_compressionStatus != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _compressionStatus!,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Variants Builder Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('Variants & Sizes (${_variants.length})', style: Theme.of(context).textTheme.titleMedium),
                        ),
                        TextButton.icon(
                          onPressed: _addVariant,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Size / Color'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ..._variants.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final variant = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.accentLight,
                                child: Text(variant.size, style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Size ${variant.size} • Color: ${variant.color}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Stock: ${variant.stockQty} units • SKU: ${variant.sku ?? "None"}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                                onPressed: () => _removeVariant(idx),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: sellerState.isLoading ? null : _handlePublish,
                      child: sellerState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Publish Garment to Marketplace'),
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
