import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// 40px white circle with a 1px border and an icon. The tap area is
/// padded to 44×44. Optionally shows a gold dot ([showDot]) or a count
/// badge ([badgeCount]) at the top-right.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.showDot = false,
    this.badgeCount,
    this.background,
    this.iconColor,
    this.bordered = true,
    this.size = AppConstants.iconButtonSize,
    this.shadow = false,
  });

  final IconData icon;

  /// Also used as the screen-reader label.
  final String tooltip;
  final VoidCallback? onPressed;
  final bool showDot;
  final int? badgeCount;

  /// Defaults to the surface color (white in light mode).
  final Color? background;
  final Color? iconColor;
  final bool bordered;
  final double size;

  /// Floating controls (map, product image) get a light shadow.
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final count = badgeCount ?? 0;
    final hitSize =
        size < AppConstants.minTapTarget ? AppConstants.minTapTarget : size;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: count > 0 ? '$tooltip, $count items' : tooltip,
        excludeSemantics: true,
        child: SizedBox(
          width: hitSize,
          height: hitSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: bordered ? Border.all(color: palette.border) : null,
                  boxShadow: shadow ? AppShadows.floating : null,
                ),
                child: Material(
                  color: background ?? palette.surface,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onPressed,
                    child: SizedBox(
                      width: size,
                      height: size,
                      child:
                          Icon(icon, size: 19, color: iconColor ?? palette.ink),
                    ),
                  ),
                ),
              ),
              if (count > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: CountBadge(count: count),
                )
              else if (showDot)
                Positioned(
                  top: (hitSize - size) / 2 + 8,
                  right: (hitSize - size) / 2 + 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: palette.gold,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gold circle with an ink count (9px w800). Used on the Cart tab and the
/// product-detail cart button.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: palette.gold,
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        border: Border.all(color: palette.surface, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AppFonts.sans(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            height: 1),
      ),
    );
  }
}
