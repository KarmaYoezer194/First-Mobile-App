import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../models/place_prediction.dart';
import '../repositories/places_repository.dart';
import 'places_providers.dart';

/// Debounces search-bar keystrokes and drives Nominatim search.
///
/// Uses [AppConstants.debounceSlow] rather than the faster
/// [AppConstants.debounceFast] product search uses — this also protects
/// against Nominatim's fair-use policy (roughly 1 request/second), so
/// don't swap in the faster tier here.
class AutocompleteNotifier extends StateNotifier<AsyncValue<List<PlacePrediction>>> {
  final PlacesRepository _repository;
  Timer? _debounce;

  AutocompleteNotifier(this._repository) : super(const AsyncValue.data([]));

  void search(String query, {LatLng? bias}) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    _debounce = Timer(AppConstants.debounceSlow, () async {
      state = const AsyncValue.loading();
      try {
        final results = await _repository.searchAutocomplete(query, bias: bias);
        state = AsyncValue.data(results);
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
    });
  }

  void clear() {
    _debounce?.cancel();
    state = const AsyncValue.data([]);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final autocompleteProvider =
    StateNotifierProvider.autoDispose<AutocompleteNotifier, AsyncValue<List<PlacePrediction>>>(
  (ref) => AutocompleteNotifier(ref.watch(placesRepositoryProvider)),
);
