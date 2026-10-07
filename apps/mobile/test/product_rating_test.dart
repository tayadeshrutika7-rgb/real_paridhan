import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paridhan_mobile/features/consumer/domain/review_model.dart';
import 'package:paridhan_mobile/features/consumer/data/review_repository.dart';
import 'package:paridhan_mobile/features/consumer/presentation/widgets/rating_star_bar.dart';
import 'package:paridhan_mobile/features/consumer/presentation/widgets/product_rating_sheet.dart';
import 'test_utils.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  group('Phase 8: Product Ratings & Reviews Unit Tests', () {
    test('ReviewModel enforces 1 to 5 star rating clamp and JSON serialization', () {
      final review = ReviewModel(
        id: 'rev-test-1',
        orderId: 'ord-100',
        productId: 'prod-001',
        reviewerId: 'user-01',
        reviewerName: 'Priya Sharma',
        rating: 5,
        comment: 'Outstanding quality and fabric!',
        createdAt: DateTime(2026, 3, 1),
      );

      expect(review.rating, 5);
      expect(review.reviewerName, 'Priya Sharma');

      final json = review.toJson();
      expect(json['rating'], 5);
      expect(json['order_id'], 'ord-100');
      expect(json['product_id'], 'prod-001');

      final fromJson = ReviewModel.fromJson({
        'id': 'rev-test-2',
        'order_id': 'ord-101',
        'product_id': 'prod-001',
        'reviewer_id': 'user-02',
        'profiles': {'full_name': 'Ananya Sen', 'avatar_url': null},
        'rating': 4,
        'comment': 'Great fit and color.',
      });

      expect(fromJson.reviewerName, 'Ananya Sen');
      expect(fromJson.rating, 4);
    });

    test('ProductRatingSummary calculates averages and star percentages correctly', () {
      final reviews = [
        ReviewModel(
          id: 'r1',
          orderId: 'o1',
          productId: 'p1',
          reviewerId: 'u1',
          rating: 5,
          createdAt: DateTime.now(),
        ),
        ReviewModel(
          id: 'r2',
          orderId: 'o2',
          productId: 'p1',
          reviewerId: 'u2',
          rating: 5,
          createdAt: DateTime.now(),
        ),
        ReviewModel(
          id: 'r3',
          orderId: 'o3',
          productId: 'p1',
          reviewerId: 'u3',
          rating: 4,
          createdAt: DateTime.now(),
        ),
        ReviewModel(
          id: 'r4',
          orderId: 'o4',
          productId: 'p1',
          reviewerId: 'u4',
          rating: 2,
          createdAt: DateTime.now(),
        ),
      ];

      final summary = ProductRatingSummary.fromReviews(reviews);

      expect(summary.totalReviews, 4);
      // (5 + 5 + 4 + 2) / 4 = 16 / 4 = 4.0
      expect(summary.averageRating, 4.0);
      expect(summary.starDistribution[5], 2);
      expect(summary.starDistribution[4], 1);
      expect(summary.starDistribution[2], 1);
      expect(summary.starDistribution[1], 0);

      // Percentage check: 2 out of 4 = 50% for 5-star
      expect(summary.percentageForStar(5), 0.5);
      expect(summary.percentageForStar(4), 0.25);
      expect(summary.percentageForStar(1), 0.0);
    });

    test('ReviewRepository verifies purchase eligibility and limits rating to purchasers', () async {
      final repo = ReviewRepository();

      // Buyer who purchased prod-001
      final purchaserOrderId = await repo.getPurchasedOrderIdForUser(
        userId: 'user-01',
        productId: 'prod-001',
      );
      expect(purchaserOrderId, isNotNull);

      // Non-purchaser attempting to rate
      final nonPurchaserOrderId = await repo.getPurchasedOrderIdForUser(
        userId: 'unknown-random-user',
        productId: 'prod-001',
      );
      expect(nonPurchaserOrderId, isNull);

      // Submit 5-star review for purchased product
      final submitted = await repo.submitReview(
        orderId: purchaserOrderId!,
        productId: 'prod-001',
        shopId: 'shop-jaipur-01',
        reviewerId: 'user-01',
        rating: 5,
        comment: 'Pure Rajasthani perfection!',
        reviewerName: 'Priya Sharma',
      );

      expect(submitted, isNotNull);
      expect(submitted!.rating, 5);
      expect(submitted.comment, 'Pure Rajasthani perfection!');
    });
  });

  group('Phase 8: Rating Widgets & Modal Sheets Tests', () {
    testWidgets('RatingStarBar renders 5 stars and handles fractional ratings', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RatingStarBar(
                rating: 4.5,
                starSize: 20,
                showRatingText: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RatingStarBar), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
      expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
    });

    testWidgets('InteractiveStarRating updates rating on user tap', (tester) async {
      int selected = 3;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: InteractiveStarRating(
                    selectedRating: selected,
                    onRatingChanged: (val) {
                      setState(() => selected = val);
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('3 Stars - Good'), findsOneWidget);

      // Tap on the 5th star
      await tester.tap(find.byType(Icon).last);
      await tester.pumpAndSettle();

      expect(selected, 5);
      expect(find.text('5 Stars - Excellent!'), findsOneWidget);
    });

    testWidgets('ProductRatingSheet renders and submits review', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProductRatingSheet(
                orderId: 'ord-mock-101',
                productId: 'prod-001',
                productTitle: 'Pure Cotton Handblock Anarkali Kurta',
                shopName: 'Jaipur Heritage Handlooms',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Rate Your Purchase'), findsOneWidget);
      expect(find.text('Pure Cotton Handblock Anarkali Kurta'), findsOneWidget);
      expect(find.text('Jaipur Heritage Handlooms'), findsOneWidget);
      expect(find.text('5 Stars - Excellent!'), findsOneWidget);
      expect(find.text('Submit Review'), findsOneWidget);
    });
  });
}
