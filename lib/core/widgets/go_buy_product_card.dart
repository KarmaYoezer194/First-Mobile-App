import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// The product grid card used on Home and Search. Purely presentational:
/// callers pass in the product's data and wire the actions to the
/// existing cart / wishlist logic.
class GoBuyProductCard extends StatelessWidget {
  const GoBuyProductCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.priceText,
    required this.onTap,
    required this.onAddToCart,
    required this.onBuyNow,
    this.tag,
    this.rating,
    this.ratingCount,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.imageKey,
  });

  final String imageUrl;
  final String name;
  final String priceText;

  /// Small white pill on the image's top-right ("New", or a category).
  final String? tag;

  /// Only shown when the product has rating data.
  final double? rating;
  final int? ratingCount;

  final bool isFavorite;

  /// Hides the heart when null.
  final VoidCallback? onToggleFavorite;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;

  /// Attached to the image so callers can find its position for the
  /// fly-to-cart animation.
  final Key? imageKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    final hasRating = rating != null && rating! > 0;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusProductCard),
        border: Border.all(color: palette.border),
        boxShadow: AppShadows.productCard,
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image tile
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Semantics(
                  button: true,
                  label: 'Open $name',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: onTap,
                    child: ClipRRect(
                      key: imageKey,
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      child: ColoredBox(
                        color: palette.tile,
                        child: imageUrl.isEmpty
                            ? Icon(Icons.image_outlined, color: palette.hint)
                            : CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                fadeInDuration: AppConstants.animToggle,
                                placeholder: (_, __) => const SizedBox.shrink(),
                                errorWidget: (_, __, ___) => Icon(
                                    Icons.broken_image_outlined,
                                    color: palette.hint),
                              ),
                      ),
                    ),
                  ),
                ),
                if (onToggleFavorite != null)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: WishlistHeart(
                      isFavorite: isFavorite,
                      onTap: onToggleFavorite!,
                    ),
                  ),
                if (tag != null && tag!.isNotEmpty)
                  Positioned(
                    right: 7,
                    top: 7,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 90),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusPill),
                      ),
                      child: Text(
                        tag!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.sans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.sans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.ink),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Expanded(
                  child: hasRating
                      // One line that clips if space runs out, so a long
                      // price never pushes the card out of shape.
                      ? Text.rich(
                          TextSpan(children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Icon(Icons.star_rounded,
                                    size: 14, color: palette.gold),
                              ),
                            ),
                            TextSpan(
                              text: rating!.toStringAsFixed(1),
                              style: AppFonts.sans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: palette.ink),
                            ),
                            if (ratingCount != null)
                              TextSpan(
                                text: ' ($ratingCount)',
                                style: AppFonts.sans(
                                    fontSize: 10.5, color: palette.hint),
                              ),
                          ]),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 4),
                Text(
                  priceText,
                  style: AppFonts.sans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: palette.ink),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CardButton(
                  label: 'Add to Cart',
                  semanticLabel: 'Add $name to cart',
                  onTap: onAddToCart,
                  background: palette.background,
                  foreground: palette.ink,
                  border: palette.borderStrong,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _CardButton(
                  label: 'Buy Now',
                  semanticLabel: 'Buy $name now',
                  onTap: onBuyNow,
                  background: scheme.primary,
                  foreground: scheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    required this.background,
    required this.foreground,
    this.border,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Pressable(
        enabled: onTap != null,
        child: Material(
          color: background,
          shape: StadiumBorder(
            side: border == null ? BorderSide.none : BorderSide(color: border!),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: SizedBox(
              height: 34,
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppFonts.sans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: foreground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 28px white circle heart; filled gold when saved. Tap area is 44×44.
class WishlistHeart extends StatelessWidget {
  const WishlistHeart({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.size = 28,
  });

  final bool isFavorite;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final label = isFavorite ? 'Remove from wishlist' : 'Add to wishlist';
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        toggled: isFavorite,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: AppConstants.minTapTarget,
            height: AppConstants.minTapTarget,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.floating,
                  ),
                  child: AnimatedSwitcher(
                    duration: AppConstants.animToggle,
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(isFavorite),
                      size: size * 0.54,
                      color: isFavorite ? palette.gold : AppColors.ink,
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
