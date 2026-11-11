import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../constants/api_constants.dart';
import '../constants/place_categories.dart';
import '../models/pickup_point.dart';
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
/// result:
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
  /// map has a center to search around.
  final PlaceCategory? initialCategory;

  @override
  ConsumerState<PickupLocationScreen> createState() =>
      _PickupLocationScreenState();
}

/// The place currently shown in the bottom panel.
class _Selection {
  const _Selection(this.place, this.categoryLabel, this.icon);

  final PlaceResult place;
  final String categoryLabel;
  final IconData icon;
}

/// Desaturates the OSM tiles and warms them slightly, to sit with the
/// ivory theme.
const ColorFilter _warmTiles = ColorFilter.matrix(<double>[
  0.630, 0.372, 0.038, 0, 8, //
  0.106, 0.858, 0.036, 0, 3, //
  0.100, 0.336, 0.504, 0, -4, //
  0, 0, 0, 1, 0, //
]);

class _PickupLocationScreenState extends ConsumerState<PickupLocationScreen> {
  static const double _defaultZoom = 15;

  bool _isRecentering = false;
  bool _initialCategoryApplied = false;
  LatLng? _userLocation;
  _Selection? _selection;
  StreamSubscription<MapEvent>? _mapEventSubscription;

  @override
  void initState() {
    super.initState();
    // Track the map's current center as the user pans/zooms, so category
    // search always searches around what's currently on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapEventSubscription =
          ref.read(mapControllerProvider).mapEventStream.listen((event) {
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
    setState(() => _selection = null);

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
    setState(() =>
        _selection = _Selection(place, 'Search result', Icons.place_outlined));
  }

  void _select(PlaceResult place, String categoryLabel, IconData icon) {
    setState(() => _selection = _Selection(place, categoryLabel, icon));
  }

  /// Same result as before: pop with a [PickupPoint] for the screen that
  /// opened the map.
  void _confirm(_Selection selection) {
    final place = selection.place;
    Navigator.of(context).pop(PickupPoint(
      placeName: place.name,
      address: place.address,
      latitude: place.location.latitude,
      longitude: place.location.longitude,
      category: selection.categoryLabel,
    ));
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isSelected(PlaceResult place) => _selection?.place.id == place.id;

  Marker _placeMarker(PlaceResult place, String label, IconData icon) {
    final selected = _isSelected(place);
    return Marker(
      point: place.location,
      width: selected ? SelectedMarkerPin.size.width : 44,
      height: selected ? SelectedMarkerPin.size.height : 44,
      // A selected pin's tip marks the spot, so it sits above the point.
      alignment: selected ? Alignment.topCenter : Alignment.center,
      child: Semantics(
        button: true,
        selected: selected,
        label: place.name,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _select(place, label, icon),
          child: selected
              ? SelectedMarkerPin(icon: icon)
              : CategoryMarkerPin(icon: icon),
        ),
      ),
    );
  }

  List<Marker> _buildMarkers(
      List<PlaceResult> nearbyPlaces, PlaceCategory? category) {
    final label = category?.label ?? 'Place';
    final icon = category?.icon ?? Icons.place_outlined;
    final markers = <Marker>[];

    if (_userLocation != null) {
      markers.add(Marker(
        point: _userLocation!,
        width: 30,
        height: 30,
        child: const UserLocationMarkerPin(),
      ));
    }

    // Selected marker last so it draws on top.
    final ordered = [
      ...nearbyPlaces.where((p) => !_isSelected(p)),
      ...nearbyPlaces.where(_isSelected),
    ];
    for (final place in ordered) {
      markers.add(_placeMarker(place, label, icon));
    }

    final searchResult = ref.watch(searchResultProvider);
    if (searchResult != null) {
      markers.add(
          _placeMarker(searchResult, 'Search result', Icons.place_outlined));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(currentPositionProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final nearbyPlacesAsync = ref.watch(nearbyPlacesProvider);
    final mapController = ref.watch(mapControllerProvider);
    final position = positionAsync.valueOrNull;
    final initialTarget =
        position == null ? null : LatLng(position.latitude, position.longitude);
    final selection = _selection;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          // Map (or the loading / error state while there's no location).
          Positioned.fill(
            child: positionAsync.when(
              loading: () => const MapLoadingView(),
              error: (error, _) => MapErrorView(
                message: error is LocationServiceException
                    ? error.message
                    : 'Something went wrong while getting your location.',
                onRetry: () => ref.invalidate(currentPositionProvider),
              ),
              data: (position) {
                final target = LatLng(position.latitude, position.longitude);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  ref.read(mapCenterProvider.notifier).state ??= target;
                  if (_userLocation == null) {
                    setState(() => _userLocation = target);
                  }

                  final initialCategory = widget.initialCategory;
                  if (initialCategory != null && !_initialCategoryApplied) {
                    _initialCategoryApplied = true;
                    _handleCategorySelected(initialCategory);
                  }
                });

                return FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: target,
                    initialZoom: _defaultZoom,
                    // Tapping empty map closes the panel.
                    onTap: (_, __) => setState(() => _selection = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: ApiConstants.osmTileUrlTemplate,
                      userAgentPackageName: 'com.example.pickup_location_demo',
                      tileBuilder: (context, tile, _) =>
                          ColorFiltered(colorFilter: _warmTiles, child: tile),
                    ),
                    MarkerLayer(
                      markers: _buildMarkers(
                          nearbyPlacesAsync.valueOrNull ?? const [],
                          selectedCategory),
                    ),
                    // Required OSM attribution. While the place panel covers
                    // the bottom of the map, the same credit is shown just
                    // above the panel instead (see below).
                    const RichAttributionWidget(
                      alignment: AttributionAlignment.bottomLeft,
                      attributions: [
                        TextSourceAttribution('© OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          // Nearby-search loading indicator.
          if (nearbyPlacesAsync.isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),

          // Top: back + search field, place-type chips, errors.
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: CircleIconButton(
                            icon: Icons.chevron_left_rounded,
                            tooltip: 'Back',
                            bordered: false,
                            shadow: true,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                        if (initialTarget != null) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: PlaceSearchBar(
                              locationBias:
                                  ref.watch(mapCenterProvider) ?? initialTarget,
                              onPlaceSelected: _handlePlaceSelectedFromSearch,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (initialTarget != null) ...[
                    const SizedBox(height: 8),
                    CategoryChipsBar(
                      selectedCategory: selectedCategory,
                      onCategorySelected: _handleCategorySelected,
                    ),
                    if (nearbyPlacesAsync.hasError)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                        child: InlineErrorBanner(
                          message:
                              'Could not load ${selectedCategory?.label ?? 'places'}: '
                              '${nearbyPlacesAsync.error}',
                          onDismiss: () =>
                              ref.read(nearbyPlacesProvider.notifier).clear(),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom: recenter button, then the selected place's panel.
          if (initialTarget != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        16, 0, 16, selection == null ? bottomInset + 40 : 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (selection != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('© OpenStreetMap contributors',
                                style: AppFonts.sans(
                                    fontSize: 10, color: AppColors.inkMuted)),
                          ),
                        const Spacer(),
                        RecenterFab(
                          isLoading: _isRecentering,
                          onPressed: _handleRecenter,
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => SlideTransition(
                      position:
                          Tween(begin: const Offset(0, 1), end: Offset.zero)
                              .animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                    child: selection == null
                        ? const SizedBox(width: double.infinity)
                        : PlaceDetailsPanel(
                            key: ValueKey(selection.place.id),
                            place: selection.place,
                            category: selection.categoryLabel,
                            icon: selection.icon,
                            distanceMeters: _userLocation == null
                                ? null
                                : const Distance().as(LengthUnit.Meter,
                                    _userLocation!, selection.place.location),
                            onConfirm: () => _confirm(selection),
                            onClose: () => setState(() => _selection = null),
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
