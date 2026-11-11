import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/nav_provider.dart';
import '../../products/widgets/product_tile.dart' show shortCategoryLabel;
import '../models/cart_item.dart';
import '../models/pricing_summary.dart';
import 'checkout_screen.dart';

/// Cart (a bottom-nav tab, and also the pushed `/cart` page): select-all,
/// line items with checkbox, quantity stepper, remove and swipe-to-remove,
/// a free-shipping banner, the price summary for the checked items, and a
/// sticky Checkout button.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  /// From the tab there's nothing to go back to, so jump to Home instead.
  void _startShopping(BuildContext context, WidgetRef ref) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      ref.read(bottomNavIndexProvider.notifier).state = 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final palette = context.palette;
    final pricing = cart.selectedPricing;
    final canPop = Navigator.of(context).canPop();
    final itemCount = cart.totalQuantity;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppConstants.pagePadding, 12, AppConstants.pagePadding, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (canPop) ...[
                      Transform.translate(
                        offset: const Offset(-6, 0),
                        child: CircleIconButton(
                          icon: Icons.chevron_left_rounded,
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Semantics(
                      header: true,
                      child: Text('My Cart',
                          style:
                              AppFonts.serif(fontSize: 26, color: palette.ink)),
                    ),
                    const Spacer(),
                    if (!cart.isEmpty)
                      Text(
                        '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                        style: AppFonts.sans(fontSize: 12, color: palette.hint),
                      ),
                  ],
                ),
              ),
            ),
            if (cart.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: PlaceholderState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Your cart is empty',
                  message:
                      'Browse products and tap Add to Cart to put something here.',
                  action: PrimaryButton(
                    label: 'Start shopping',
                    expand: false,
                    onPressed: () => _startShopping(context, ref),
                  ),
                ).entrance(),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppConstants.pagePadding, 14, AppConstants.pagePadding, 0),
                sliver: SliverList.list(children: [
                  _FreeShippingBanner(pricing: pricing),
                  const SizedBox(height: 6),
                  _SelectAllBar(
                    allSelected: cart.allSelected,
                    selectedCount: cart.selectedItems.length,
                    totalCount: cart.items.length,
                    onChanged: (v) =>
                        ref.read(cartProvider.notifier).selectAll(v),
                  ),
                  const SizedBox(height: 4),
                ]),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.pagePadding),
                sliver: _GroupedCartList(cart: cart),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppConstants.pagePadding, 6, AppConstants.pagePadding, 24),
                sliver: SliverToBoxAdapter(
                  child: cart.selectedItems.isEmpty
                      ? Text(
                          'Tick the items you want to check out.',
                          textAlign: TextAlign.center,
                          style:
                              AppFonts.sans(fontSize: 12, color: palette.hint),
                        )
                      : SummaryCard(
                          lines: _summaryLines(pricing, palette),
                          totalValue: _money(pricing.total),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppConstants.pagePadding, 8, AppConstants.pagePadding, 12),
                child: PrimaryButton(
                  label: cart.selectedItems.isEmpty
                      ? 'Select items to check out'
                      : 'Checkout · ${_money(pricing.total)}',
                  onPressed: cart.selectedItems.isEmpty
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const CheckoutScreen()),
                          ),
                ),
              ),
            ),
    );
  }

  static List<SummaryLine> _summaryLines(
      PricingSummary pricing, AppPalette palette) {
    return [
      SummaryLine('Subtotal', _money(pricing.subtotal)),
      if (pricing.discount > 0)
        SummaryLine('Discount', '-${_money(pricing.discount)}',
            valueColor: palette.success),
      SummaryLine(
        'Shipping',
        pricing.shipping == 0 ? 'Free' : _money(pricing.shipping),
        valueColor: pricing.shipping == 0 ? palette.success : null,
      ),
      SummaryLine(
        'Tax (${(PricingSummary.taxRate * 100).toStringAsFixed(0)}%)',
        _money(pricing.tax),
      ),
    ];
  }
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

/// Ink banner: free shipping unlocked, or how much more is needed.
class _FreeShippingBanner extends StatelessWidget {
  const _FreeShippingBanner({required this.pricing});

  final PricingSummary pricing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final remaining = pricing.remainingForFreeShipping;
    final threshold =
        '\$${PricingSummary.freeShippingThreshold.toStringAsFixed(0)}';
    final base =
        AppFonts.sans(fontSize: 12.5, color: palette.onHeroCard, height: 1.35);
    final bold = AppFonts.sans(
        fontSize: 12.5, fontWeight: FontWeight.w700, color: palette.goldLight);

    final TextSpan message = remaining <= 0 && pricing.subtotal > 0
        ? TextSpan(style: base, children: [
            const TextSpan(text: "You've unlocked "),
            TextSpan(text: 'free shipping', style: bold),
            TextSpan(text: ' on orders over $threshold'),
          ])
        : TextSpan(style: base, children: [
            const TextSpan(text: 'Add '),
            TextSpan(text: _money(remaining), style: bold),
            const TextSpan(text: ' more for '),
            TextSpan(text: 'free shipping', style: bold),
          ]);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.heroCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusInput),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 18, color: palette.goldLight),
          const SizedBox(width: 10),
          Expanded(child: Text.rich(message)),
        ],
      ),
    );
  }
}

/// "Select all" checkbox plus how many lines are checked.
class _SelectAllBar extends StatelessWidget {
  const _SelectAllBar({
    required this.allSelected,
    required this.selectedCount,
    required this.totalCount,
    required this.onChanged,
  });

  final bool allSelected;
  final int selectedCount;
  final int totalCount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: () => onChanged(!allSelected),
      borderRadius: BorderRadius.circular(AppConstants.radiusS),
      child: Row(
        children: [
          Checkbox(value: allSelected, onChanged: (v) => onChanged(v ?? false)),
          Text('Select all',
              style: AppFonts.sans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.ink)),
          const Spacer(),
          Text('$selectedCount of $totalCount selected',
              style: AppFonts.sans(fontSize: 12, color: palette.hint)),
        ],
      ),
    );
  }
}

/// Cart items grouped per "shop" (the product's brand stands in for a
/// seller). Group headers, each with its own select checkbox, only show
/// when there's more than one group — with one group they'd just repeat
/// "Select all".
class _GroupedCartList extends ConsumerWidget {
  const _GroupedCartList({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = <String, List<CartItem>>{};
    for (final item in cart.items) {
      grouped.putIfAbsent(item.product.brand, () => []).add(item);
    }
    final showHeaders = grouped.length > 1;
    final notifier = ref.read(cartProvider.notifier);

    return SliverList.list(
      children: [
        for (final entry in grouped.entries) ...[
          if (showHeaders)
            _ShopHeader(
              brand: entry.key,
              allSelected:
                  entry.value.every((i) => cart.isSelected(i.product.id)),
              onChanged: (v) =>
                  notifier.selectGroup(entry.value.map((i) => i.product.id), v),
            ),
          for (final item in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CartItemCard(
                item: item,
                selected: cart.isSelected(item.product.id),
                onSelectedChanged: (_) =>
                    notifier.toggleSelected(item.product.id),
                onQuantityChanged: (q) =>
                    notifier.updateQuantity(item.product.id, q),
                onRemove: () => notifier.removeProduct(item.product.id),
              ),
            ),
        ],
      ],
    );
  }
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({
    required this.brand,
    required this.allSelected,
    required this.onChanged,
  });

  final String brand;
  final bool allSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: () => onChanged(!allSelected),
      child: Row(
        children: [
          Checkbox(value: allSelected, onChanged: (v) => onChanged(v ?? false)),
          Icon(Icons.storefront_outlined, size: 16, color: palette.inkMuted),
          const SizedBox(width: 6),
          Text(brand,
              style: AppFonts.sans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.ink)),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.selected,
    required this.onSelectedChanged,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final CartItem item;
  final bool selected;
  final ValueChanged<bool?> onSelectedChanged;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final product = item.product;
    final radius = BorderRadius.circular(AppConstants.radiusM);

    return Dismissible(
      key: ValueKey(product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
        decoration:
            BoxDecoration(color: palette.dangerBg, borderRadius: radius),
        child: Icon(Icons.delete_outline_rounded, color: palette.danger),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(2, 10, 10, 10),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: radius,
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Checkbox(value: selected, onChanged: onSelectedChanged),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusInput),
              child: SizedBox(
                width: 84,
                height: 84,
                child: ColoredBox(
                  color: palette.tile,
                  child: product.thumbnail.isEmpty
                      ? Icon(Icons.image_outlined, color: palette.hint)
                      // Cached: almost always the same image already loaded
                      // on the product grid/detail screen moments ago.
                      : CachedNetworkImage(
                          imageUrl: product.thumbnail,
                          fit: BoxFit.cover,
                          memCacheWidth: 168,
                          fadeInDuration: AppConstants.animPress,
                          errorWidget: (_, __, ___) =>
                              Icon(Icons.image_outlined, color: palette.hint),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.sans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: palette.ink),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              shortCategoryLabel(product.category),
                              style: AppFonts.sans(
                                  fontSize: 11, color: palette.hint),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          tooltip: 'Remove ${product.title}',
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          color: palette.hint,
                          onPressed: onRemove,
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _money(item.lineTotal),
                              style: AppFonts.sans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: palette.ink),
                            ),
                            if (product.discountPercentage > 0)
                              Text(
                                _money(item.lineSubtotal),
                                style: AppFonts.sans(
                                        fontSize: 11, color: palette.hint)
                                    .copyWith(
                                        decoration: TextDecoration.lineThrough),
                              ),
                          ],
                        ),
                      ),
                      // Going below 1 removes the item, as before.
                      QuantityStepper(
                        value: item.quantity,
                        min: 0,
                        onChanged: onQuantityChanged,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
