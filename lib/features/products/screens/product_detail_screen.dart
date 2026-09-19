import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/cart_provider.dart';
import '../../cart/models/cart_item.dart';
import '../../cart/models/pricing_summary.dart';
import '../../cart/screens/checkout_screen.dart';
import '../../cart/widgets/added_to_cart_sheet.dart';
import '../../cart/widgets/cart_badge.dart';
import '../../cart/widgets/fly_to_cart.dart';
import '../../pickup_location/constants/place_categories.dart';
import '../../pickup_location/models/pickup_point.dart';
import '../core/category_icons.dart';
import '../models/product.dart';
import '../services/firestore_product_service.dart';
import '../services/product_api_service.dart' show ApiException;
import '../widgets/product_state_views.dart';

/// Fetches and displays a single product by id: image, title, description,
/// category, brand, price, rating and stock — plus a quantity picker and
/// "Add to Cart" bar so this screen can act as the product's buy page.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final FirestoreProductService _service = FirestoreProductService();

  late Future<Product> _future;
  int _quantity = 1;
  // Local-only wishlist toggle — same as Home's Best Selling cards (see
  // HomeProductCard's doc comment); no wishlist backend to persist to yet.
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _future = _service.getProductById(widget.productId);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() => _future = _service.getProductById(widget.productId));
  }

  void _addToCart(Product product, Offset start) {
    final addedQuantity = _quantity;
    ref.read(cartProvider.notifier).addProduct(product, quantity: addedQuantity);
    flyToCart(context, start: start, imageUrl: product.thumbnail);
    setState(() => _quantity = 1);
    showAddedToCartSheet(context, product: product, quantity: addedQuantity);
  }

  /// Skips the cart entirely — Lazada/Shopee's "Buy Now" — and goes
  /// straight to checkout for just this product/quantity.
  void _buyNow(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen.buyNow(
          buyNowItem: CartItem(product: product, quantity: _quantity),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Shows the product's own name once loaded (matching the reference
        // layout), falling back to a generic title while it's still loading
        // or if it failed — reuses the same cached _future, no extra call.
        title: FutureBuilder<Product>(
          future: _future,
          builder: (context, snapshot) => Text(
            snapshot.data?.title ?? 'Product Details',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: const [CartBadge()],
      ),
      body: FutureBuilder<Product>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _DetailSkeleton();
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Something went wrong while loading this product.';
            return ProductErrorView(message: message, onRetry: _retry);
          }

          final product = snapshot.data;
          if (product == null) {
            return const Center(child: Text('Product not found.'));
          }
          return _ProductDetailBody(
            product: product,
            quantity: _quantity,
            onQuantityChanged: (q) => setState(() => _quantity = q.clamp(1, 99)),
          );
        },
      ),
      // Reuses the same cached _future (no extra network call) just to know
      // whether a product is loaded — the Add-to-Cart bar only makes sense
      // once there's something to buy.
      bottomNavigationBar: FutureBuilder<Product>(
        future: _future,
        builder: (context, snapshot) {
          final product = snapshot.data;
          if (product == null) return const SizedBox.shrink();
          return _AddToCartBar(
            product: product,
            isFavorite: _isFavorite,
            onToggleFavorite: () => setState(() => _isFavorite = !_isFavorite),
            onAddToCart: (start) => _addToCart(product, start),
            onBuyNow: () => _buyNow(product),
          );
        },
      ),
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({
    required this.product,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final Product product;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final ValueChanged<Offset> onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool inStock = product.stock > 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        // Heart (wishlist) + Lazada/Shopee's split button: a lighter "Add to
        // Cart" (keeps browsing) next to a solid, more prominent "Buy Now"
        // (skips straight to checkout for just this item).
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: IconButton(
                tooltip: isFavorite ? 'Remove from wishlist' : 'Add to wishlist',
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorite ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Builder(
                builder: (buttonContext) => OutlinedButton.icon(
                  onPressed: inStock
                      ? () {
                          final box = buttonContext.findRenderObject() as RenderBox?;
                          onAddToCart(box != null
                              ? box.localToGlobal(box.size.center(Offset.zero))
                              : Offset.zero);
                        }
                      : null,
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('Add to Cart'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: inStock ? onBuyNow : null,
                child: Text(inStock ? 'Buy Now' : 'Out of Stock'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmering placeholder shown while the product loads — previews the
/// real layout's shape (image, title, chips, price) instead of a bare spinner.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;

    Widget bar(double width, double height) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(8)),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Container(height: 280, color: base),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(double.infinity, 24),
              const SizedBox(height: 12),
              Row(children: [bar(90, 28), const SizedBox(width: 8), bar(90, 28)]),
              const SizedBox(height: 20),
              bar(140, 32),
              const SizedBox(height: 20),
              bar(100, 18),
              const SizedBox(height: 8),
              bar(double.infinity, 14),
              const SizedBox(height: 6),
              bar(double.infinity, 14),
              const SizedBox(height: 6),
              bar(200, 14),
            ],
          ),
        ),
      ],
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: AppConstants.animShimmer,
          color: theme.colorScheme.surface.withValues(alpha: 0.6),
        );
  }
}

class _ProductDetailBody extends StatefulWidget {
  const _ProductDetailBody({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
  });

  final Product product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  @override
  State<_ProductDetailBody> createState() => _ProductDetailBodyState();
}

class _ProductDetailBodyState extends State<_ProductDetailBody> {
  static const _sizes = ['S', 'M', 'L', 'XL'];
  String _selectedSize = 'M';

  /// FakeStoreAPI has no size/variant data at all, so a size picker only
  /// makes sense — and only gets shown — for the categories where "size"
  /// is a real, meaningful attribute of the product.
  bool get _showSizePicker => widget.product.category.toLowerCase().contains('clothing');

  /// "N reviews" — same deterministic, no-backend approach as
  /// [_SoldCountBadge]'s sold count, with a different multiplier so the two
  /// numbers don't just mirror each other for every product.
  int get _reviewCount {
    final product = widget.product;
    final seed = (product.id * 83 + (product.rating * 97).round()).abs();
    return 8 + (seed % 190);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;
    final quantity = widget.quantity;
    final onQuantityChanged = widget.onQuantityChanged;
    final images = product.images.isNotEmpty ? product.images : [product.thumbnail];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _ImageGallery(images: images, productId: product.id),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rating + price up top, title below — the reference layout
              // this screen follows leads with those two, not the name.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _RatingBadge(rating: product.rating),
                  const SizedBox(width: 8),
                  Text(
                    '$_reviewCount reviews',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  if (product.discountPercentage > 0) ...[
                    Text(
                      '\$${(product.price * (1 - product.discountPercentage / 100)).toStringAsFixed(2)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ] else
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(product.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                '${product.brand} • ${product.category}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Quantity', style: theme.textTheme.titleSmall),
                  const Spacer(),
                  _QuantityStepper(quantity: quantity, onChanged: onQuantityChanged),
                ],
              ),
              if (_showSizePicker) ...[
                const SizedBox(height: 20),
                Text('Product Size', style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final size in _sizes)
                      _SizeChip(
                        label: size,
                        selected: size == _selectedSize,
                        onTap: () => setState(() => _selectedSize = size),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Text('Description', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(product.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: Icon(CategoryIcons.iconFor(product.category), size: 18),
                    label: Text(product.category),
                  ),
                  Chip(
                    avatar: const Icon(Icons.sell_outlined, size: 18),
                    label: Text(product.brand),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StockBadge(stock: product.stock),
                  _SoldCountBadge(product: product),
                  if (product.price >= PricingSummary.freeShippingThreshold)
                    const _FreeShippingBadge(),
                ],
              ),
              const SizedBox(height: 20),
              _FindPickupTile(category: product.category),
            ],
          ),
        ).animate().fadeIn(duration: AppConstants.animMedium).slideY(begin: 0.04, end: 0, duration: AppConstants.animMedium),
      ],
    );
  }
}

/// One "Product Size" option — a plain rounded-rect chip, filled + bordered
/// in the accent color when selected. Display-only: this demo catalog has
/// no per-size stock or pricing to actually vary by the choice.
class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusS),
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minWidth: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Quantity +/- control — moved up into the body (next to the description)
/// rather than living in the bottom Add-to-Cart bar, matching the reference
/// layout this screen follows.
class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded),
            onPressed: () => onChanged(quantity - 1),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _ImageGallery extends StatefulWidget {
  const _ImageGallery({required this.images, required this.productId});

  final List<String> images;
  final int productId;

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectPage(int i) {
    _pageController.animateToPage(
      i,
      duration: AppConstants.animFast,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: 'product-image-${widget.productId}',
          child: SizedBox(
            height: 280,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _DetailImage(url: widget.images[i]),
            ),
          ),
        ),
        // A tappable thumbnail strip under the hero image — lets you jump
        // straight to a specific shot instead of only swiping through them
        // one at a time.
        if (widget.images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _ThumbnailTile(
                url: widget.images[i],
                selected: i == _index,
                onTap: () => _selectPage(i),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ThumbnailTile extends StatelessWidget {
  const _ThumbnailTile({required this.url, required this.selected, required this.onTap});

  final String url;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusS),
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        curve: Curves.easeOut,
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusS - 2),
          child: url.isEmpty
              ? Container(color: theme.colorScheme.surfaceContainerHighest)
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  memCacheWidth: 120,
                  fadeInDuration: AppConstants.animMicro,
                  errorWidget: (_, __, ___) => Container(color: theme.colorScheme.surfaceContainerHighest),
                ),
        ),
      ),
    );
  }
}

class _DetailImage extends StatelessWidget {
  const _DetailImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder(context);
    // Cached to disk+memory: coming back from the product grid (which
    // already loaded this same image) shows it instantly instead of
    // re-downloading it.
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      width: double.infinity,
      fadeInDuration: AppConstants.animMicro,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade700),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final bool outOfStock = stock <= 0;
    final bool lowStock = !outOfStock && stock <= 10;

    final Color color = outOfStock
        ? Colors.red.shade600
        : lowStock
            ? Colors.orange.shade700
            : Colors.green.shade600;
    final IconData icon = outOfStock
        ? Icons.cancel_rounded
        : lowStock
            ? Icons.warning_amber_rounded
            : Icons.check_circle_rounded;
    final String label = outOfStock
        ? 'Out of stock'
        : lowStock
            ? 'Only $stock left — order soon'
            : 'In stock • $stock available';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

/// "N+ sold" — Lazada/Shopee's social-proof badge. FakeStoreAPI has no
/// actual sales figures, so this is derived deterministically from the
/// product's own id/rating (same product always shows the same number,
/// rather than a fresh random one on every rebuild).
class _SoldCountBadge extends StatelessWidget {
  const _SoldCountBadge({required this.product});

  final Product product;

  int get _sold {
    final seed = (product.id * 47 + (product.rating * 131).round()).abs();
    return 50 + (seed % 950);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded,
              size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            '$_sold+ sold',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown once a product's price clears [PricingSummary.freeShippingThreshold]
/// on its own — the same threshold the cart/checkout pricing already uses,
/// so this badge never promises something checkout doesn't deliver.
class _FreeShippingBadge extends StatelessWidget {
  const _FreeShippingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.success),
          SizedBox(width: 6),
          Text(
            'Free Shipping',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Jumps to the pickup map with a category chip preselected from this
/// product's DummyJSON category, so tapping it lands on nearby places
/// relevant to what's being bought instead of a blank map.
class _FindPickupTile extends StatelessWidget {
  const _FindPickupTile({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final placeCategory = PlaceCategories.forProductCategory(category);

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(placeCategory.icon, color: placeCategory.color),
        title: const Text('Find pickup near me'),
        subtitle: Text('See nearby ${placeCategory.label.toLowerCase()} on the map'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push<PickupPoint>('/pickup-location', extra: placeCategory),
      ),
    );
  }
}
