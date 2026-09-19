import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../constants/place_categories.dart';
import '../models/place_result.dart';

/// The live flutter_map MapController, set once the map finishes creating.
final mapControllerProvider = Provider.autoDispose<MapController>((ref) {
  final controller = MapController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// The currently-selected category chip (null = none selected).
final selectedCategoryProvider = StateProvider<PlaceCategory?>((ref) => null);

/// The place dropped as a marker when the user picks a search-bar result.
final searchResultProvider = StateProvider<PlaceResult?>((ref) => null);

/// Tracks the map's current center so category search always searches
/// "around where the user is currently looking", not just their original
/// GPS fix.
final mapCenterProvider = StateProvider<LatLng?>((ref) => null);
