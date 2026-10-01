import 'package:flutter/material.dart';

class RatingStarBar extends StatelessWidget {
  final double rating;
  final double starSize;
  final Color starColor;
  final Color emptyColor;
  final int maxRating;
  final bool showRatingText;
  final TextStyle? textStyle;

  const RatingStarBar({
    super.key,
    required this.rating,
    this.starSize = 16.0,
    this.starColor = const Color(0xFFF59E0B), // Amber gold
    this.emptyColor = const Color(0xFFE5E7EB),
    this.maxRating = 5,
    this.showRatingText = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...List.generate(maxRating, (index) {
          final currentStarValue = index + 1;
          if (rating >= currentStarValue) {
            // Full star
            return Icon(Icons.star_rounded, size: starSize, color: starColor);
          } else if (rating >= currentStarValue - 0.5) {
            // Half star
            return Icon(Icons.star_half_rounded, size: starSize, color: starColor);
          } else {
            // Empty star
            return Icon(Icons.star_outline_rounded, size: starSize, color: emptyColor);
          }
        }),
        if (showRatingText) ...[
          const SizedBox(width: 6),
          Text(
            rating > 0 ? rating.toStringAsFixed(1) : 'No reviews',
            style: textStyle ??
                const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1F2937),
                ),
          ),
        ],
      ],
    );
  }
}

class InteractiveStarRating extends StatelessWidget {
  final int selectedRating;
  final ValueChanged<int> onRatingChanged;
  final double starSize;
  final Color activeColor;
  final Color inactiveColor;

  const InteractiveStarRating({
    super.key,
    required this.selectedRating,
    required this.onRatingChanged,
    this.starSize = 36.0,
    this.activeColor = const Color(0xFFF59E0B),
    this.inactiveColor = const Color(0xFFD1D5DB),
  });

  String get _ratingLabel {
    switch (selectedRating) {
      case 1:
        return '1 Star - Poor';
      case 2:
        return '2 Stars - Fair';
      case 3:
        return '3 Stars - Good';
      case 4:
        return '4 Stars - Very Good';
      case 5:
        return '5 Stars - Excellent!';
      default:
        return 'Tap a star to rate';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            final isFilled = starNumber <= selectedRating;
            return GestureDetector(
              onTap: () => onRatingChanged(starNumber),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedScale(
                  scale: isFilled ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: starSize,
                    color: isFilled ? activeColor : inactiveColor,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _ratingLabel,
            key: ValueKey(selectedRating),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: selectedRating > 0 ? const Color(0xFFD97706) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }
}
