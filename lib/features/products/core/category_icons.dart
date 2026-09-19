import 'package:flutter/material.dart';

/// Maps a category slug to a representative icon so the filter chips read
/// at a glance instead of as plain text. Falls back to a generic tag icon
/// for anything not explicitly listed.
///
/// FakeStoreAPI (the current backend) only has four categories, listed
/// first below; the rest are kept around from the previous DummyJSON
/// backend in case that's ever swapped back in — an unrecognized slug just
/// falls back to [fallback], so the extra entries are harmless.
class CategoryIcons {
  CategoryIcons._();

  static const IconData all = Icons.apps_rounded;
  static const IconData fallback = Icons.sell_rounded;

  static const Map<String, IconData> _icons = {
    // FakeStoreAPI
    'electronics': Icons.devices_rounded,
    'jewelery': Icons.diamond_rounded,
    "men's clothing": Icons.checkroom_rounded,
    "women's clothing": Icons.checkroom_rounded,
    // DummyJSON
    'beauty': Icons.face_retouching_natural_rounded,
    'fragrances': Icons.local_florist_rounded,
    'furniture': Icons.chair_rounded,
    'groceries': Icons.local_grocery_store_rounded,
    'home-decoration': Icons.lightbulb_outline_rounded,
    'kitchen-accessories': Icons.kitchen_rounded,
    'laptops': Icons.laptop_mac_rounded,
    'mens-shirts': Icons.checkroom_rounded,
    'mens-shoes': Icons.hiking_rounded,
    'mens-watches': Icons.watch_rounded,
    'mobile-accessories': Icons.headset_rounded,
    'motorcycle': Icons.two_wheeler_rounded,
    'skin-care': Icons.spa_rounded,
    'smartphones': Icons.smartphone_rounded,
    'sports-accessories': Icons.sports_basketball_rounded,
    'sunglasses': Icons.wb_sunny_rounded,
    'tablets': Icons.tablet_mac_rounded,
    'tops': Icons.checkroom_rounded,
    'vehicle': Icons.directions_car_filled_rounded,
    'womens-bags': Icons.shopping_bag_rounded,
    'womens-dresses': Icons.checkroom_rounded,
    'womens-jewellery': Icons.diamond_rounded,
    'womens-shoes': Icons.hiking_rounded,
    'womens-watches': Icons.watch_rounded,
  };

  static IconData iconFor(String slug) => _icons[slug] ?? fallback;
}
