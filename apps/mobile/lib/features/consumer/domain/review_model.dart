class ReviewModel {
  final String id;
  final String orderId;
  final String productId;
  final String? shopId;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerAvatar;
  final int rating; // 1 to 5
  final String? comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.orderId,
    required this.productId,
    this.shopId,
    required this.reviewerId,
    this.reviewerName = 'Verified Buyer',
    this.reviewerAvatar,
    required this.rating,
    this.comment,
    required this.createdAt,
  }) : assert(rating >= 1 && rating <= 5, 'Rating must be between 1 and 5 stars');

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Extract reviewer name from joined profile if available
    String name = 'Verified Buyer';
    String? avatar;
    if (json['profiles'] != null && json['profiles'] is Map) {
      final profile = json['profiles'] as Map<String, dynamic>;
      name = profile['full_name'] as String? ?? 'Verified Buyer';
      avatar = profile['avatar_url'] as String?;
    } else if (json['reviewer_name'] != null) {
      name = json['reviewer_name'] as String;
      avatar = json['reviewer_avatar'] as String?;
    }

    return ReviewModel(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      shopId: json['shop_id'] as String?,
      reviewerId: json['reviewer_id'] as String? ?? '',
      reviewerName: name,
      reviewerAvatar: avatar,
      rating: ((json['rating'] as num?)?.toInt() ?? 5).clamp(1, 5),
      comment: json['comment'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      if (shopId != null) 'shop_id': shopId,
      'reviewer_id': reviewerId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ReviewModel copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? shopId,
    String? reviewerId,
    String? reviewerName,
    String? reviewerAvatar,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      shopId: shopId ?? this.shopId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerAvatar: reviewerAvatar ?? this.reviewerAvatar,
      rating: (rating ?? this.rating).clamp(1, 5),
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ProductRatingSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> starDistribution; // star (1-5) -> count

  const ProductRatingSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.starDistribution,
  });

  factory ProductRatingSummary.fromReviews(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return const ProductRatingSummary(
        averageRating: 0.0,
        totalReviews: 0,
        starDistribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      );
    }

    final Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    int totalScore = 0;

    for (final review in reviews) {
      final star = review.rating.clamp(1, 5);
      distribution[star] = (distribution[star] ?? 0) + 1;
      totalScore += star;
    }

    final avg = totalScore / reviews.length;
    // Round to 1 decimal place
    final roundedAvg = (avg * 10).round() / 10;

    return ProductRatingSummary(
      averageRating: roundedAvg,
      totalReviews: reviews.length,
      starDistribution: distribution,
    );
  }

  double percentageForStar(int star) {
    if (totalReviews == 0) return 0.0;
    return (starDistribution[star] ?? 0) / totalReviews;
  }
}
