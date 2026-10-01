import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/auth_state.dart';
import '../../domain/review_model.dart';
import '../review_controller.dart';
import 'rating_star_bar.dart';

class ProductRatingSheet extends ConsumerStatefulWidget {
  final String orderId;
  final String productId;
  final String productTitle;
  final String? shopName;
  final String? imageUrl;
  final String? shopId;
  final ReviewModel? initialReview;

  const ProductRatingSheet({
    super.key,
    required this.orderId,
    required this.productId,
    required this.productTitle,
    this.shopName,
    this.imageUrl,
    this.shopId,
    this.initialReview,
  });

  static Future<ReviewModel?> show(
    BuildContext context, {
    required String orderId,
    required String productId,
    required String productTitle,
    String? shopName,
    String? imageUrl,
    String? shopId,
    ReviewModel? initialReview,
  }) {
    return showModalBottomSheet<ReviewModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductRatingSheet(
        orderId: orderId,
        productId: productId,
        productTitle: productTitle,
        shopName: shopName,
        imageUrl: imageUrl,
        shopId: shopId,
        initialReview: initialReview,
      ),
    );
  }

  @override
  ConsumerState<ProductRatingSheet> createState() => _ProductRatingSheetState();
}

class _ProductRatingSheetState extends ConsumerState<ProductRatingSheet> {
  late int _rating;
  late TextEditingController _commentController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialReview?.rating ?? 5;
    _commentController = TextEditingController(text: widget.initialReview?.comment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_rating < 1 || _rating > 5) {
      setState(() => _errorMessage = 'Please select a star rating from 1 to 5.');
      return;
    }

    final user = ref.read(authProvider).user;
    if (user == null) {
      setState(() => _errorMessage = 'You must be signed in to submit a review.');
      return;
    }

    final userName = user.fullName ?? 'Verified Buyer';

    final result = await ref.read(reviewProvider.notifier).submitReview(
      orderId: widget.orderId,
      productId: widget.productId,
      shopId: widget.shopId,
      reviewerId: user.id,
      rating: _rating,
      comment: _commentController.text,
      reviewerName: userName,
    );

    if (result != null && mounted) {
      Navigator.of(context).pop(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you! Your $_rating-star review has been posted.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else if (mounted) {
      final err = ref.read(reviewProvider).errorMessage;
      setState(() => _errorMessage = err ?? 'Failed to submit review. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(reviewProvider).isSubmitting;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
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

            // Header Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.initialReview != null ? 'Edit Your Review' : 'Rate Your Purchase',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: const [
                          Icon(Icons.verified_rounded, size: 14, color: AppTheme.successColor),
                          SizedBox(width: 4),
                          Text(
                            'Verified Hyperlocal Purchase',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Product summary card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.imageUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, e, s) => Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.checkroom, color: Colors.grey),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.productTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (widget.shopName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.shopName!,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rating Stars (Max 5 Stars)
            const Center(
              child: Text(
                'How would you rate this item?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            InteractiveStarRating(
              selectedRating: _rating,
              onRatingChanged: (newRating) {
                setState(() {
                  _rating = newRating;
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 20),

            // Review Comment Text Field
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Write a Review (Optional)',
                hintText: 'Share details about the fabric, sizing, artisan craftsmanship, or fitting...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFFCFDFD),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        widget.initialReview != null ? 'Update Review' : 'Submit Review',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
