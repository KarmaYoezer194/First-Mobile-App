/// Thrown when a Nominatim/Overpass request fails, or returns something
/// the app can't parse. Carries an optional [statusCode] so the UI can
/// distinguish e.g. a rate-limit (429) from a generic failure.
class PlacesApiException implements Exception {
  final String message;
  final int? statusCode;

  const PlacesApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'PlacesApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}
