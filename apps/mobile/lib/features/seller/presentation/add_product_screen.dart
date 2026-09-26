import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/device_image_picker.dart';
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

  // Multiple Product Images List (first item is Primary Cover Photo)
  final List<String> _productImages = [
    'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800&auto=format&fit=crop&q=80',
  ];

  // Variants list
  final List<VariantModel> _variants = [
    const VariantModel(
      id: '',
      productId: '',
      size: 'M',
      color: 'Maroon',
      stockQty: 10,
      sku: 'PRD-M-MRN',
      imageUrls: ['https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800'],
    ),
    const VariantModel(
      id: '',
      productId: '',
      size: 'L',
      color: 'Maroon',
      stockQty: 8,
      sku: 'PRD-L-MRN',
      imageUrls: ['https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800'],
    ),
  ];

  String? _compressionStatus;
  bool _isDeviceUploading = false;
  String? _deviceUploadMessage;

  // Preset boutique image choices for quick selection
  static const List<Map<String, String>> _sampleBoutiqueImages = [
    {
      'label': 'Bandhani Lehenga',
      'url': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800&auto=format&fit=crop&q=80',
    },
    {
      'label': 'Anarkali Kurti',
      'url': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=800&auto=format&fit=crop&q=80',
    },
    {
      'label': 'Silk Saree',
      'url': 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=800&auto=format&fit=crop&q=80',
    },
    {
      'label': 'Royal Sherwani',
      'url': 'https://images.unsplash.com/photo-1597983073493-88cd35cf93b0?w=800&auto=format&fit=crop&q=80',
    },
    {
      'label': 'Mojari Jutti',
      'url': 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=800&auto=format&fit=crop&q=80',
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _minBargainPriceController.dispose();
    super.dispose();
  }

  // Upload one or multiple photos directly from Device Gallery
  Future<void> _pickMultipleImagesFromDevice() async {
    try {
      setState(() {
        _isDeviceUploading = true;
        _deviceUploadMessage = 'Opening device file browser (select one or multiple images)...';
      });

      final rawBytesList = await DeviceImagePicker.pickMultipleImages();
      if (rawBytesList.isEmpty) {
        setState(() {
          _isDeviceUploading = false;
          _deviceUploadMessage = null;
        });
        return;
      }

      setState(() {
        _deviceUploadMessage = 'Compressing ${rawBytesList.length} images client-side...';
      });

      final List<String> uploadedUrls = [];
      final client = SupabaseService.client;

      for (int i = 0; i < rawBytesList.length; i++) {
        final raw = rawBytesList[i];
        final compressed = await ImageCompressor.compressImage(raw);
        final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        String url = '';

        if (client != null) {
          try {
            await client.storage.from('product-images').uploadBinary(
                  fileName,
                  compressed,
                );
            url = client.storage.from('product-images').getPublicUrl(fileName);
          } catch (_) {
            final base64String = base64Encode(compressed);
            url = 'data:image/jpeg;base64,$base64String';
          }
        } else {
          final base64String = base64Encode(compressed);
          url = 'data:image/jpeg;base64,$base64String';
        }

        if (url.isNotEmpty) {
          uploadedUrls.add(url);
        }
      }

      setState(() {
        _productImages.addAll(uploadedUrls);
        _isDeviceUploading = false;
        _deviceUploadMessage = '✓ Successfully added ${uploadedUrls.length} photos from device!';
      });
    } catch (e) {
      setState(() {
        _isDeviceUploading = false;
        _deviceUploadMessage = 'Image selection cancelled or failed: $e';
      });
    }
  }

  void _setAsPrimaryCover(int index) {
    if (index >= 0 && index < _productImages.length) {
      setState(() {
        final img = _productImages.removeAt(index);
        _productImages.insert(0, img);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cover photo updated!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _removeProductImage(int index) {
    if (_productImages.length > 1) {
      setState(() {
        _productImages.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product must have at least one image.')),
      );
    }
  }

  void _showAddByUrlOrPresetModal() {
    final urlController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Image by Web Link or Preset',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Paste an image URL or choose from curated boutique presets.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // URL Input Field
                    TextField(
                      controller: urlController,
                      decoration: InputDecoration(
                        labelText: 'Image Web URL',
                        hintText: 'https://images.unsplash.com/...',
                        prefixIcon: const Icon(Icons.link_rounded),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => urlController.clear(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Preset Photos Selection
                    const Text(
                      'Or Pick from Boutique Presets:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 85,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _sampleBoutiqueImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final sample = _sampleBoutiqueImages[i];
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                urlController.text = sample['url']!;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: urlController.text == sample['url']
                                      ? AppTheme.primaryColor
                                      : const Color(0xFFE5E7EB),
                                  width: urlController.text == sample['url'] ? 2 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    sample['url']!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.image),
                                  ),
                                  Container(
                                    alignment: Alignment.bottomCenter,
                                    color: Colors.black.withValues(alpha: 0.5),
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                    child: Text(
                                      sample['label']!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Add Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final finalUrl = urlController.text.trim();
                          if (finalUrl.isNotEmpty) {
                            setState(() {
                              _productImages.add(finalUrl);
                            });
                          }
                          Navigator.pop(modalContext);
                        },
                        icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
                        label: const Text('Add to Product Photos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
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

  void _showVariantDialog({VariantModel? existingVariant, int? index}) {
    final isEditing = existingVariant != null && index != null;
    final sizeController = TextEditingController(text: existingVariant?.size ?? 'M');
    final colorController = TextEditingController(text: existingVariant?.color ?? 'Maroon');
    int quantity = existingVariant?.stockQty ?? 10;
    final skuController = TextEditingController(text: existingVariant?.sku ?? 'PRD-M-${DateTime.now().millisecondsSinceEpoch % 1000}');

    final commonSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '38', '40', '42', 'Free Size'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Variant / Size' : 'Add New Size & Quantity',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Select Size Pills
                    const Text('Select or Enter Size:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: commonSizes.map((sz) {
                        final isSelected = sizeController.text.trim().toUpperCase() == sz.toUpperCase();
                        return ChoiceChip(
                          label: Text(sz),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryLight,
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                sizeController.text = sz;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Custom Size Text Field
                    TextField(
                      controller: sizeController,
                      decoration: const InputDecoration(
                        labelText: 'Size Name / Custom Size',
                        hintText: 'e.g. M, 38, Free Size, Semi-Stitched',
                        prefixIcon: Icon(Icons.straighten_outlined),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 14),

                    // Color Field
                    TextField(
                      controller: colorController,
                      decoration: const InputDecoration(
                        labelText: 'Color / Pattern',
                        hintText: 'e.g. Crimson Red, Royal Blue, Gold',
                        prefixIcon: Icon(Icons.palette_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stock Quantity Manual Counter & Input
                    const Text('Stock Quantity:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Available Units in Shop:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primaryColor),
                                onPressed: quantity > 0
                                    ? () => setModalState(() => quantity--)
                                    : null,
                              ),
                              SizedBox(
                                width: 50,
                                child: Text(
                                  '$quantity',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                                onPressed: () => setModalState(() => quantity++),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // SKU
                    TextField(
                      controller: skuController,
                      decoration: const InputDecoration(
                        labelText: 'SKU / Barcode (Optional)',
                        hintText: 'e.g. PRD-M-MRN',
                        prefixIcon: Icon(Icons.qr_code_scanner_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Variant Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final size = sizeController.text.trim().isEmpty ? 'M' : sizeController.text.trim();
                          final color = colorController.text.trim().isEmpty ? 'Standard' : colorController.text.trim();
                          final sku = skuController.text.trim().isEmpty ? 'PRD-$size-$color' : skuController.text.trim();

                          setState(() {
                            final newVariant = VariantModel(
                              id: isEditing ? existingVariant.id : '',
                              productId: isEditing ? existingVariant.productId : '',
                              size: size,
                              color: color,
                              stockQty: quantity,
                              sku: sku,
                              imageUrls: _productImages,
                            );

                            if (isEditing) {
                              _variants[index] = newVariant;
                            } else {
                              _variants.add(newVariant);
                            }
                          });

                          Navigator.pop(modalContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          isEditing ? 'Update Variant' : 'Add Variant to Product',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
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

  void _updateVariantStock(int index, int delta) {
    setState(() {
      final v = _variants[index];
      final newQty = (v.stockQty + delta).clamp(0, 9999);
      _variants[index] = VariantModel(
        id: v.id,
        productId: v.productId,
        size: v.size,
        color: v.color,
        stockQty: newQty,
        sku: v.sku,
        imageUrls: v.imageUrls,
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
    
    // Create a 1.2MB dummy test payload
    final samplePayload = Uint8List(1200 * 1024);
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

    // Attach all uploaded product images to all variants
    final updatedVariants = _variants.map((v) {
      return VariantModel(
        id: v.id,
        productId: v.productId,
        size: v.size,
        color: v.color,
        stockQty: v.stockQty,
        sku: v.sku,
        imageUrls: _productImages.isNotEmpty ? _productImages : v.imageUrls,
      );
    }).toList();

    final success = await ref.read(sellerProvider.notifier).createOrUpdateProduct(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      categoryId: 'b0000001-0000-0000-0000-000000000001', // Kurtas & Kurtis
      basePrice: basePrice,
      minBargainPrice: minPrice,
      bargainEnabled: _bargainEnabled,
      variants: updatedVariants,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product and all images published successfully to Supabase DB!'),
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
              constraints: const BoxConstraints(maxWidth: 680),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Product Photos & Multi-Upload Section
                    _buildMultipleImageUploadSection(),
                    const SizedBox(height: 20),

                    // Title & Description
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
                          const Text(
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
                          const Text(
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

                    // Variants, Sizes & Quantity Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Variants & Sizes (${_variants.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showVariantDialog(),
                          icon: const Icon(Icons.add, size: 16, color: Colors.white),
                          label: const Text('Add Size / Color', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Variants List with Stock Steppers & Edit
                    ..._variants.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final variant = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Size Badge
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                variant.size,
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Variant Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Size ${variant.size}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          variant.color,
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'SKU: ${variant.sku ?? "None"}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),

                            // Stock Quantity Stepper directly in card
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: variant.stockQty > 0
                                        ? () => _updateVariantStock(idx, -1)
                                        : null,
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Icon(Icons.remove, size: 16, color: AppTheme.primaryColor),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Text(
                                      '${variant.stockQty} Qty',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _updateVariantStock(idx, 1),
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Icon(Icons.add, size: 16, color: AppTheme.primaryColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 6),

                            // Edit Variant
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
                              tooltip: 'Edit Size & Details',
                              onPressed: () => _showVariantDialog(existingVariant: variant, index: idx),
                            ),

                            // Delete Variant
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                              tooltip: 'Remove Variant',
                              onPressed: () => _removeVariant(idx),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Publish Button
                    ElevatedButton(
                      onPressed: sellerState.isLoading ? null : _handlePublish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: sellerState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Publish Garment to Marketplace',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
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

  Widget _buildGarmentPhotoWidget(String url, {BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('data:image')) {
      try {
        final base64Data = url.split(',').last;
        return Image.memory(
          base64Decode(base64Data),
          fit: fit,
          errorBuilder: (ctx, err, stack) => const Center(
            child: Icon(Icons.checkroom, size: 40, color: AppTheme.textMuted),
          ),
        );
      } catch (_) {}
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (ctx, err, stack) => const Center(
        child: Icon(Icons.checkroom, size: 40, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _buildMultipleImageUploadSection() {
    return Container(
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
              Text('Product Photos & Media (${_productImages.length})', style: Theme.of(context).textTheme.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Multi-Photo Ready', style: TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Upload multiple photos (front, back, model, fabric close-up). The first photo is your Primary Cover.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),

          // Action Buttons: Batch Upload from Device & Add from URL
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isDeviceUploading ? null : _pickMultipleImagesFromDevice,
                  icon: _isDeviceUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_photo_alternate_rounded, size: 18, color: Colors.white),
                  label: Text(
                    _isDeviceUploading ? 'Compressing...' : '📁 Upload Multiple Photos',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _showAddByUrlOrPresetModal,
                icon: const Icon(Icons.link_rounded, size: 16),
                label: const Text('Add via Link', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),

          if (_deviceUploadMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _deviceUploadMessage!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _deviceUploadMessage!.startsWith('✓') ? AppTheme.successColor : AppTheme.primaryColor,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Uploaded Photos Grid
          if (_productImages.isEmpty)
            _buildEmptyUploadPlaceholder()
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ..._productImages.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final imgUrl = entry.value;
                  final isCover = idx == 0;

                  return Container(
                    width: 135,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCover ? AppTheme.primaryColor : const Color(0xFFE5E7EB),
                        width: isCover ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildGarmentPhotoWidget(imgUrl, fit: BoxFit.cover),

                        // Cover Badge or "Set as Cover" button
                        Positioned(
                          top: 6,
                          left: 6,
                          child: isCover
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('★ Cover', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                )
                              : InkWell(
                                  onTap: () => _setAsPrimaryCover(idx),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Make Cover', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                        ),

                        // Delete button
                        Positioned(
                          top: 6,
                          right: 6,
                          child: InkWell(
                            onTap: () => _removeProductImage(idx),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.errorColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),

                        // Photo Index Label
                        Positioned(
                          bottom: 4,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Add More Photos Placeholder Card
                InkWell(
                  onTap: _isDeviceUploading ? null : _pickMultipleImagesFromDevice,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 135,
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppTheme.primaryColor),
                        SizedBox(height: 6),
                        Text(
                          '+ Add More',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                        Text(
                          'Select multiple',
                          style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyUploadPlaceholder() {
    return InkWell(
      onTap: _isDeviceUploading ? null : _pickMultipleImagesFromDevice,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
        ),
        child: _buildPlaceholderGraphic(),
      ),
    );
  }

  Widget _buildPlaceholderGraphic() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload Multiple Product Photos',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 2),
          const Text(
            'Select multiple photos from device or gallery at once',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
