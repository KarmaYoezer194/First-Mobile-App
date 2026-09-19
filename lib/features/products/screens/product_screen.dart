import 'package:flutter/material.dart';

import '../../cart/widgets/cart_badge.dart';
import '../widgets/product_browser.dart';

/// Standalone, full-page host for [ProductBrowser] — used by the `/products`
/// route. The Search tab embeds [ProductBrowser] directly instead, without
/// this Scaffold/AppBar wrapper.
class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key, this.initialCategorySlug});

  /// Passed straight through to [ProductBrowser] — see its doc comment.
  final String? initialCategorySlug;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: const [CartBadge()],
      ),
      body: ProductBrowser(initialCategorySlug: initialCategorySlug),
    );
  }
}
