import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../products/models/product.dart';

/// The confirmation shown right after a deliberate "Add to Cart" on
/// Product detail (picked a quantity, tapped the button) — as opposed to
/// the grid's quick-add, which only gets the flying animation (see
/// fly_to_cart.dart).
///
/// Shows the item just added and its quantity, and lets you keep browsing
/// or jump straight to the cart.
Future<void> showAddedToCartSheet(
  BuildContext context, {
  required Product product,
  required int quantity,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
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
    final palette = context.palette;
    final unit = product.price * (1 - product.discountPercentage / 100);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppConstants.pagePadding, 0, AppConstants.pagePadding, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: palette.success, size: 20),
                const SizedBox(width: 8),
                Text('Added to cart',
                    style: AppFonts.serif(fontSize: 20, color: palette.ink)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.radiusInput),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: ColoredBox(
                      color: palette.tile,
                      child: product.thumbnail.isEmpty
                          ? null
                          : CachedNetworkImage(
                              imageUrl: product.thumbnail,
                              fit: BoxFit.cover,
                              memCacheWidth: 120,
                              errorWidget: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        'Qty $quantity · \$${(unit * quantity).toStringAsFixed(2)}',
                        style: AppFonts.sans(fontSize: 12, color: palette.hint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Keep shopping',
                    onPressed: onContinueShopping,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child:
                      PrimaryButton(label: 'View cart', onPressed: onViewCart),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
