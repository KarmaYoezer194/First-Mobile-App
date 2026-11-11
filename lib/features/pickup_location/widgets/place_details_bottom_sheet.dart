import 'package:flutter/material.dart';

import '../models/pickup_point.dart';
import '../models/place_result.dart';

/// Bottom sheet shown when the user taps a marker. Presents the place's
/// details and, on confirmation, pops itself with a [PickupPoint] — the
/// caller (the map screen) is responsible for popping itself in turn with
/// that same value so it reaches the screen that opened the map.
class PlaceDetailsBottomSheet extends StatelessWidget {
  final PlaceResult place;
  final String category;

  const PlaceDetailsBottomSheet({
    super.key,
    required this.place,
    required this.category,
  });

  static Future<PickupPoint?> show(
    BuildContext context, {
    required PlaceResult place,
    required String category,
  }) {
    return showModalBottomSheet<PickupPoint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaceDetailsBottomSheet(place: place, category: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      place.name,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _StatusChip(openNow: place.openNow),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      place.address.isNotEmpty ? place.address : 'Address unavailable',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _InfoPill(
                    icon: Icons.star_rounded,
                    iconColor: Colors.amber,
                    label: place.rating != null ? place.rating!.toStringAsFixed(1) : 'No rating',
                  ),
                  _InfoPill(icon: Icons.category_outlined, label: category),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _CoordinateLabel(
                        label: 'Latitude',
                        value: place.location.latitude.toStringAsFixed(6),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    Expanded(
                      child: _CoordinateLabel(
                        label: 'Longitude',
                        value: place.location.longitude.toStringAsFixed(6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Select Pickup Point'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final pickupPoint = PickupPoint(
                      placeName: place.name,
                      address: place.address,
                      latitude: place.location.latitude,
                      longitude: place.location.longitude,
                      category: category,
                    );
                    Navigator.of(context).pop(pickupPoint);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool? openNow;
  const _StatusChip({required this.openNow});

  @override
  Widget build(BuildContext context) {
    if (openNow == null) return const SizedBox.shrink();
    final color = openNow! ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        openNow! ? 'Open' : 'Closed',
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;

  const _InfoPill({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor ?? theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _CoordinateLabel extends StatelessWidget {
  final String label;
  final String value;

  const _CoordinateLabel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
