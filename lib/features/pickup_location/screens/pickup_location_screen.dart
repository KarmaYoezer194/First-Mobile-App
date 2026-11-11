import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../constants/api_constants.dart';
import '../constants/place_categories.dart';
import '../models/place_prediction.dart';
import '../models/place_result.dart';
import '../providers/location_providers.dart';
import '../providers/map_state_providers.dart';
import '../providers/nearby_places_notifier.dart';
import '../services/location_service.dart';
import '../utils/marker_icon_utils.dart';
import '../widgets/category_chips_bar.dart';
import '../widgets/map_status_views.dart';
import '../widgets/place_details_bottom_sheet.dart';
import '../widgets/place_search_bar.dart';
import '../widgets/recenter_fab.dart';

/// Entry point for the Pickup Location feature. Registered as the
/// `/pickup-location` route in `app_router.dart` — push it and await its
/// result the same way `Navigator.push` would work, but with real
/// deep-link/back-button behavior since GoRouter knows about it:
///
/// ```dart
/// final pickupPoint = await context.push<PickupPoint>('/pickup-location');
/// if (pickupPoint != null) {
///   // use pickupPoint.placeName / address / latitude / longitude / category
/// }
/// ```
///
/// To preselect a category chip (e.g. from a product's "Find pickup near
/// me" tile), pass it as `extra`:
///
/// ```dart
/// context.push<PickupPoint>('/pickup-location', extra: placeCategory);
/// ```
///
/// Runs entirely on free OpenStreetMap services (flutter_map tiles +
/// Nominatim search + Overpass nearby search) — no API key, no billing
/// account, no Google Cloud Console setup required.
class PickupLocationScreen extends ConsumerStatefulWidget {
  const PickupLocationScreen({super.key, this.initialCategory});

  /// When set (e.g. jumping here from a product's detail page), this
  /// category chip is selected and searched automatically as soon as the
  /// map has a center to search around — the user lands on the map already
  /// looking at nearby places relevant to that product.
  final PlaceCategory? initialCategory;

  @override
  ConsumerState<PickupLocationScreen> createState() => _PickupLocationScreenState();
}

class _PickupLocationScreenState extends ConsumerState<PickupLocationScreen> {
  static const double _defaultZoom = 15;

  bool _isRecentering = false;
  bool _initialCategoryApplied = false;
  LatLng? _userLocation;
  StreamSubscription<MapEvent>? _mapEventSubscription;

  @override
  void initState() {
    super.initState();
    // Track the map's current center as the user pans/zooms, so category
    // search always searches around what's currently on screen. Using the
    // controller's own event stream (rather than a MapOptions callback)
    // keeps this working across flutter_map versions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapEventSubscription = ref.read(mapControllerProvider).mapEventStream.listen((event) {
        ref.read(mapCenterProvider.notifier).state = event.camera.center;
      });
    });
  }

  @override
  void dispose() {
    _mapEventSubscription?.cancel();
    super.dispose();
  }

  void _moveCamera(LatLng target, {double zoom = _defaultZoom}) {
    ref.read(mapControllerProvider).move(target, zoom);
  }

  Future<void> _handleRecenter() async {
    setState(() => _isRecentering = true);
    try {
      final repository = ref.read(locationRepositoryProvider);
      final position = await repository.getCurrentPosition();
      final target = LatLng(position.latitude, position.longitude);
      setState(() => _userLocation = target);
      ref.read(mapCenterProvider.notifier).state = target;
      _moveCamera(target);
    } on LocationServiceException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('Could not get your location: $e');
    } finally {
      if (mounted) setState(() => _isRecentering = false);
    }
  }

  Future<void> _handleCategorySelected(PlaceCategory category) async {
    // Ignore a chip tap while a search is already in flight — rapid
    // chip-switching would otherwise fire overlapping Overpass requests
    // and trip the free server's fair-use rate limit (HTTP 429).
    if (ref.read(nearbyPlacesProvider).isLoading) return;

    ref.read(selectedCategoryProvider.notifier).state = category;

    final center = ref.read(mapCenterProvider) ?? _userLocation;
    if (center == null) {
      _showSnackBar('Waiting for your location. Please try again in a moment.');
      return;
    }

    await ref.read(nearbyPlacesProvider.notifier).fetch(
          category: category,
          location: center,
        );
  }

  void _handlePlaceSelectedFromSearch(PlacePrediction prediction) {
    final place = PlaceResult.fromPrediction(prediction);
    ref.read(searchResultProvider.notifier).state = place;
    ref.read(mapCenterProvider.notifier).state = place.location;
    _moveCamera(place.location);
  }

  Future<void> _handleMarkerTap(PlaceResult place, String categoryLabel) async {
    final pickupPoint = await PlaceDetailsBottomSheet.show(
      context,
      place: place,
      category: categoryLabel,
    );

    if (pickupPoint != null && mounted) {
      Navigator.of(context).pop(pickupPoint);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<Marker> _buildMarkers(List<PlaceResult> nearbyPlaces, PlaceCategory? category) {
    final markers = <Marker>[];

    for (final place in nearbyPlaces) {
      markers.add(
        Marker(
          point: place.location,
          width: 36,
          height: 36,
          child: GestureDetector(
            onTap: () => _handleMarkerTap(place, category?.label ?? 'Place'),
            child: CategoryMarkerPin(
              icon: category?.icon ?? Icons.place,
              color: category?.color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    final searchResult = ref.watch(searchResultProvider);
    if (searchResult != null) {
      markers.add(
        Marker(
          point: searchResult.location,
          width: 36,
          height: 36,
          child: GestureDetector(
            onTap: () => _handleMarkerTap(searchResult, 'Search Result'),
            child: const SearchResultMarkerPin(),
          ),
        ),
      );
    }

    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 20,
          height: 20,
          child: const UserLocationMarkerPin(),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(currentPositionProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final nearbyPlacesAsync = ref.watch(nearbyPlacesProvider);
    final mapController = ref.watch(mapControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Pickup Location')),
      body: positionAsync.when(
        loading: () => const MapLoadingView(),
        error: (error, _) => MapErrorView(
          message: error is LocationServiceException
              ? error.message
              : 'Something went wrong while getting your location.',
          onRetry: () => ref.invalidate(currentPositionProvider),
        ),
        data: (position) {
          final initialTarget = LatLng(position.latitude, position.longitude);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref.read(mapCenterProvider.notifier).state ??= initialTarget;
            if (_userLocation == null) setState(() => _userLocation = initialTarget);

            final initialCategory = widget.initialCategory;
            if (initialCategory != null && !_initialCategoryApplied) {
              _initialCategoryApplied = true;
              _handleCategorySelected(initialCategory);
            }
          });

          return Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: initialTarget,
                  initialZoom: _defaultZoom,
                ),
                children: [
                  TileLayer(
                    urlTemplate: ApiConstants.osmTileUrlTemplate,
                    userAgentPackageName: 'com.example.pickup_location_demo',
                  ),
                  MarkerLayer(
                    markers: _buildMarkers(nearbyPlacesAsync.valueOrNull ?? const [], selectedCategory),
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('© OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),

              // Search bar + category chips overlay
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PlaceSearchBar(
                        locationBias: ref.watch(mapCenterProvider) ?? initialTarget,
                        onPlaceSelected: _handlePlaceSelectedFromSearch,
                      ),
                      const SizedBox(height: 10),
                      CategoryChipsBar(
                        selectedCategory: selectedCategory,
                        onCategorySelected: _handleCategorySelected,
                      ),
                      if (nearbyPlacesAsync.hasError) ...[
                        const SizedBox(height: 8),
                        InlineErrorBanner(
                          message: 'Could not load ${selectedCategory?.label ?? 'places'}: '
                              '${nearbyPlacesAsync.error}',
                          onDismiss: () => ref.read(nearbyPlacesProvider.notifier).clear(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Nearby-search loading indicator
              if (nearbyPlacesAsync.isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 3),
                ),
            ],
          );
        },
      ),
      floatingActionButton: RecenterFab(
        isLoading: _isRecentering,
        onPressed: _handleRecenter,
      ),
    );
  }
}
