import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/primary_button.dart';

/// Full-screen loading state, e.g. while first acquiring GPS location.
class MapLoadingView extends StatelessWidget {
  final String message;
  const MapLoadingView({super.key, this.message = 'Getting your location...'});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
                color: palette.surfaceSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
          const SizedBox(height: 18),
          Text(message,
              style: AppFonts.sans(fontSize: 13, color: palette.inkMuted)),
        ],
      ),
    );
  }
}

/// Full-screen error state with a retry action, e.g. for denied location
/// permission or an unrecoverable startup failure.
class MapErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const MapErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return PlaceholderState(
      icon: Icons.location_off_outlined,
      title: "Can't find your location",
      message: message,
      action: PrimaryButton(
        label: 'Try again',
        icon: Icons.refresh_rounded,
        expand: false,
        onPressed: onRetry,
      ),
    );
  }
}

/// Small inline banner used for non-fatal errors (e.g. a failed nearby
/// search) that shouldn't block the whole map.
class InlineErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const InlineErrorBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.dangerBg,
      borderRadius: BorderRadius.circular(AppConstants.radiusInput),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: palette.danger),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: AppFonts.sans(fontSize: 12, color: palette.danger)),
            ),
            if (onDismiss != null)
              IconButton(
                tooltip: 'Dismiss',
                icon:
                    Icon(Icons.close_rounded, size: 16, color: palette.danger),
                onPressed: onDismiss,
              ),
          ],
        ),
      ),
    );
  }
}
