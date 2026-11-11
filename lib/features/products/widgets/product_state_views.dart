import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/primary_button.dart';
import 'product_tile.dart';

/// Placeholder grid shown while the first page of products loads:
/// tile-coloured rounded blocks in the shape of the product cards, with a
/// soft shimmer.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton(
      {super.key, this.itemCount = 6, this.shrinkWrap = false});

  final int itemCount;

  /// For use inside another scroll view (e.g. Home's list).
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      padding: shrinkWrap
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(
              AppConstants.pagePadding, 4, AppConstants.pagePadding, 0),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const ProductGridDelegate(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusProductCard),
            border: Border.all(color: palette.border),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(aspectRatio: 1, child: SkeletonBlock()),
              SizedBox(height: 12),
              SkeletonBlock(height: 12, width: 110, radius: 6),
              SizedBox(height: 10),
              SkeletonBlock(height: 12, width: 70, radius: 6),
              Spacer(),
              SkeletonBlock(height: 34, radius: AppConstants.radiusPill),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(
            duration: AppConstants.animShimmer,
            color: palette.surface.withValues(alpha: 0.5));
      },
    );
  }
}

/// Standard "the request failed" state: icon, message, and a Retry button.
class ProductErrorView extends StatelessWidget {
  const ProductErrorView(
      {super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PlaceholderState(
      icon: Icons.cloud_off_rounded,
      title: "Couldn't load products",
      message: message,
      action: PrimaryButton(
        label: 'Retry',
        icon: Icons.refresh_rounded,
        expand: false,
        onPressed: onRetry,
      ),
    ).entrance();
  }
}

/// Standard "nothing here" state: icon and message, no results found.
class ProductEmptyView extends StatelessWidget {
  const ProductEmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inventory_2_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PlaceholderState(
      icon: icon,
      title: 'Nothing here yet',
      message: message,
    ).entrance();
  }
}
