import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/review_repository.dart';
import '../domain/review_model.dart';

class ReviewState {
  final Map<String, List<ReviewModel>> reviewsByProduct;
  final Map<String, ProductRatingSummary> summariesByProduct;
  final Map<String, String?> purchasedOrderIds; // key: "$userId-$productId"
  final Map<String, ReviewModel?> userReviews; // key: "$userId-$productId"
  final Map<String, List<ReviewModel>> orderReviews; // key: orderId
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  const ReviewState({
    this.reviewsByProduct = const {},
    this.summariesByProduct = const {},
    this.purchasedOrderIds = const {},
    this.userReviews = const {},
    this.orderReviews = const {},
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  ReviewState copyWith({
    Map<String, List<ReviewModel>>? reviewsByProduct,
    Map<String, ProductRatingSummary>? summariesByProduct,
    Map<String, String?>? purchasedOrderIds,
    Map<String, ReviewModel?>? userReviews,
    Map<String, List<ReviewModel>>? orderReviews,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return ReviewState(
      reviewsByProduct: reviewsByProduct ?? this.reviewsByProduct,
      summariesByProduct: summariesByProduct ?? this.summariesByProduct,
      purchasedOrderIds: purchasedOrderIds ?? this.purchasedOrderIds,
      userReviews: userReviews ?? this.userReviews,
      orderReviews: orderReviews ?? this.orderReviews,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class ReviewController extends Notifier<ReviewState> {
  final ReviewRepository _repo = ReviewRepository();

  @override
  ReviewState build() {
    return const ReviewState();
  }

  Future<void> loadProductReviews(String productId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final reviews = await _repo.getProductReviews(productId);
      final summary = ProductRatingSummary.fromReviews(reviews);

      final updatedReviews = Map<String, List<ReviewModel>>.from(state.reviewsByProduct);
      updatedReviews[productId] = reviews;

      final updatedSummaries = Map<String, ProductRatingSummary>.from(state.summariesByProduct);
      updatedSummaries[productId] = summary;

      state = state.copyWith(
        reviewsByProduct: updatedReviews,
        summariesByProduct: updatedSummaries,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> checkPurchaseEligibility({
    required String userId,
    required String productId,
  }) async {
    final key = '$userId-$productId';
    try {
      final orderId = await _repo.getPurchasedOrderIdForUser(
        userId: userId,
        productId: productId,
      );

      final userReview = await _repo.getUserReviewForProduct(
        userId: userId,
        productId: productId,
      );

      final updatedPurchased = Map<String, String?>.from(state.purchasedOrderIds);
      updatedPurchased[key] = orderId;

      final updatedUserReviews = Map<String, ReviewModel?>.from(state.userReviews);
      updatedUserReviews[key] = userReview;

      state = state.copyWith(
        purchasedOrderIds: updatedPurchased,
        userReviews: updatedUserReviews,
      );
    } catch (_) {}
  }

  Future<void> loadOrderReviews(String orderId) async {
    try {
      final reviews = await _repo.getOrderReviews(orderId);
      final updatedOrderReviews = Map<String, List<ReviewModel>>.from(state.orderReviews);
      updatedOrderReviews[orderId] = reviews;
      state = state.copyWith(orderReviews: updatedOrderReviews);
    } catch (_) {}
  }

  Future<ReviewModel?> submitReview({
    required String orderId,
    required String productId,
    String? shopId,
    required String reviewerId,
    required int rating,
    String? comment,
    String reviewerName = 'Verified Buyer',
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final review = await _repo.submitReview(
        orderId: orderId,
        productId: productId,
        shopId: shopId,
        reviewerId: reviewerId,
        rating: rating,
        comment: comment,
        reviewerName: reviewerName,
      );

      if (review != null) {
        // Refresh product reviews and order reviews
        await loadProductReviews(productId);
        await loadOrderReviews(orderId);

        final key = '$reviewerId-$productId';
        final updatedUserReviews = Map<String, ReviewModel?>.from(state.userReviews);
        updatedUserReviews[key] = review;

        state = state.copyWith(
          userReviews: updatedUserReviews,
          isSubmitting: false,
        );
      } else {
        state = state.copyWith(isSubmitting: false, errorMessage: 'Failed to submit review');
      }

      return review;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return null;
    }
  }
}

final reviewProvider =
    NotifierProvider<ReviewController, ReviewState>(ReviewController.new);
