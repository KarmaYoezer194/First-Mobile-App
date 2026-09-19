import 'package:geolocator/geolocator.dart';

/// Thrown for every location-permission or location-service failure so the
/// UI layer can render a precise, actionable error state.
class LocationServiceException implements Exception {
  final String message;
  const LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}

/// Thin wrapper around `geolocator` — handles permission requests and
/// fetching the current device position.
class LocationService {
  /// Ensures location services are enabled and permission is granted.
  /// Throws [LocationServiceException] with a user-facing message otherwise.
  Future<void> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException(
        'Location services are disabled. Please enable them to continue.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationServiceException(
          'Location permission was denied.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Location permission is permanently denied. '
        'Please enable it from app settings.',
      );
    }
  }

  /// Returns the current device position. Requests permission first if
  /// necessary.
  Future<Position> getCurrentPosition() async {
    await ensurePermission();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
}
