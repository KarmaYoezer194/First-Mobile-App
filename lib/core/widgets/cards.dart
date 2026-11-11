import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// White card (radius 16, 1px border) holding a column of [ListRow]s,
/// separated by hairline dividers.
class ListRowCard extends StatelessWidget {
  const ListRowCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(indent: 62, height: 1, color: palette.border),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// A row inside [ListRowCard]: 34px icon well, title, optional subtitle,
/// and a trailing widget (chevron by default; pass a [GoldSwitch], radio,
/// or text instead).
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.darkWell = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Log-out style row: danger icon well and text, no chevron.
  final bool destructive;

  /// Ink icon well with a light-gold icon (order/shipping rows).
  final bool darkWell;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final Color wellColor;
    final Color iconColor;
    if (destructive) {
      wellColor = palette.dangerBg;
      iconColor = palette.danger;
    } else if (darkWell) {
      wellColor = palette.heroCard;
      iconColor = palette.goldLight;
    } else {
      wellColor = palette.surfaceSoft;
      iconColor = palette.ink;
    }

    final trailingWidget = trailing ??
        (showChevron && !destructive && onTap != null
            ? Icon(Icons.chevron_right_rounded, size: 20, color: palette.hint)
            : null);

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: wellColor,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusIconWell),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppFonts.sans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: destructive ? palette.danger : palette.ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.sans(fontSize: 11, color: palette.hint),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null) ...[
                const SizedBox(width: 8),
                trailingWidget,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SummaryLine {
  const SummaryLine(this.label, this.value, {this.highlight, this.valueColor});

  final String label;
  final String value;

  /// Gold label + value (voucher line).
  final bool? highlight;

  /// Overrides the value color (e.g. success for "Free" shipping).
  final Color? valueColor;
}

/// Price breakdown card: label/value rows, a dashed divider, then the
/// total in serif 22.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.lines,
    required this.totalValue,
    this.totalLabel = 'Total',
  });

  final List<SummaryLine> lines;
  final String totalLabel;
  final String totalValue;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    line.label,
                    style: AppFonts.sans(
                      fontSize: 13,
                      color: line.highlight == true
                          ? palette.gold
                          : palette.inkMuted,
                      fontWeight: line.highlight == true
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  Text(
                    line.value,
                    style: AppFonts.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: line.valueColor ??
                          (line.highlight == true ? palette.gold : palette.ink),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          DashedDivider(color: palette.borderStrong),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                totalLabel,
                style: AppFonts.sans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.ink),
              ),
              Text(
                totalValue,
                style:
                    AppFonts.serif(fontSize: 22, color: palette.ink, height: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A 1px dashed horizontal line.
class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key, this.color, this.dash = 5, this.gap = 4});

  final Color? color;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashPainter(color ?? context.palette.borderStrong, dash, gap),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.dash, this.gap);

  final Color color;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + dash, 0.5), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) =>
      old.color != color || old.dash != dash || old.gap != gap;
}

/// Profile stat tile: gold icon, serif number, small label.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: palette.gold),
            const SizedBox(height: 10),
            Text(value,
                style: AppFonts.serif(
                    fontSize: 22, color: palette.ink, height: 1)),
            const SizedBox(height: 4),
            Text(label,
                style: AppFonts.sans(fontSize: 11, color: palette.hint)),
          ],
        ),
      ),
    );
  }
}

/// Rounded placeholder block for loading skeletons.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    this.height,
    this.radius = AppConstants.radiusM,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.palette.tile,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
