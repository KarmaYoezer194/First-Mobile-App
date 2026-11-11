import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/go_buy_product_card.dart';
import '../../../core/widgets/pressable.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../cart/models/cart_item.dart';
import '../../cart/screens/checkout_screen.dart';
import '../../cart/widgets/fly_to_cart.dart';
import '../models/product.dart';
import '../screens/product_detail_screen.dart';

/// A [GoBuyProductCard] wired to the app's existing actions: open the
/// product, wishlist heart, quick add-to-cart (with the fly-to-cart
/// animation) and Buy Now (straight to checkout for one item).
class ProductTile extends ConsumerStatefulWidget {
  const ProductTile({
    super.key,
    required this.product,
    this.tag,
    this.index = 0,
  });

  final Product product;

  /// Pill on the image's top-right (e.g. "New" on Home, the category on
  /// Search).
  final String? tag;

  /// Grid position, used to stagger the entrance animation.
  final int index;

  @override
  ConsumerState<ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends ConsumerState<ProductTile> {
  final GlobalKey _imageKey = GlobalKey();

  Product get _product => widget.product;
  bool get _inStock => _product.stock > 0;

  void _open() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: _product.id),
      ),
    );
  }

  /// The grid's quick-add: adds one, plays the fly-to-cart animation. No
  /// confirmation sheet (that's for Product detail's deliberate add).
  void _addToCart() {
    ref.read(cartProvider.notifier).addProduct(_product);
    final box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    final start = box != null && box.attached
        ? box.localToGlobal(box.size.center(Offset.zero))
        : Offset.zero;
    flyToCart(context, start: start, imageUrl: _product.thumbnail);
  }

  void _buyNow() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen.buyNow(
          buyNowItem: CartItem(product: _product, quantity: 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite =
        ref.watch(wishlistProvider.select((ids) => ids.contains(_product.id)));

    return GoBuyProductCard(
      imageKey: _imageKey,
      imageUrl: _product.thumbnail,
      name: _product.title,
      priceText: '\$${_product.discountedPrice.toStringAsFixed(2)}',
      tag: _inStock ? widget.tag : 'Sold out',
      rating: _product.rating > 0 ? _product.rating : null,
      isFavorite: isFavorite,
      onToggleFavorite: () =>
          ref.read(wishlistProvider.notifier).toggle(_product.id),
      onTap: _open,
      onAddToCart: _inStock ? _addToCart : null,
      onBuyNow: _inStock ? _buyNow : null,
    ).entrance(index: widget.index);
  }
}

extension on Product {
  double get discountedPrice => price * (1 - discountPercentage / 100);
}

/// Short tag for a category slug, e.g. "men's clothing" → "Men's".
String shortCategoryLabel(String slug) {
  switch (slug) {
    case "men's clothing":
      return "Men's";
    case "women's clothing":
      return "Women's";
    case 'jewelery':
      return 'Jewelry';
  }
  final words = slug.replaceAll('-', ' ').split(' ');
  final first = words.isEmpty ? slug : words.first;
  return first.isEmpty ? slug : first[0].toUpperCase() + first.substring(1);
}

/// Tag shown on Home: the product's discount if it has one, otherwise
/// "New" (same rule the old Home card used).
String homeTagFor(Product product) => product.discountPercentage > 0
    ? '-${product.discountPercentage.round()}%'
    : 'New';

/// Grid layout for product cards: [columns] across, 12px column gap, 22px
/// row gap, and a row height that fits the card's square image plus its
/// text and buttons.
class ProductGridDelegate extends SliverGridDelegate {
  const ProductGridDelegate({this.columns = 2, this.textScale = 1});

  final int columns;
  final double textScale;

  static const double columnGap = 12;
  static const double rowGap = 22;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final width =
        (constraints.crossAxisExtent - columnGap * (columns - 1)) / columns;
    // Card padding 8 each side around a square image, then name, rating /
    // price row and the two buttons.
    final height = (width - 16) + 83 + 36 * textScale;
    return SliverGridRegularTileLayout(
      crossAxisCount: columns,
      mainAxisStride: height + rowGap,
      crossAxisStride: width + columnGap,
      childMainAxisExtent: height,
      childCrossAxisExtent: width,
      reverseCrossAxis: false,
    );
  }

  @override
  bool shouldRelayout(ProductGridDelegate oldDelegate) =>
      oldDelegate.columns != columns || oldDelegate.textScale != textScale;
}
