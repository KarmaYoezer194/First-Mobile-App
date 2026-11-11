import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/place_result.dart';

/// Panel fixed to the bottom of the map showing the selected place: icon,
/// name, "type · address · distance", open/closed, rating, coordinates, and
/// "Set as pickup location". The map screen turns the confirmation into a
/// [PickupPoint] and pops with it.
class PlaceDetailsPanel extends StatelessWidget {
  const PlaceDetailsPanel({
    super.key,
    required this.place,
    required this.category,
    required this.icon,
    required this.onConfirm,
    required this.onClose,
    this.distanceMeters,
  });

  final PlaceResult place;
  final String category;
  final IconData icon;
  final double? distanceMeters;
  final VoidCallback onConfirm;
  final VoidCallback onClose;

  /// Uses a non-breaking space so "246 m" never wraps between the parts.
  static String formatDistance(double meters) => meters < 1000
      ? '${meters.round()}\u00A0m'
      : '${(meters / 1000).toStringAsFixed(1)}\u00A0km';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final meta = [
      category,
      if (place.address.isNotEmpty) place.address,
      if (distanceMeters != null) formatDistance(distanceMeters!),
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusSheet)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A2B2420), blurRadius: 16, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppConstants.pagePadding, 10, AppConstants.pagePadding, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: palette.surfaceSoft,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusInput),
                    ),
                    child: Icon(icon, size: 20, color: palette.ink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.sans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: palette.ink)),
                        const SizedBox(height: 3),
                        Text(meta,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.sans(
                                fontSize: 12,
                                color: palette.inkMuted,
                                height: 1.4)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (place.openNow != null)
                              Text(
                                place.openNow! ? '● Open now' : '● Closed',
                                style: AppFonts.sans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: place.openNow!
                                        ? palette.success
                                        : palette.danger),
                              ),
                            if (place.rating != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded,
                                      size: 13, color: palette.gold),
                                  const SizedBox(width: 2),
                                  Text(place.rating!.toStringAsFixed(1),
                                      style: AppFonts.sans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: palette.ink)),
                                ],
                              ),
                            Text(
                              '${place.location.latitude.toStringAsFixed(5)}, '
                              '${place.location.longitude.toStringAsFixed(5)}',
                              style: AppFonts.sans(
                                  fontSize: 11, color: palette.hint),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    iconSize: 18,
                    color: palette.hint,
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                  label: 'Set as pickup location', onPressed: onConfirm),
            ],
          ),
        ),
      ),
    );
  }
}
