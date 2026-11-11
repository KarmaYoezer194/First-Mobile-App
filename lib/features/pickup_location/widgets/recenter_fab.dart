import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// 46px white circle that recenters the map on the user's location. Shows
/// a spinner while a fresh GPS fix is being fetched.
class RecenterFab extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const RecenterFab({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: 'Recenter on my location',
      child: Semantics(
        button: true,
        label: 'Recenter on my location',
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: const BoxDecoration(
              shape: BoxShape.circle, boxShadow: AppShadows.floating),
          child: Material(
            color: palette.surface,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              child: SizedBox(
                width: 46,
                height: 46,
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.my_location_rounded,
                          size: 20, color: palette.ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
