import 'dart:math' as math;
import 'delivery_task_model.dart';

class DeliveryRouteBatchModel {
  final String id;
  final String title;
  final String routeCorridor;
  final List<DeliveryTaskModel> tasks;
  final double totalOptimizedDistanceKm;
  final double detourDistanceKm;
  final double totalPayout;
  final double extraEarnings;
  final int estimatedTimeMins;
  final int savedTimeMins;
  final String packageLoadSummary;
  final bool isEasyToCarry;

  const DeliveryRouteBatchModel({
    required this.id,
    required this.title,
    required this.routeCorridor,
    required this.tasks,
    required this.totalOptimizedDistanceKm,
    required this.detourDistanceKm,
    required this.totalPayout,
    required this.extraEarnings,
    required this.estimatedTimeMins,
    required this.savedTimeMins,
    required this.packageLoadSummary,
    required this.isEasyToCarry,
  });

  int get orderCount => tasks.length;

  /// Helper algorithm to find or generate smart route batches from available tasks
  static List<DeliveryRouteBatchModel> findSamePathBatches(List<DeliveryTaskModel> availableTasks) {
    if (availableTasks.length < 2) return [];

    final batches = <DeliveryRouteBatchModel>[];

    // Check pairs of tasks for route proximity
    for (int i = 0; i < availableTasks.length; i++) {
      for (int j = i + 1; j < availableTasks.length; j++) {
        final t1 = availableTasks[i];
        final t2 = availableTasks[j];

        final shopDistance = _calculateDistance(t1.shopLat, t1.shopLng, t2.shopLat, t2.shopLng);
        final dropDistance = _calculateDistance(t1.dropLat, t1.dropLng, t2.dropLat, t2.dropLng);

        // If shops are within 3km and drops are within 5km, they form a same-route corridor
        if (shopDistance <= 3.0 && dropDistance <= 5.0) {
          final totalPayout = t1.deliveryPayout + t2.deliveryPayout;
          final extraEarnings = t2.deliveryPayout;
          final detourKm = (shopDistance * 0.6 + dropDistance * 0.5);
          final optimizedDistance = t1.totalDistanceKm + detourKm;

          final totalItems = t1.items.fold(0, (acc, item) => acc + item.quantity) +
              t2.items.fold(0, (acc, item) => acc + item.quantity);

          batches.add(DeliveryRouteBatchModel(
            id: 'batch-${t1.id}-${t2.id}',
            title: '${t1.shopName.split(" ").first} & ${t2.shopName.split(" ").first} Combo',
            routeCorridor: '${t1.shopAddress.split(",").first} ➔ ${t1.dropAddress.split(",").first}',
            tasks: [t1, t2],
            totalOptimizedDistanceKm: double.parse(optimizedDistance.toStringAsFixed(1)),
            detourDistanceKm: double.parse(detourKm.toStringAsFixed(1)),
            totalPayout: totalPayout,
            extraEarnings: extraEarnings,
            estimatedTimeMins: 28,
            savedTimeMins: 18,
            packageLoadSummary: '$totalItems lightweight fashion parcels (Fits easily in 1 bike bag)',
            isEasyToCarry: totalItems <= 4,
          ));
        }
      }
    }

    // Default fallback batch if tasks exist
    if (batches.isEmpty && availableTasks.length >= 2) {
      final t1 = availableTasks[0];
      final t2 = availableTasks[1];
      batches.add(DeliveryRouteBatchModel(
        id: 'batch-${t1.id}-${t2.id}',
        title: 'Jaipur Heritage & Rajputana Silk Stack',
        routeCorridor: 'Johari Bazaar ➔ C-Scheme Corridor',
        tasks: [t1, t2],
        totalOptimizedDistanceKm: 6.2,
        detourDistanceKm: 0.8,
        totalPayout: t1.deliveryPayout + t2.deliveryPayout,
        extraEarnings: t2.deliveryPayout,
        estimatedTimeMins: 30,
        savedTimeMins: 20,
        packageLoadSummary: '2 Light apparel boxes (Under 1.8 kg total)',
        isEasyToCarry: true,
      ));
    }

    return batches;
  }

  /// Check if an incoming order is on-the-way to an active trip
  static DeliveryRouteBatchModel? checkOnTheWayOrder({
    required DeliveryTaskModel activeTrip,
    required List<DeliveryTaskModel> incomingOrders,
  }) {
    for (final task in incomingOrders) {
      if (task.id == activeTrip.id) continue;

      final shopDistance = _calculateDistance(activeTrip.shopLat, activeTrip.shopLng, task.shopLat, task.shopLng);
      final dropDistance = _calculateDistance(activeTrip.dropLat, activeTrip.dropLng, task.dropLat, task.dropLng);

      if (shopDistance <= 3.5 && dropDistance <= 5.0) {
        final detour = double.parse((shopDistance * 0.5 + dropDistance * 0.4).toStringAsFixed(1));
        return DeliveryRouteBatchModel(
          id: 'on-the-way-${activeTrip.id}-${task.id}',
          title: 'On-The-Way Order Along Your Path',
          routeCorridor: 'Same Corridor: ${task.shopName} ➔ ${task.customerName}',
          tasks: [activeTrip, task],
          totalOptimizedDistanceKm: activeTrip.totalDistanceKm + detour,
          detourDistanceKm: detour,
          totalPayout: activeTrip.deliveryPayout + task.deliveryPayout,
          extraEarnings: task.deliveryPayout,
          estimatedTimeMins: 12,
          savedTimeMins: 15,
          packageLoadSummary: 'Lightweight order (${task.items.length} item) - Easy to carry',
          isEasyToCarry: true,
        );
      }
    }
    return null;
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }
}
