import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Inline error banner for sign-in / sign-up / reset failures that aren't
/// tied to one field (wrong password, network error, ...). Field
/// validation errors show under their own field instead.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: palette.dangerBg,
          borderRadius: BorderRadius.circular(AppConstants.radiusInput),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: palette.danger, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppFonts.sans(
                    fontSize: 12.5, color: palette.danger, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
