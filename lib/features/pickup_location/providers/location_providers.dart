import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../repositories/location_repository.dart';
import '../services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepositoryImpl(ref.watch(locationServiceProvider));
});

/// Fetches the user's current position once. UI can call
/// `ref.invalidate(currentPositionProvider)` to re-fetch (e.g. from the
/// recenter button) which re-runs this FutureProvider.
final currentPositionProvider = FutureProvider.autoDispose<Position>((ref) async {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.getCurrentPosition();
});
