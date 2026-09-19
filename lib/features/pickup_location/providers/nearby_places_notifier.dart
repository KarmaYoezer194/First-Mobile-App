import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../constants/place_categories.dart';
import '../models/place_result.dart';
import '../repositories/places_repository.dart';
import 'places_providers.dart';

/// Holds the results of the currently-selected category search.
/// Calling [fetch] with a new category *replaces* the state entirely, so
/// markers from the previously-selected category disappear automatically
/// once the UI rebuilds from this provider.
class NearbyPlacesNotifier extends StateNotifier<AsyncValue<List<PlaceResult>>> {
  final PlacesRepository _repository;

  NearbyPlacesNotifier(this._repository) : super(const AsyncValue.data([]));

  Future<void> fetch({
    required PlaceCategory category,
    required LatLng location,
  }) async {
    state = const AsyncValue.loading();
    try {
      final results = await _repository.getNearbyPlaces(
        location: location,
        category: category,
      );
      state = AsyncValue.data(results);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clear() => state = const AsyncValue.data([]);
}

final nearbyPlacesProvider =
    StateNotifierProvider<NearbyPlacesNotifier, AsyncValue<List<PlaceResult>>>(
  (ref) => NearbyPlacesNotifier(ref.watch(placesRepositoryProvider)),
);
