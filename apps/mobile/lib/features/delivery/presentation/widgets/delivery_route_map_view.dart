import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/map_navigation_launcher.dart';
import '../../domain/delivery_task_model.dart';

class DeliveryRouteMapView extends StatefulWidget {
  final DeliveryTaskModel trip;
  final bool isPickedUp;

  const DeliveryRouteMapView({
    super.key,
    required this.trip,
    required this.isPickedUp,
  });

  @override
  State<DeliveryRouteMapView> createState() => _DeliveryRouteMapViewState();
}

class _DeliveryRouteMapViewState extends State<DeliveryRouteMapView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _launchActiveGoogleMaps() {
    final targetLat = widget.isPickedUp ? widget.trip.dropLat : widget.trip.shopLat;
    final targetLng = widget.isPickedUp ? widget.trip.dropLng : widget.trip.shopLng;
    final targetName = widget.isPickedUp ? widget.trip.customerName : widget.trip.shopName;
    final targetAddress = widget.isPickedUp ? widget.trip.dropAddress : widget.trip.shopAddress;

    MapNavigationLauncher.openGoogleMaps(
      latitude: targetLat,
      longitude: targetLng,
      destinationName: targetName,
      address: targetAddress,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final isPickedUp = widget.isPickedUp;
    final currentTargetName = isPickedUp ? trip.customerName : trip.shopName;
    final currentTargetAddress = isPickedUp ? trip.dropAddress : trip.shopAddress;
    final currentDistance = isPickedUp ? trip.distanceToCustomerKm : trip.distanceToShopKm;
    final etaMinutes = math.max(3, (currentDistance * 3.5).round());

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Premium Dark Map Aesthetic
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Interactive Animated Map Canvas with Route Path
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                // Custom Map Background & Route Polyline Painter
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _LiveRouteMapPainter(
                          progress: _animController.value,
                          isPickedUp: isPickedUp,
                        ),
                      );
                    },
                  ),
                ),

                // Top Floating Status HUD
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.successColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'GPS Active • Live Path',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$currentDistance km • ~$etaMinutes min',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Left Turn Direction Pill
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.turn_right, color: Color(0xFF38BDF8), size: 18),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isPickedUp ? 'In 300m, Turn Right' : 'In 150m, Turn Left',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isPickedUp ? 'Towards Customer Landmark' : 'Towards Johari Bazaar Store',
                              style: const TextStyle(color: Colors.white70, fontSize: 9),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Navigation Action Bottom Bar
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isPickedUp
                          ? AppTheme.accentColor.withValues(alpha: 0.12)
                          : AppTheme.primaryColor.withValues(alpha: 0.12),
                      child: Icon(
                        isPickedUp ? Icons.home_rounded : Icons.storefront_rounded,
                        size: 18,
                        color: isPickedUp ? AppTheme.accentColor : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPickedUp ? 'Target: $currentTargetName (Drop-off)' : 'Target: $currentTargetName (Pickup)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                          ),
                          Text(
                            currentTargetAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Primary Google Maps Launch Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _launchActiveGoogleMaps,
                    icon: const Icon(Icons.directions, size: 20),
                    label: Text(
                      isPickedUp
                          ? 'Open Google Maps Navigation to Customer'
                          : 'Open Google Maps Navigation to Boutique',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB), // Google Maps Primary Blue
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRouteMapPainter extends CustomPainter {
  final double progress;
  final bool isPickedUp;

  _LiveRouteMapPainter({required this.progress, required this.isPickedUp});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Grid Roads & Streets
    final roadPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final minorRoadPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Horizontal & vertical grid lines simulating city blocks
    for (double y = 30; y < size.height; y += 45) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorRoadPaint);
    }
    for (double x = 40; x < size.width; x += 55) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorRoadPaint);
    }

    // Main Avenue
    canvas.drawLine(Offset(0, size.height * 0.45), Offset(size.width, size.height * 0.45), roadPaint);
    canvas.drawLine(Offset(size.width * 0.65, 0), Offset(size.width * 0.65, size.height), roadPaint);

    // 2. Define Route Path from Driver (Start) to Destination (End)
    final startPoint = Offset(size.width * 0.15, size.height * 0.75);
    final midPoint1 = Offset(size.width * 0.42, size.height * 0.75);
    final midPoint2 = Offset(size.width * 0.42, size.height * 0.35);
    final endPoint = Offset(size.width * 0.82, size.height * 0.35);

    final path = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..lineTo(midPoint1.dx, midPoint1.dy)
      ..lineTo(midPoint2.dx, midPoint2.dy)
      ..lineTo(endPoint.dx, endPoint.dy);

    // Glow Route Shadow
    final glowPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.35)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, glowPaint);

    // Solid Route Line
    final activePathPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, activePathPaint);

    // 3. Compute Current Rider Position along the Path
    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final currentDistance = metric.length * progress;
      final tangent = metric.getTangentForOffset(currentDistance);

      if (tangent != null) {
        final riderPos = tangent.position;

        // Pulse Circle under Rider
        final pulseRadius = 14 + (math.sin(progress * 2 * math.pi) * 4);
        final pulsePaint = Paint()
          ..color = const Color(0xFF22C55E).withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(riderPos, pulseRadius, pulsePaint);

        // Rider Icon Pin
        final riderPaint = Paint()..color = const Color(0xFF22C55E);
        canvas.drawCircle(riderPos, 8, riderPaint);
        final innerRiderPaint = Paint()..color = Colors.white;
        canvas.drawCircle(riderPos, 3.5, innerRiderPaint);
      }
    }

    // 4. Start Point Pin (Delivery Partner Origin)
    final startPinPaint = Paint()..color = const Color(0xFF64748B);
    canvas.drawCircle(startPoint, 6, startPinPaint);

    // 5. Destination Pin (Store or Customer)
    final destPinColor = isPickedUp ? const Color(0xFFF43F5E) : const Color(0xFFEC4899);
    final destPulsePaint = Paint()
      ..color = destPinColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endPoint, 16, destPulsePaint);

    final destPinPaint = Paint()..color = destPinColor;
    canvas.drawCircle(endPoint, 9, destPinPaint);
    final destCenterPaint = Paint()..color = Colors.white;
    canvas.drawCircle(endPoint, 4, destCenterPaint);
  }

  @override
  bool shouldRepaint(covariant _LiveRouteMapPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isPickedUp != isPickedUp;
}
