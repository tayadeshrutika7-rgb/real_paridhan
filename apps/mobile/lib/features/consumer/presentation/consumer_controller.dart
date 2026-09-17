import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../seller/domain/product_model.dart';
import '../data/consumer_repository.dart';
import '../domain/nearby_shop.dart';

class ConsumerDiscoveryState {
  final bool isLoading;
  final double currentLat;
  final double currentLng;
  final String locationLabel;
  final List<NearbyShop> nearbyShops;
  final List<ProductModel> featuredProducts;
  final String? errorMessage;

  const ConsumerDiscoveryState({
    this.isLoading = false,
    this.currentLat = 26.9124, // Jaipur
    this.currentLng = 75.7873,
    this.locationLabel = 'Johari Bazaar, Jaipur',
    this.nearbyShops = const [],
    this.featuredProducts = const [],
    this.errorMessage,
  });

  ConsumerDiscoveryState copyWith({
    bool? isLoading,
    double? currentLat,
    double? currentLng,
    String? locationLabel,
    List<NearbyShop>? nearbyShops,
    List<ProductModel>? featuredProducts,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ConsumerDiscoveryState(
      isLoading: isLoading ?? this.isLoading,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      locationLabel: locationLabel ?? this.locationLabel,
      nearbyShops: nearbyShops ?? this.nearbyShops,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ConsumerController extends Notifier<ConsumerDiscoveryState> {
  late final ConsumerRepository _repository;

  @override
  ConsumerDiscoveryState build() {
    _repository = ConsumerRepository();
    // Schedule discovery loading
    Future.microtask(() => loadDiscovery());
    return const ConsumerDiscoveryState(isLoading: true);
  }

  Future<void> loadDiscovery() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final shops = await _repository.getNearbyShops(
        latitude: state.currentLat,
        longitude: state.currentLng,
        radiusKm: 10.0,
      );
      final products = await _repository.searchProducts(query: '');

      state = state.copyWith(
        isLoading: false,
        nearbyShops: shops,
        featuredProducts: products,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load discovery data: $e',
      );
    }
  }

  void updateLocation(double lat, double lng, String label) {
    state = state.copyWith(currentLat: lat, currentLng: lng, locationLabel: label);
    loadDiscovery();
  }
}

final consumerProvider = NotifierProvider<ConsumerController, ConsumerDiscoveryState>(() {
  return ConsumerController();
});
