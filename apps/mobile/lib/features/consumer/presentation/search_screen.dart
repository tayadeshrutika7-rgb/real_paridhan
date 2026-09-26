import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../seller/domain/product_model.dart';
import '../data/consumer_repository.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _repo = ConsumerRepository();
  List<ProductModel> _results = [];
  bool _isLoading = false;
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);

    double? maxPrice;
    double? minPrice;

    if (_selectedFilter == 'Under ₹1500') {
      maxPrice = 1500;
    } else if (_selectedFilter == '₹1500 - ₹3000') {
      minPrice = 1500;
      maxPrice = 3000;
    } else if (_selectedFilter == 'Above ₹3000') {
      minPrice = 3000;
    }

    final products = await _repo.searchProducts(
      query: query,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );

    if (mounted) {
      setState(() {
        _results = products;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search kurtas, sarees, handlooms...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onChanged: (val) => _performSearch(val),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _filterChip('All Items'),
                const SizedBox(width: 8),
                _filterChip('Under ₹1500'),
                const SizedBox(width: 8),
                _filterChip('₹1500 - ₹3000'),
                const SizedBox(width: 8),
                _filterChip('Above ₹3000'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Results Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 64, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            const Text('No products matched your search', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Try searching for "Kurta", "Saree", or "Silk"', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: _results.length,
                        itemBuilder: (context, idx) {
                          final product = _results[idx];
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
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = (_selectedFilter == null && label == 'All Items') || _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label == 'All Items' ? null : label;
        });
        _performSearch(_searchController.text);
      },
    );
  }
}
