import 'package:latlong2/latlong.dart';

import '../constants/place_categories.dart';
import '../models/place_prediction.dart';
import '../models/place_result.dart';
import '../services/places_api_service.dart';

/// Abstract contract for place search/lookup. Keeping this as an interface
/// makes it trivial to mock in tests or swap the data source later.
abstract class PlacesRepository {
  Future<List<PlacePrediction>> searchAutocomplete(String query, {LatLng? bias});
  Future<List<PlaceResult>> getNearbyPlaces({
    required LatLng location,
    required PlaceCategory category,
    int radiusMeters,
  });
}

class PlacesRepositoryImpl implements PlacesRepository {
  final PlacesApiService _apiService;

  PlacesRepositoryImpl(this._apiService);

  @override
  Future<List<PlacePrediction>> searchAutocomplete(
    String query, {
    LatLng? bias,
  }) {
    return _apiService.autocomplete(query, bias: bias);
  }

  @override
  Future<List<PlaceResult>> getNearbyPlaces({
    required LatLng location,
    required PlaceCategory category,
    int radiusMeters = 5000,
  }) {
    return _apiService.nearbySearch(
      location: location,
      category: category,
      radiusMeters: radiusMeters,
    );
  }
}
