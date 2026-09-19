import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../models/product.dart';

/// A single grid tile: thumbnail with a discount badge and a wishlist
/// heart, then title, price, and a rating/sold-count line underneath.
/// Animates in on first build (with a small stagger based on [index]) and
/// gives a tactile scale-down on tap.
class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.index = 0,
  });

  final Product product;
  final VoidCallback onTap;

  /// Local-only wishlist toggle — see [HomeProductCard]'s doc comment on
  /// the same pattern; there's no wishlist backend yet.
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  /// This card's position in its grid, used only to stagger the entrance
  /// animation so cards don't all pop in at once.
  final int index;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _pressed = false;

  /// "N sold" — Lazada/Shopee's social-proof line. FakeStoreAPI has no
  /// actual sales figures, so this is derived deterministically from the
  /// product's own id/rating (same product always shows the same number,
  /// rather than a fresh random one on every rebuild).
  int get _sold {
    final product = widget.product;
    final seed = (product.id * 47 + (product.rating * 131).round()).abs();
    return 50 + (seed % 950);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;
    final bool hasDiscount = product.discountPercentage > 0;
    final double discountedPrice = product.price * (1 - product.discountPercentage / 100);
    final bool inStock = product.stock > 0;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: AppConstants.animMicro,
      curve: Curves.easeOut,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'product-image-${product.id}',
                      child: _ProductThumbnail(url: product.thumbnail),
                    ),
                    if (!inStock)
                      Container(color: Colors.black.withValues(alpha: 0.35)),
                    if (!inStock)
                      const Center(
                        child: _Ribbon(label: 'OUT OF STOCK', color: Colors.black87),
                      ),
                    if (hasDiscount)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: _DiscountBadge(percent: product.discountPercentage),
                      ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: _FavoriteButton(
                        active: widget.isFavorite,
                        onTap: widget.onToggleFavorite,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '\$${discountedPrice.toStringAsFixed(2)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 13, color: Colors.amber.shade700),
                        const SizedBox(width: 2),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          ' · $_sold Sold',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (widget.index % 8 * 45).ms)
        .fadeIn(duration: AppConstants.animMedium, curve: Curves.easeOut)
        .slideY(begin: 0.08, end: 0, duration: AppConstants.animMedium, curve: Curves.easeOut);
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${percent.toStringAsFixed(0)}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Local-only wishlist toggle — same pattern as [HomeProductCard]'s
/// `_FavoriteButton`; no wishlist backend to persist to yet.
class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1.5,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 16,
            color: active ? AppColors.primary : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _placeholder(context);
    }
    // Cached to disk+memory (keyed by URL) so scrolling back to a card, or
    // returning to this screen later, shows the image instantly instead of
    // re-downloading it from fakestoreapi's slow image host every time.
    return CachedNetworkImage(
      imageUrl: url,
      width: double.infinity,
      fit: BoxFit.cover,
      // Downscale the decode target to roughly what a grid tile needs
      // instead of decoding the (often much larger) source image at full
      // resolution — cheaper on both memory and CPU.
      memCacheWidth: 400,
      fadeInDuration: AppConstants.animMicro,
      placeholder: (context, url) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
