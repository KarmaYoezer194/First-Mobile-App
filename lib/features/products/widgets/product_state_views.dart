import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';

/// Shimmering placeholder grid shown while the first page of products is
/// loading — reads as "content is on its way" instead of a blank spinner,
/// and roughly previews the real grid's shape.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;

    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.spaceSM),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppConstants.spaceSM,
        crossAxisSpacing: AppConstants.spaceSM,
        childAspectRatio: 0.62,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          decoration:
              BoxDecoration(color: base, borderRadius: BorderRadius.circular(AppConstants.radiusM)),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
                duration: AppConstants.animShimmer,
                color: theme.colorScheme.surface.withValues(alpha: 0.6));
      },
    );
  }
}

/// Standard "the request failed" state: icon, message, and a Retry button.
class ProductErrorView extends StatelessWidget {
  const ProductErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 52, color: theme.colorScheme.error)
                .animate()
                .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  duration: AppConstants.animMedium,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: AppConstants.spaceSM),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppConstants.spaceM),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ).animate().fadeIn(duration: AppConstants.animMedium),
      ),
    );
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppConstants.spaceSM),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ],
        ).animate().fadeIn(duration: AppConstants.animMedium).slideY(begin: 0.06, end: 0),
      ),
    );
  }
}
