import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

enum PerformanceTimeframe {
  today,
  month,
  year,
}

class PieSliceData {
  final String label;
  final double value;
  final Color color;
  final String? detail;

  const PieSliceData({
    required this.label,
    required this.value,
    required this.color,
    this.detail,
  });
}

class PieDonutChart extends StatelessWidget {
  final List<PieSliceData> slices;
  final String centerTitle;
  final String centerValue;
  final double size;

  const PieDonutChart({
    super.key,
    required this.slices,
    required this.centerTitle,
    required this.centerValue,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    final double total = slices.fold(0.0, (sum, s) => sum + s.value);

    return Column(
      children: [
        // Donut Chart Graphic with Center Metric
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _PieDonutPainter(slices: slices, total: total),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerValue,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    centerTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Legend Grid
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: slices.map((slice) {
            final double pct = total > 0 ? (slice.value / total * 100) : 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: slice.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    slice.label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: slice.color,
                    ),
                  ),
                  if (slice.detail != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${slice.detail})',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PieDonutPainter extends CustomPainter {
  final List<PieSliceData> slices;
  final double total;

  const _PieDonutPainter({required this.slices, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0 || slices.isEmpty) {
      final paint = Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2 - 14, paint);
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 22.0;

    double startAngle = -math.pi / 2;
    const double gapAngle = 0.04;

    for (final slice in slices) {
      final sweepAngle = (slice.value / total) * 2 * math.pi;
      final effectiveSweep = math.max(0.0, sweepAngle - gapAngle);

      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (gapAngle / 2),
        effectiveSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieDonutPainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.total != total;
}

class EngagementBarChart extends StatelessWidget {
  final int views;
  final int wishlistAdds;
  final int bargainsReceived;
  final int bargainsAccepted;

  const EngagementBarChart({
    super.key,
    required this.views,
    required this.wishlistAdds,
    required this.bargainsReceived,
    required this.bargainsAccepted,
  });

  @override
  Widget build(BuildContext context) {
    final int maxVal = math.max(views, math.max(wishlistAdds, math.max(bargainsReceived, bargainsAccepted)));
    final double safeMax = maxVal > 0 ? maxVal.toDouble() : 1.0;

    return Column(
      children: [
        _buildBarRow(
          context: context,
          icon: Icons.visibility_outlined,
          label: 'Customer Store Views',
          value: views,
          color: const Color(0xFF3B82F6),
          ratio: views / safeMax,
        ),
        const SizedBox(height: 10),
        _buildBarRow(
          context: context,
          icon: Icons.favorite_rounded,
          label: 'Wishlist Saves',
          value: wishlistAdds,
          color: AppTheme.primaryColor,
          ratio: wishlistAdds / safeMax,
        ),
        const SizedBox(height: 10),
        _buildBarRow(
          context: context,
          icon: Icons.local_offer_outlined,
          label: 'Bargain Offers Received',
          value: bargainsReceived,
          color: const Color(0xFFF59E0B),
          ratio: bargainsReceived / safeMax,
        ),
        const SizedBox(height: 10),
        _buildBarRow(
          context: context,
          icon: Icons.handshake_outlined,
          label: 'Bargains Closed & Agreed',
          value: bargainsAccepted,
          color: AppTheme.successColor,
          ratio: bargainsAccepted / safeMax,
        ),
      ],
    );
  }

  Widget _buildBarRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required double ratio,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
              ],
            ),
            Text(
              '$value',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: math.max(0.04, ratio.clamp(0.0, 1.0)),
            minHeight: 8,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
