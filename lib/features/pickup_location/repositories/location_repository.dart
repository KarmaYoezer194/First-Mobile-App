import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';

/// Abstract contract for device location access.
abstract class LocationRepository {
  Future<Position> getCurrentPosition();
}

class LocationRepositoryImpl implements LocationRepository {
  final LocationService _locationService;

  LocationRepositoryImpl(this._locationService);

  @override
  Future<Position> getCurrentPosition() {
    return _locationService.getCurrentPosition();
  }
}
