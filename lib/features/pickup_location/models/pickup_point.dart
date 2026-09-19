/// The value returned to the calling screen when the user confirms a
/// pickup location. This is the ONLY data this feature hands back to the
/// rest of the app — nothing is persisted here.
class PickupPoint {
  final String placeName;
  final String address;
  final double latitude;
  final double longitude;
  final String category;

  const PickupPoint({
    required this.placeName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'placeName': placeName,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'category': category,
      };

  @override
  String toString() =>
      'PickupPoint(placeName: $placeName, address: $address, '
      'latitude: $latitude, longitude: $longitude, category: $category)';
}
