import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../products/models/product.dart';

/// The confirmation Lazada/Shopee show right after a deliberate "Add to
/// Cart" (picked a quantity, tapped the button) — as opposed to the
/// grid's quick-add, which only gets the flying animation (see
/// fly_to_cart.dart) since interrupting quick browsing with a sheet every
/// time would defeat the point of "quick".
///
/// Shows the item just added, its quantity, and lets you either keep
/// browsing or jump straight to the cart.
Future<void> showAddedToCartSheet(
  BuildContext context, {
  required Product product,
  required int quantity,
}) {
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusXL)),
    ),
    builder: (sheetContext) => _AddedToCartSheet(
      product: product,
      quantity: quantity,
      onViewCart: () {
        Navigator.of(sheetContext).pop();
        sheetContext.push('/cart');
      },
      onContinueShopping: () => Navigator.of(sheetContext).pop(),
    ),
  );
}

class _AddedToCartSheet extends StatelessWidget {
  const _AddedToCartSheet({
    required this.product,
    required this.quantity,
    required this.onViewCart,
    required this.onContinueShopping,
  });

  final Product product;
  final int quantity;
  final VoidCallback onViewCart;
  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spaceL,
          AppConstants.spaceM,
          AppConstants.spaceL,
          AppConstants.spaceL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
                const SizedBox(width: 8),
                Text('Added to Cart', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppConstants.spaceL),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: product.thumbnail.isEmpty
                        ? Container(color: theme.colorScheme.surfaceContainerHighest)
                        : CachedNetworkImage(
                            imageUrl: product.thumbnail,
                            fit: BoxFit.cover,
                            memCacheWidth: 112,
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
                        product.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Qty: $quantity  •  \$${(product.price * quantity).toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spaceL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onContinueShopping,
                    child: const Text('Continue Shopping'),
                  ),
                ),
                const SizedBox(width: AppConstants.spaceSM),
                Expanded(
                  child: FilledButton(
                    onPressed: onViewCart,
                    child: const Text('View Cart'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
