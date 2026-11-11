import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// 58px white circle with an icon and a small label underneath. Used for
/// Home's category row.
class CategoryCircle extends StatelessWidget {
  const CategoryCircle({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: SizedBox(
          width: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppConstants.categoryCircleSize,
                  height: AppConstants.categoryCircleSize,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.border),
                  ),
                  child: Icon(icon, size: 22, color: palette.ink),
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppFonts.sans(
                      fontSize: 11, color: palette.inkMuted, height: 1.25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill chip. Selected: ink background, ivory text. Unselected: white,
/// 1px border, muted text.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.strikethrough = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  /// Unavailable options render at 45% opacity.
  final bool enabled;
  final bool strikethrough;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : palette.inkMuted;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: SizedBox(
          height: AppConstants.minTapTarget,
          // widthFactor keeps the chip as wide as its label (in a Wrap it
          // would otherwise stretch to the full row).
          child: Center(
            widthFactor: 1,
            child: AnimatedContainer(
              duration: AppConstants.animToggle,
              curve: AppConstants.animCurve,
              decoration: BoxDecoration(
                color: selected ? scheme.primary : palette.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                border: Border.all(
                    color: selected ? scheme.primary : palette.border),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: enabled ? onTap : null,
                  borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 14, color: fg),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          label,
                          style: AppFonts.sans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: fg,
                          ).copyWith(
                            decoration: strikethrough
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: fg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SortTabItem {
  const SortTabItem(this.label, {this.trailingIcon});

  final String label;
  final IconData? trailingIcon;
}

/// Text tabs with a 2px ink underline under the active one.
class SortTabs extends StatelessWidget {
  const SortTabs({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<SortTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Scrolls sideways if the tabs don't fit (narrow screens, large text).
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 20),
            Semantics(
              button: true,
              selected: i == selectedIndex,
              label: 'Sort by ${items[i].label}',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onChanged(i),
                child: SizedBox(
                  height: AppConstants.minTapTarget,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            items[i].label,
                            style: AppFonts.sans(
                              fontSize: 13,
                              fontWeight: i == selectedIndex
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: i == selectedIndex
                                  ? palette.ink
                                  : palette.hint,
                            ),
                          ),
                          if (items[i].trailingIcon != null)
                            Icon(items[i].trailingIcon,
                                size: 16,
                                color: i == selectedIndex
                                    ? palette.ink
                                    : palette.hint),
                        ],
                      ),
                      const SizedBox(height: 5),
                      AnimatedContainer(
                        duration: AppConstants.animToggle,
                        curve: AppConstants.animCurve,
                        height: 2,
                        width: i == selectedIndex ? 22 : 0,
                        color: palette.ink,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 44×26 switch: gold track when on, warm grey when off, white thumb.
class GoldSwitch extends StatelessWidget {
  const GoldSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      toggled: value,
      label: semanticLabel,
      enabled: onChanged != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: SizedBox(
          width: 48,
          height: AppConstants.minTapTarget,
          child: Center(
            child: AnimatedContainer(
              duration: AppConstants.animToggle,
              curve: AppConstants.animCurve,
              width: 44,
              height: 26,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? palette.gold : palette.switchTrackOff,
                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
              ),
              child: AnimatedAlign(
                duration: AppConstants.animToggle,
                curve: AppConstants.animCurve,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.floating,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill with − / + circular buttons and the value in between.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max,
  });

  final int value;
  final ValueChanged<int>? onChanged;
  final int min;
  final int? max;

  @override
  Widget build(BuildContext context) {
    final canDec = onChanged != null && value > min;
    final canInc = onChanged != null && (max == null || value < max!);
    final palette = context.palette;

    // The pill draws 34px tall, but the widget is 44px so each button's
    // tap area meets the minimum size.
    return SizedBox(
      height: AppConstants.minTapTarget,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            top: 5,
            bottom: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surfaceSoft,
                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                tooltip: 'Decrease quantity',
                onTap: canDec ? () => onChanged!(value - 1) : null,
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 20),
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: AppFonts.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: palette.ink),
                ),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                tooltip: 'Increase quantity',
                onTap: canInc ? () => onChanged!(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: tooltip,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: AppConstants.minTapTarget,
            child: Center(
              child: Opacity(
                opacity: onTap == null ? 0.4 : 1,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: palette.ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Uppercase 12 w700 label in the hint color, used above grouped cards.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: AppFonts.sans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: context.palette.hint,
          letterSpacing: 12 * 0.06,
        ),
      ),
    );
  }
}
