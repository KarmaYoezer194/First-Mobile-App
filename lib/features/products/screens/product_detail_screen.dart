import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../cart/models/cart_item.dart';
import '../../cart/models/pricing_summary.dart';
import '../../cart/screens/checkout_screen.dart';
import '../../cart/widgets/added_to_cart_sheet.dart';
import '../../cart/widgets/cart_badge.dart';
import '../../cart/widgets/fly_to_cart.dart';
import '../../pickup_location/constants/place_categories.dart';
import '../../pickup_location/models/pickup_point.dart';
import '../models/product.dart';
import '../services/firestore_product_service.dart';
import '../services/product_api_service.dart' show ApiException;
import '../widgets/product_state_views.dart';
import '../widgets/product_tile.dart';

/// Height of the image area at the top of the screen.
const double _kImageHeight = 330;

/// How far the content sheet overlaps the image.
const double _kSheetOverlap = 20;

/// Fetches and displays a single product by id: image gallery, category,
/// stock, name, price, sizes (clothing), quantity, pickup shortcut and
/// description, with a sticky Add to Cart / Buy Now bar.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final FirestoreProductService _service = FirestoreProductService();

  late Future<Product> _future;
  int _quantity = 1;

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
    ref
        .read(cartProvider.notifier)
        .addProduct(product, quantity: addedQuantity);
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
      body: Stack(
        children: [
          FutureBuilder<Product>(
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
                return const ProductEmptyView(message: 'Product not found.');
              }
              return _ProductDetailBody(
                product: product,
                quantity: _quantity,
                onQuantityChanged: (q) =>
                    setState(() => _quantity = q.clamp(1, 99)),
              );
            },
          ),
          // Floating top bar: back, wishlist, cart.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Back',
                    bordered: false,
                    shadow: true,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  Consumer(
                    builder: (context, ref, _) {
                      final saved = ref.watch(wishlistProvider
                          .select((ids) => ids.contains(widget.productId)));
                      return CircleIconButton(
                        icon: saved
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        iconColor: saved ? context.palette.gold : null,
                        tooltip:
                            saved ? 'Remove from wishlist' : 'Add to wishlist',
                        bordered: false,
                        shadow: true,
                        // Shared in-memory wishlist, so the heart matches
                        // Home/Search.
                        onPressed: () => ref
                            .read(wishlistProvider.notifier)
                            .toggle(widget.productId),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  const CartBadge(shadow: true),
                ],
              ),
            ),
          ),
        ],
      ),
      // Reuses the same cached _future (no extra network call) just to know
      // whether a product is loaded — the bar only makes sense once there's
      // something to buy.
      bottomNavigationBar: FutureBuilder<Product>(
        future: _future,
        builder: (context, snapshot) {
          final product = snapshot.data;
          if (product == null) return const SizedBox.shrink();
          return _AddToCartBar(
            product: product,
            onAddToCart: (start) => _addToCart(product, start),
            onBuyNow: () => _buyNow(product),
          );
        },
      ),
    );
  }
}

/// Sticky bottom bar: Add to Cart (outline) + Buy Now (solid), equal width.
class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({
    required this.product,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final Product product;
  final ValueChanged<Offset> onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bool inStock = product.stock > 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppConstants.pagePadding, 14, AppConstants.pagePadding, 14),
          child: Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (buttonContext) => SecondaryButton(
                    label: 'Add to Cart',
                    icon: Icons.shopping_bag_outlined,
                    onPressed: inStock
                        ? () {
                            final box =
                                buttonContext.findRenderObject() as RenderBox?;
                            onAddToCart(box != null
                                ? box
                                    .localToGlobal(box.size.center(Offset.zero))
                                : Offset.zero);
                          }
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: inStock ? 'Buy Now' : 'Out of Stock',
                  onPressed: inStock ? onBuyNow : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder in the shape of the real layout while the product loads.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Container(height: _kImageHeight, color: palette.tile),
        const Padding(
          padding: EdgeInsets.all(AppConstants.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBlock(width: 90, height: 12, radius: 6),
              SizedBox(height: 14),
              SkeletonBlock(height: 22, radius: 8),
              SizedBox(height: 8),
              SkeletonBlock(width: 220, height: 22, radius: 8),
              SizedBox(height: 18),
              SkeletonBlock(width: 140, height: 30, radius: 8),
              SizedBox(height: 26),
              SkeletonBlock(height: 64),
              SizedBox(height: 22),
              SkeletonBlock(height: 14, radius: 6),
              SizedBox(height: 8),
              SkeletonBlock(height: 14, radius: 6),
              SizedBox(height: 8),
              SkeletonBlock(width: 200, height: 14, radius: 6),
            ],
          ),
        ),
      ],
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: AppConstants.animShimmer,
          color: palette.surface.withValues(alpha: 0.5),
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
  /// is a real, meaningful attribute of the product. Display-only, as
  /// before: the chosen size isn't stored with the cart item.
  bool get _showSizePicker =>
      widget.product.category.toLowerCase().contains('clothing');

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final product = widget.product;
    final images =
        product.images.isNotEmpty ? product.images : [product.thumbnail];
    final hasDiscount = product.discountPercentage > 0;
    final price = product.price * (1 - product.discountPercentage / 100);
    final hasBrand =
        product.brand.isNotEmpty && product.brand.toLowerCase() != 'unbranded';

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ImageGallery(images: images, productId: product.id),
        Transform.translate(
          offset: const Offset(0, -_kSheetOverlap),
          child: Container(
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.radiusSheet)),
            ),
            padding: const EdgeInsets.fromLTRB(
                AppConstants.pagePadding, 22, AppConstants.pagePadding, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shortCategoryLabel(product.category).toUpperCase(),
                        style: AppFonts.sans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: palette.gold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    _StockIndicator(stock: product.stock),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  product.title,
                  style: AppFonts.sans(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                      height: 1.3),
                ),
                if (hasBrand) ...[
                  const SizedBox(height: 4),
                  Text('by ${product.brand}',
                      style: AppFonts.sans(fontSize: 12, color: palette.hint)),
                ],
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('\$${price.toStringAsFixed(2)}',
                        style: AppFonts.serif(
                            fontSize: 26, color: palette.ink, height: 1)),
                    if (hasDiscount) ...[
                      const SizedBox(width: 10),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: AppFonts.sans(fontSize: 13, color: palette.hint)
                            .copyWith(
                          decoration: TextDecoration.lineThrough,
                          decorationColor: palette.hint,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusPill),
                        ),
                        child: Text(
                          '-${product.discountPercentage.round()}%',
                          style: AppFonts.sans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.background),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (product.rating > 0) ...[
                      Icon(Icons.star_rounded, size: 16, color: palette.gold),
                      const SizedBox(width: 3),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: AppFonts.sans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: palette.ink),
                      ),
                    ],
                  ],
                ),
                if (price >= PricingSummary.freeShippingThreshold) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 15, color: palette.success),
                      const SizedBox(width: 6),
                      Text(
                        'Free shipping',
                        style: AppFonts.sans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.success),
                      ),
                    ],
                  ),
                ],
                if (_showSizePicker) ...[
                  const SizedBox(height: 20),
                  const _Label('Size'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final size in _sizes)
                        AppChip(
                          label: size,
                          selected: size == _selectedSize,
                          onTap: () => setState(() => _selectedSize = size),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    const _Label('Quantity'),
                    const Spacer(),
                    QuantityStepper(
                      value: widget.quantity,
                      max: 99,
                      onChanged: widget.onQuantityChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _FindPickupCard(category: product.category),
                const SizedBox(height: 20),
                const _Label('Description'),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: AppFonts.sans(
                      fontSize: 13, color: palette.inkMuted, height: 1.6),
                ),
              ],
            ),
          ),
        ).entrance(),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppFonts.sans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.palette.ink),
      );
}

/// "● In stock · N left" in green, or "● Out of stock" in red.
class _StockIndicator extends StatelessWidget {
  const _StockIndicator({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final inStock = stock > 0;
    final color = inStock ? palette.success : palette.danger;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          inStock ? 'In stock · $stock left' : 'Out of stock',
          style: AppFonts.sans(
              fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

/// Opens the pickup map with a place type preselected from this product's
/// category, so it lands on nearby places relevant to what's being bought.
class _FindPickupCard extends StatelessWidget {
  const _FindPickupCard({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final placeCategory = PlaceCategories.forProductCategory(category);
    return ListRowCard(children: [
      ListRow(
        icon: Icons.location_on_outlined,
        title: 'Find pickup near me',
        subtitle: 'See nearby ${placeCategory.label.toLowerCase()} on the map',
        onTap: () =>
            context.push<PickupPoint>('/pickup-location', extra: placeCategory),
      ),
    ]);
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
      duration: AppConstants.animToggle,
      curve: AppConstants.animCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      height: _kImageHeight + topInset,
      color: palette.tile,
      padding: EdgeInsets.only(
          top: topInset + 56, bottom: _kSheetOverlap + 18, left: 24, right: 24),
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _DetailImage(url: widget.images[i]),
            ),
          ),
          // Tappable dots to jump between images.
          if (widget.images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: -14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.images.length; i++)
                    Semantics(
                      button: true,
                      selected: i == _index,
                      label: 'Image ${i + 1} of ${widget.images.length}',
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _selectPage(i),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: AnimatedContainer(
                            duration: AppConstants.animToggle,
                            width: i == _index ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? palette.ink
                                  : palette.switchTrackOff,
                              borderRadius: BorderRadius.circular(
                                  AppConstants.radiusPill),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
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
      fadeInDuration: AppConstants.animPress,
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Center(
      child: Icon(Icons.image_not_supported_outlined,
          size: 44, color: context.palette.hint),
    );
  }
}
