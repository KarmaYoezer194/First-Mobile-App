import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../constants/api_constants.dart';
import '../constants/place_categories.dart';
import '../models/place_prediction.dart';
import '../models/place_result.dart';
import 'places_api_exception.dart';

/// Thin, testable wrapper around the raw Nominatim + Overpass HTTP
/// endpoints. Nothing here knows about Riverpod or the UI — it only
/// turns HTTP responses into typed models or throws [PlacesApiException].
class PlacesApiService {
  final http.Client _client;

  PlacesApiService({required http.Client client}) : _client = client;

  static const String _resultLimit = '60';

  Map<String, String> get _headers => const {
        // Ignored by the browser on Flutter Web (browsers control their
        // own User-Agent), but respected by http on native platforms.
        // Nominatim's usage policy accepts either a valid User-Agent OR
        // a valid HTTP Referer — browsers always send a real Referer.
        'User-Agent': ApiConstants.requestUserAgent,
      };

  Future<dynamic> _getJson(Uri uri) async {
    http.Response response;
    try {
      response = await _client.get(uri, headers: _headers);
    } catch (e) {
      throw PlacesApiException('Network error: $e');
    }

    if (response.statusCode == 429) {
      throw const PlacesApiException(
        'Too many requests — please wait a moment and try again.',
        statusCode: 429,
      );
    }
    if (response.statusCode != 200) {
      throw PlacesApiException('Request failed', statusCode: response.statusCode);
    }

    try {
      return jsonDecode(response.body);
    } catch (e) {
      throw PlacesApiException('Could not parse response: $e');
    }
  }

  /// Search suggestions for the search bar. [bias] softly biases results
  /// toward a location by searching within a loose bounding box around
  /// it first (Nominatim's `viewbox` + `bounded=0` = soft preference,
  /// not a hard restriction).
  Future<List<PlacePrediction>> autocomplete(
    String input, {
    LatLng? bias,
  }) async {
    if (input.trim().isEmpty) return [];

    final params = <String, String>{
      'q': input,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '6',
      if (bias != null) ...{
        'viewbox':
            '${bias.longitude - 0.5},${bias.latitude + 0.5},${bias.longitude + 0.5},${bias.latitude - 0.5}',
        'bounded': '0',
      },
    };

    final uri = Uri.parse(ApiConstants.nominatimSearchEndpoint)
        .replace(queryParameters: params);
    final body = await _getJson(uri);

    if (body is! List) return [];
    return body
        .map((e) => PlacePrediction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Nearby places matching [category] within [radiusMeters] of [location],
  /// queried from OpenStreetMap via the Overpass API.
  Future<List<PlaceResult>> nearbySearch({
    required LatLng location,
    required PlaceCategory category,
    int radiusMeters = ApiConstants.defaultSearchRadiusMeters,
  }) async {
    final filter = category.overpassFilter;
    final around = '(around:$radiusMeters,${location.latitude},${location.longitude})';

    final query = '''
[out:json][timeout:${ApiConstants.overpassTimeoutSeconds}];
(
  node$filter$around;
  way$filter$around;
  relation$filter$around;
);
out center $_resultLimit;
''';

    // The free public Overpass server's fair-use rate limit is a short,
    // rolling window — a 429 almost always clears within a couple of
    // seconds, so retry with backoff instead of failing the whole search
    // on the first hiccup (e.g. two category chips tapped back-to-back).
    const maxAttempts = 3;
    http.Response? response;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        response = await _client.post(
          Uri.parse(ApiConstants.overpassBaseUrl),
          headers: {
            ..._headers,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {'data': query},
        );
      } catch (e) {
        throw PlacesApiException('Network error: $e');
      }

      if (response.statusCode != 429) break;
      if (attempt == maxAttempts) {
        throw const PlacesApiException(
          'Too many requests — please wait a moment and try again.',
          statusCode: 429,
        );
      }
      await Future<void>.delayed(Duration(seconds: attempt * 2));
    }

    if (response!.statusCode != 200) {
      throw PlacesApiException('Nearby search failed', statusCode: response.statusCode);
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw PlacesApiException('Could not parse nearby search response: $e');
    }

    final elements = (body['elements'] as List<dynamic>? ?? []);
    return elements
        .map((e) => PlaceResult.fromOverpassElement(
              e as Map<String, dynamic>,
              categoryLabel: category.label,
            ))
        .where((place) => place.location.latitude != 0 || place.location.longitude != 0)
        .toList();
  }
}
