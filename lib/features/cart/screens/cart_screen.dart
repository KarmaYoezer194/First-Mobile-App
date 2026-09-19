import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../providers/cart_provider.dart';
import '../models/cart_item.dart';
import 'checkout_screen.dart';

/// Full shopping-cart page: line items with a quantity stepper and swipe-to-
/// remove, plus a live subtotal. "Proceed to Checkout" hands off to
/// [CheckoutScreen] for the full price breakdown, payment method, and the
/// actual order-placing API call.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: cart.isEmpty
          ? const PlaceholderState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Browse products and tap the cart icon to add something.',
            )
          : Column(
              children: [
                _SelectAllBar(
                  allSelected: cart.allSelected,
                  selectedCount: cart.selectedItems.length,
                  totalCount: cart.items.length,
                  onChanged: (v) => ref.read(cartProvider.notifier).selectAll(v),
                ),
                const Divider(height: 1),
                Expanded(child: _GroupedCartList(cart: cart)),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spaceM,
                  AppConstants.spaceSM,
                  AppConstants.spaceM,
                  AppConstants.spaceM,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cart.selectedItems.isEmpty
                              ? 'Select items to check out'
                              : 'Total (${cart.selectedItems.fold<int>(0, (s, i) => s + i.quantity)} items)',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          '\$${cart.selectedPricing.total.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spaceSM),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: cart.selectedItems.isEmpty
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                                ),
                        child: Text(
                          cart.selectedItems.isEmpty
                              ? 'Proceed to Checkout'
                              : 'Proceed to Checkout (${cart.selectedItems.length})',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Header row above the cart list: a "Select All" checkbox plus how many
/// of the cart's lines are currently checked — the same control Lazada's
/// cart shows above its item list.
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
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onChanged(!allSelected),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceSM,
          vertical: AppConstants.spaceXS,
        ),
        child: Row(
          children: [
            Checkbox(value: allSelected, onChanged: (v) => onChanged(v ?? false)),
            const SizedBox(width: 4),
            Text('Select All', style: theme.textTheme.bodyMedium),
            const Spacer(),
            Text(
              '$selectedCount of $totalCount selected',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cart items grouped into per-"shop" sections (Lazada groups by seller;
/// this catalog has no seller of its own, so [Product.brand] stands in),
/// each with its own header + select-all checkbox above its item rows.
class _GroupedCartList extends ConsumerWidget {
  const _GroupedCartList({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = <String, List<CartItem>>{};
    for (final item in cart.items) {
      grouped.putIfAbsent(item.product.brand, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(AppConstants.spaceM),
      children: [
        for (final entry in grouped.entries) ...[
          _ShopHeader(
            brand: entry.key,
            allSelected: entry.value.every((i) => cart.isSelected(i.product.id)),
            onChanged: (v) => ref
                .read(cartProvider.notifier)
                .selectGroup(entry.value.map((i) => i.product.id), v),
          ),
          const SizedBox(height: AppConstants.spaceS),
          for (final item in entry.value) ...[
            _CartItemTile(
              item: item,
              selected: cart.isSelected(item.product.id),
              onSelectedChanged: (_) =>
                  ref.read(cartProvider.notifier).toggleSelected(item.product.id),
              onQuantityChanged: (q) =>
                  ref.read(cartProvider.notifier).updateQuantity(item.product.id, q),
              onRemove: () => ref.read(cartProvider.notifier).removeProduct(item.product.id),
            ),
            const SizedBox(height: AppConstants.spaceSM),
          ],
          const SizedBox(height: AppConstants.spaceS),
        ],
      ],
    );
  }
}

/// One "shop" section's header: a store icon, the brand name standing in
/// for a seller, and a checkbox that selects/deselects every item in that
/// group at once.
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
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onChanged(!allSelected),
      borderRadius: BorderRadius.circular(AppConstants.radiusS),
      child: Row(
        children: [
          Checkbox(value: allSelected, onChanged: (v) => onChanged(v ?? false)),
          Icon(Icons.storefront_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            brand,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
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
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(item.product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          // Matches the Card's own radius (AppTheme's cardTheme, also
          // AppConstants.radiusM) so the swipe reveal doesn't show a
          // mismatched corner underneath it.
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spaceS),
          child: Row(
            children: [
              Checkbox(value: selected, onChanged: onSelectedChanged),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: item.product.thumbnail.isEmpty
                      ? Container(color: theme.colorScheme.surfaceContainerHighest)
                      // Cached: this is almost always the same image already
                      // loaded on the product grid/detail screen moments ago.
                      : CachedNetworkImage(
                          imageUrl: item.product.thumbnail,
                          fit: BoxFit.cover,
                          memCacheWidth: 128,
                          fadeInDuration: AppConstants.animMicro,
                          errorWidget: (_, __, ___) =>
                              Container(color: theme.colorScheme.surfaceContainerHighest),
                        ),
                ),
              ),
              const SizedBox(width: AppConstants.spaceSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '\$${item.lineTotal.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.product.discountPercentage > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '\$${item.lineSubtotal.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _QuantityStepper(quantity: item.quantity, onChanged: onQuantityChanged),
            ],
          ),
        ),
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove_rounded, onTap: () => onChanged(quantity - 1)),
          SizedBox(
            width: 22,
            child: Text('$quantity', textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          _StepButton(icon: Icons.add_rounded, onTap: () => onChanged(quantity + 1)),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
