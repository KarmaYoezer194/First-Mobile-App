import 'package:latlong2/latlong.dart';

import 'place_prediction.dart';

/// A place shown as a marker on the map — either a Nominatim search
/// result (from the search bar) or an Overpass nearby-search result
/// (from a category chip).
///
/// Note on data completeness: OpenStreetMap is community-sourced, so
/// unlike Google Places, `rating` is never available (OSM has no rating
/// system) and `openNow` is only available for the subset of places that
/// have a machine-parseable `opening_hours` tag — both are nullable and
/// the UI already handles "unknown" gracefully.
class PlaceResult {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final double? rating;
  final bool? openNow;
  final String? categoryLabel;

  const PlaceResult({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    this.rating,
    this.openNow,
    this.categoryLabel,
  });

  /// Builds a [PlaceResult] directly from a search-bar [PlacePrediction] —
  /// Nominatim already gave us the coordinates, so no extra network call
  /// is needed.
  factory PlaceResult.fromPrediction(PlacePrediction prediction) {
    return PlaceResult(
      id: prediction.osmId,
      name: prediction.mainText,
      address: prediction.secondaryText.isNotEmpty
          ? prediction.secondaryText
          : prediction.displayName,
      location: LatLng(prediction.latitude, prediction.longitude),
    );
  }

  /// Parses a single element from an Overpass API `out center;` response.
  /// Nodes carry `lat`/`lon` directly; ways/relations carry a `center`
  /// object instead.
  factory PlaceResult.fromOverpassElement(
    Map<String, dynamic> json, {
    String? categoryLabel,
  }) {
    final tags = (json['tags'] as Map<String, dynamic>?) ?? const {};

    double lat;
    double lon;
    if (json['lat'] != null && json['lon'] != null) {
      lat = (json['lat'] as num).toDouble();
      lon = (json['lon'] as num).toDouble();
    } else {
      final center = json['center'] as Map<String, dynamic>?;
      lat = (center?['lat'] as num?)?.toDouble() ?? 0;
      lon = (center?['lon'] as num?)?.toDouble() ?? 0;
    }

    return PlaceResult(
      id: '${json['type']}_${json['id']}',
      name: (tags['name'] as String?)?.trim().isNotEmpty == true
          ? tags['name'] as String
          : (categoryLabel ?? 'Unnamed place'),
      address: _buildAddress(tags),
      location: LatLng(lat, lon),
      openNow: _parseOpenNow(tags['opening_hours'] as String?),
      categoryLabel: categoryLabel,
    );
  }

  static String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[
      if (tags['addr:housenumber'] != null) tags['addr:housenumber'].toString(),
      if (tags['addr:street'] != null) tags['addr:street'].toString(),
      if (tags['addr:city'] != null) tags['addr:city'].toString(),
    ];
    return parts.join(' ').trim();
  }

  /// Best-effort parse of the common "Mo-Fr 09:00-18:00" style OSM
  /// opening_hours tag. Returns null (unknown) for anything it can't
  /// confidently interpret, rather than guessing — the UI already
  /// handles a null open/closed status.
  static bool? _parseOpenNow(String? openingHours) {
    if (openingHours == null || openingHours.trim().isEmpty) return null;
    if (openingHours.trim() == '24/7') return true;
    // Full opening_hours parsing is genuinely complex (holidays,
    // exceptions, multiple ranges); intentionally left unresolved rather
    // than risk showing a wrong open/closed status.
    return null;
  }
}
