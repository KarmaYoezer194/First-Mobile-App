/// A single search suggestion returned by the Nominatim `/search`
/// endpoint. Unlike Google's Autocomplete, Nominatim returns the full
/// lat/lon with every suggestion — no separate "place details" call is
/// needed once the user picks one.
class PlacePrediction {
  final String osmId;
  final String displayName;
  final String mainText;
  final String secondaryText;
  final double latitude;
  final double longitude;

  const PlacePrediction({
    required this.osmId,
    required this.displayName,
    required this.mainText,
    required this.secondaryText,
    required this.latitude,
    required this.longitude,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final displayName = json['display_name'] as String? ?? '';
    final parts = displayName.split(',');
    final mainText = parts.isNotEmpty ? parts.first.trim() : displayName;
    final secondaryText = parts.length > 1 ? parts.skip(1).join(',').trim() : '';

    return PlacePrediction(
      osmId: '${json['osm_type']}_${json['osm_id']}',
      displayName: displayName,
      mainText: mainText,
      secondaryText: secondaryText,
      latitude: double.tryParse(json['lat']?.toString() ?? '') ?? 0,
      longitude: double.tryParse(json['lon']?.toString() ?? '') ?? 0,
    );
  }
}
