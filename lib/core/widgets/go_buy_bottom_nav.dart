import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'circle_icon_button.dart';

class GoBuyNavItem {
  const GoBuyNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
    this.key,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;

  /// Lets callers locate an item (e.g. the Cart tab as the fly-to-cart
  /// target).
  final Key? key;
}

/// White bottom bar with a top hairline. Active item: ink icon, bold
/// label, 4px gold dot under the label. Inactive: muted.
class GoBuyBottomNav extends StatelessWidget {
  const GoBuyBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<GoBuyNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final GoBuyNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = selected ? palette.ink : palette.navInactive;
    final badge = item.badgeCount > 0 ? ', ${item.badgeCount} items' : '';

    return Semantics(
      button: true,
      selected: selected,
      label: '${item.label} tab$badge',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        highlightShape: BoxShape.rectangle,
        containedInkWell: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              key: item.key,
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? item.activeIcon : item.icon,
                    size: 20, color: color),
                if (item.badgeCount > 0)
                  Positioned(
                    top: -6,
                    right: -10,
                    // Bumps whenever the count changes, like the old
                    // cart icon did.
                    child: CountBadge(count: item.badgeCount)
                        .animate(key: ValueKey(item.badgeCount))
                        .scaleXY(
                          begin: 1.35,
                          end: 1,
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOut,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: AppFonts.sans(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedOpacity(
              duration: AppConstants.animToggle,
              opacity: selected ? 1 : 0,
              child: Container(
                width: 4,
                height: 4,
                decoration:
                    BoxDecoration(color: palette.gold, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
