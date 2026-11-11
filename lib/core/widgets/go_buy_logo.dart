import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// "GoBuy" wordmark in Lora 700 with a gold full stop.
class GoBuyLogo extends StatelessWidget {
  const GoBuyLogo({super.key, this.size = 26, this.color});

  final double size;

  /// Defaults to the theme's ink color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: AppConstants.appName,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          text: AppConstants.appName,
          style: AppFonts.serif(
              fontSize: size, color: color ?? palette.ink, height: 1),
          children: [
            TextSpan(text: '.', style: TextStyle(color: palette.gold)),
          ],
        ),
      ),
    );
  }
}
