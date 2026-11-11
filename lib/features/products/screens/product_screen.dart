import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../cart/widgets/cart_badge.dart';
import '../widgets/product_browser.dart';

/// Standalone, full-page host for [ProductBrowser] — used by the `/products`
/// route (e.g. Home's "Shop Now"). The Search tab embeds [ProductBrowser]
/// directly instead.
class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key, this.initialCategorySlug});

  /// Passed straight through to [ProductBrowser] — see its doc comment.
  final String? initialCategorySlug;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  14, 8, AppConstants.pagePadding - 2, 12),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text('Products',
                          style:
                              AppFonts.serif(fontSize: 24, color: palette.ink)),
                    ),
                  ),
                  // Also the fly-to-cart target on this page.
                  const CartBadge(),
                ],
              ),
            ),
            Expanded(
              child: ProductBrowser(initialCategorySlug: initialCategorySlug),
            ),
          ],
        ),
      ),
    );
  }
}
