import 'package:flutter/foundation.dart';
import '../../../core/network/supabase_client.dart';
import '../domain/review_model.dart';

class ReviewRepository {
  // In-memory mock reviews for offline / test environments
  static final List<ReviewModel> _mockReviews = [
    ReviewModel(
      id: 'rev-01',
      orderId: 'f0000001-0000-0000-0000-000000000003',
      productId: 'prod-001',
      shopId: 'shop-jaipur-01',
      reviewerId: '00000000-0000-0000-0000-000000000001',
      reviewerName: 'Priya Sharma',
      reviewerAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
      rating: 5,
      comment: 'Authentic Sanganeri block print with pure organic cotton! The gota patti work on the neckline is immaculate. Super fast delivery in Johari Bazaar.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ReviewModel(
      id: 'rev-02',
      orderId: 'f0000001-0000-0000-0000-000000000003',
      productId: 'prod-001',
      shopId: 'shop-jaipur-01',
      reviewerId: '00000000-0000-0000-0000-000000000011',
      reviewerName: 'Ananya Sen',
      reviewerAvatar: null,
      rating: 5,
      comment: 'Loved the indigo blue shade. Stitching quality is top notch and fits true to size.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ReviewModel(
      id: 'rev-03',
      orderId: 'f0000001-0000-0000-0000-000000000003',
      productId: 'prod-001',
      shopId: 'shop-jaipur-01',
      reviewerId: 'user-03',
      reviewerName: 'Kavita Verma',
      reviewerAvatar: null,
      rating: 4,
      comment: 'Very comfortable daily wear ethnic kurta. Color did not bleed after first wash.',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    ReviewModel(
      id: 'rev-04',
      orderId: 'f0000001-0000-0000-0000-000000000003',
      productId: 'prod-002',
      shopId: 'shop-jaipur-02',
      reviewerId: '00000000-0000-0000-0000-000000000001',
      reviewerName: 'Priya Sharma',
      reviewerAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
      rating: 5,
      comment: 'The Chanderi silk saree exceeded expectations. Heavy gold zari and royal finish.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  /// Get all reviews for a product
  Future<List<ReviewModel>> getProductReviews(String productId) async {
    final client = SupabaseService.client;
    if (client == null) {
      return _mockReviews.where((r) => r.productId == productId).toList();
    }

    try {
      final res = await client
          .from('reviews')
          .select('*, profiles:reviewer_id(full_name, avatar_url)')
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      final reviews = (res as List)
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (reviews.isEmpty) {
        return _mockReviews.where((r) => r.productId == productId).toList();
      }
      return reviews;
    } catch (e) {
      debugPrint('[ReviewRepository] Error fetching product reviews: $e');
      return _mockReviews.where((r) => r.productId == productId).toList();
    }
  }

  /// Get summary of ratings for a product
  Future<ProductRatingSummary> getProductRatingSummary(String productId) async {
    final reviews = await getProductReviews(productId);
    return ProductRatingSummary.fromReviews(reviews);
  }

  /// Check if the user has purchased the product, and returns the order_id if purchased
  Future<String?> getPurchasedOrderIdForUser({
    required String userId,
    required String productId,
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      // In offline / mock mode: user-01 and 00000000-0000-0000-0000-000000000001 have purchased prod-001 & prod-002
      if (userId == '00000000-0000-0000-0000-000000000001' || userId == 'user-01' || userId == 'buyer-01') {
        return 'ord-mock-101';
      }
      return null;
    }

    try {
      // Find any order by this user containing the product
      final res = await client
          .from('orders')
          .select('id, status, order_items!inner(product_id)')
          .eq('consumer_id', userId)
          .eq('order_items.product_id', productId)
          .neq('status', 'cancelled')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null && res['id'] != null) {
        return res['id'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('[ReviewRepository] Error verifying purchased product order: $e');
      return null;
    }
  }

  /// Check if user has already reviewed a product for a specific order
  Future<ReviewModel?> getUserReviewForProduct({
    required String userId,
    required String productId,
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      try {
        return _mockReviews.firstWhere(
          (r) => r.reviewerId == userId && r.productId == productId,
        );
      } catch (_) {
        return null;
      }
    }

    try {
      final res = await client
          .from('reviews')
          .select('*, profiles:reviewer_id(full_name, avatar_url)')
          .eq('reviewer_id', userId)
          .eq('product_id', productId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return res != null ? ReviewModel.fromJson(res) : null;
    } catch (e) {
      debugPrint('[ReviewRepository] Error getting user review: $e');
      return null;
    }
  }

  /// Get all reviews created for an order
  Future<List<ReviewModel>> getOrderReviews(String orderId) async {
    final client = SupabaseService.client;
    if (client == null) {
      return _mockReviews.where((r) => r.orderId == orderId).toList();
    }

    try {
      final res = await client
          .from('reviews')
          .select('*, profiles:reviewer_id(full_name, avatar_url)')
          .eq('order_id', orderId);

      return (res as List)
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ReviewRepository] Error getting order reviews: $e');
      return _mockReviews.where((r) => r.orderId == orderId).toList();
    }
  }

  /// Submit a 1-5 star review for a purchased product
  Future<ReviewModel?> submitReview({
    required String orderId,
    required String productId,
    String? shopId,
    required String reviewerId,
    required int rating,
    String? comment,
    String reviewerName = 'Verified Buyer',
  }) async {
    // Enforce 1-5 star rating
    final clampedRating = rating.clamp(1, 5);

    final newReview = ReviewModel(
      id: 'rev-${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      productId: productId,
      shopId: shopId,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      rating: clampedRating,
      comment: comment?.trim().isNotEmpty == true ? comment!.trim() : null,
      createdAt: DateTime.now(),
    );

    final client = SupabaseService.client;
    if (client == null) {
      // Update existing mock review or add new
      final existingIdx = _mockReviews.indexWhere(
        (r) => r.orderId == orderId && r.productId == productId,
      );
      if (existingIdx >= 0) {
        _mockReviews[existingIdx] = newReview;
      } else {
        _mockReviews.insert(0, newReview);
      }
      return newReview;
    }

    try {
      final payload = <String, dynamic>{
        'order_id': orderId,
        'product_id': productId,
        'reviewer_id': reviewerId,
        'rating': clampedRating,
        'comment': comment?.trim().isNotEmpty == true ? comment!.trim() : null,
      };
      if (shopId != null && shopId.isNotEmpty) {
        payload['shop_id'] = shopId;
      }

      final res = await client
          .from('reviews')
          .upsert(
            payload,
            onConflict: 'order_id,product_id,reviewer_id',
          )
          .select('*, profiles:reviewer_id(full_name, avatar_url)')
          .single();

      return ReviewModel.fromJson(res);
    } catch (e) {
      debugPrint('[ReviewRepository] Error submitting review: $e');
      // Fallback in memory
      _mockReviews.insert(0, newReview);
      return newReview;
    }
  }
}
