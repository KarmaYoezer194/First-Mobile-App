/// API configuration for the Pickup Location feature.
///
/// This feature runs entirely on free, keyless OpenStreetMap services:
///   - Nominatim  -> search / autocomplete
///   - Overpass   -> nearby category search
///   - OSM raster tiles -> the map background itself
///
/// No API key, no billing account, and no Google Cloud Console setup are
/// required anywhere in this feature.
///
/// IMPORTANT — usage policy: both Nominatim and the public OSM tile
/// server are free community-run services with fair-use limits (roughly
/// one request per second, no heavy automated/bulk use). That's more
/// than enough for normal app usage and development, but if this app
/// ever gets real production traffic, switch to either self-hosted
/// tiles/Nominatim or a paid OSM-compatible provider (e.g. MapTiler,
/// Stadia Maps, Thunderforest all have free tiers with no card required
/// to start, and paid tiers if you outgrow them).
class ApiConstants {
  ApiConstants._();

  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String nominatimSearchEndpoint = '$nominatimBaseUrl/search';

  static const String overpassBaseUrl = 'https://overpass-api.de/api/interpreter';

  /// OSM tile server. Attribution ("© OpenStreetMap contributors") is
  /// legally required and is already wired into the map widget — do not
  /// remove the AttributionWidget in pickup_location_screen.dart.
  static const String osmTileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Sent as the User-Agent on Nominatim/Overpass requests where the
  /// http client allows it (native platforms). On Flutter Web, browsers
  /// block overriding User-Agent — Nominatim's usage policy accepts
  /// either a valid User-Agent OR a valid HTTP Referer, and browsers
  /// send a real Referer automatically, so this is still policy-
  /// compliant on web.
  static const String requestUserAgent = 'TaskFlowPickupLocationDemo/1.0';

  /// Default search radius for nearby category search, in meters.
  static const int defaultSearchRadiusMeters = 5000;

  /// Overpass query timeout, in seconds.
  static const int overpassTimeoutSeconds = 25;
}
