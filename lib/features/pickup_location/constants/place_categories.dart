import 'package:flutter/material.dart';

/// A category chip shown above the map. [tagKey]/[tagValue] identify the
/// matching OpenStreetMap tag used to query the Overpass API, e.g.
/// amenity=cafe, shop=bakery. See https://wiki.openstreetmap.org/wiki/Map_features
class PlaceCategory {
  final String label;
  final String tagKey;
  final String tagValue;
  final IconData icon;
  final Color color;

  const PlaceCategory({
    required this.label,
    required this.tagKey,
    required this.tagValue,
    required this.icon,
    required this.color,
  });

  /// The Overpass QL tag filter fragment for this category, e.g. `["amenity"="cafe"]`.
  String get overpassFilter => '["$tagKey"="$tagValue"]';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaceCategory && other.tagKey == tagKey && other.tagValue == tagValue);

  @override
  int get hashCode => Object.hash(tagKey, tagValue);
}

/// The fixed list of categories required by the Pickup Location feature,
/// each mapped to a real OpenStreetMap tag.
class PlaceCategories {
  PlaceCategories._();

  static const List<PlaceCategory> all = [
    PlaceCategory(label: 'Gas Station', tagKey: 'amenity', tagValue: 'fuel', icon: Icons.local_gas_station, color: Color(0xFFF97316)),
    PlaceCategory(label: 'Mall', tagKey: 'shop', tagValue: 'mall', icon: Icons.local_mall, color: Color(0xFF8B5CF6)),
    PlaceCategory(label: 'Bakery', tagKey: 'shop', tagValue: 'bakery', icon: Icons.bakery_dining, color: Color(0xFFEC4899)),
    PlaceCategory(label: 'Salon', tagKey: 'shop', tagValue: 'hairdresser', icon: Icons.content_cut, color: Color(0xFFD946EF)),
    PlaceCategory(label: 'Post Office', tagKey: 'amenity', tagValue: 'post_office', icon: Icons.local_post_office, color: Color(0xFF0EA5E9)),
    PlaceCategory(label: 'Cafe', tagKey: 'amenity', tagValue: 'cafe', icon: Icons.local_cafe, color: Color(0xFFEAB308)),
    PlaceCategory(label: 'Restaurant', tagKey: 'amenity', tagValue: 'restaurant', icon: Icons.restaurant, color: Color(0xFFEF4444)),
    PlaceCategory(label: 'Hospital', tagKey: 'amenity', tagValue: 'hospital', icon: Icons.local_hospital, color: Color(0xFFDC2626)),
    PlaceCategory(label: 'Pharmacy', tagKey: 'amenity', tagValue: 'pharmacy', icon: Icons.local_pharmacy, color: Color(0xFF10B981)),
    PlaceCategory(label: 'Bank', tagKey: 'amenity', tagValue: 'bank', icon: Icons.account_balance, color: Color(0xFF2563EB)),
  ];

  // DummyJSON product category slugs that have an obviously closer match
  // among [all] than the generic "Mall" default. Kept small and honest —
  // most retail categories (electronics, furniture, apparel...) don't map
  // to any of the 10 real-world OSM tags this feature queries, so they
  // fall back to Mall rather than being forced into a misleading category.
  static const Map<String, String> _productCategoryOverrides = {
    'beauty': 'Salon',
    'fragrances': 'Salon',
    'skin-care': 'Salon',
    'skincare': 'Salon',
    'groceries': 'Mall',
    'vehicle': 'Gas Station',
    'motorcycle': 'Gas Station',
  };

  /// Best-effort [PlaceCategory] for a DummyJSON product category slug (e.g.
  /// "beauty", "smartphones"), used to preselect a map category chip when
  /// jumping to the pickup map from a product's detail page. Falls back to
  /// Mall, the closest general-purpose "buy things here" category.
  static PlaceCategory forProductCategory(String productCategorySlug) {
    final label = _productCategoryOverrides[productCategorySlug.toLowerCase().trim()];
    if (label == null) return all.firstWhere((c) => c.label == 'Mall');
    return all.firstWhere((c) => c.label == label);
  }
}
