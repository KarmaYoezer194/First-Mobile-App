import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../cart/widgets/cart_badge.dart';
import '../products/models/product.dart';
import '../products/screens/product_detail_screen.dart';
import '../products/screens/sorted_products_screen.dart';
import '../products/services/firestore_product_service.dart';
import '../products/services/product_api_service.dart' show ApiException;
import '../products/widgets/product_state_views.dart';
import 'widgets/home_product_card.dart';

/// Storefront-style Home tab: a search-first header (search field + camera
/// + cart), a bold promo banner, a category grid, and a "Recommended" grid
/// of real catalog products — modeled on a reference storefront mockup
/// rather than the previous generic-app-dashboard layout (greeting hero,
/// activity feed, etc.) this replaced.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final FirestoreProductService _service = FirestoreProductService();
  late Future<List<Product>> _bestSellingFuture = _loadBestSelling();

  // Wishlist toggle shown on each Best Selling card — local UI state only
  // (see HomeProductCard's doc comment). There's no wishlist backend yet;
  // this just makes the hearts tappable instead of dead decoration.
  final Set<int> _favoriteIds = {};

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<List<Product>> _loadBestSelling() async {
    final response = await _service.getProducts(limit: 6, sortBy: 'rating', order: 'desc');
    return response.products;
  }

  Future<void> _onRefresh() async {
    final future = _loadBestSelling();
    setState(() => _bestSellingFuture = future);
    await future;
  }

  void _toggleFavorite(int productId) {
    setState(() {
      if (!_favoriteIds.remove(productId)) _favoriteIds.add(productId);
    });
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id)),
    );
  }

  void _openCategory(String slug) => context.push('/products', extra: slug);

  void _openBestSelling() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SortedProductsScreen(
          title: 'Best Selling Product',
          sortBy: 'rating',
          order: 'desc',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL)
                .copyWith(top: AppConstants.spaceM, bottom: AppConstants.listBottomInset),
            children: [
              _Header(
                onSearchTap: () => context.push('/search'),
              ),
              const SizedBox(height: AppConstants.spaceL),
              const _PromoBanner(),
              const SizedBox(height: AppConstants.spaceXL),
              Text(
                'Categories',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppConstants.spaceM),
              Row(
                children: [
                  for (int i = 0; i < _categoryPills.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppConstants.spaceS),
                    Expanded(
                      child: _CategoryTile(
                        label: _categoryPills[i].$2,
                        icon: _categoryPills[i].$3,
                        onTap: () => _openCategory(_categoryPills[i].$1),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppConstants.spaceXL),
              SectionHeader(
                title: 'Recommended',
                actionLabel: 'See more',
                onAction: _openBestSelling,
              ),
              const SizedBox(height: AppConstants.spaceM),
              FutureBuilder<List<Product>>(
                future: _bestSellingFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    final message = snapshot.error is ApiException
                        ? (snapshot.error as ApiException).message
                        : 'Could not load products right now.';
                    return ProductErrorView(
                      message: message,
                      onRetry: () => setState(() => _bestSellingFuture = _loadBestSelling()),
                    );
                  }
                  final products = snapshot.data ?? const [];
                  if (products.isEmpty) {
                    return const ProductEmptyView(message: 'No products found.');
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 4 : 2,
                      mainAxisSpacing: AppConstants.spaceM,
                      crossAxisSpacing: AppConstants.spaceM,
                      childAspectRatio: 0.66,
                    ),
                    itemBuilder: (context, i) {
                      final product = products[i];
                      return HomeProductCard(
                        product: product,
                        isFavorite: _favoriteIds.contains(product.id),
                        onToggleFavorite: () => _toggleFavorite(product.id),
                        onTap: () => _openProduct(product),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// FakeStoreAPI's four real categories — see CategoryIcons' doc comment.
  /// Hardcoded rather than fetched: there are only ever these four, so a
  /// network round-trip just to draw four pills isn't worth the loading
  /// state it would need.
  static const _categoryPills = <(String, String, IconData)>[
    ('electronics', 'Electronics', Icons.devices_rounded),
    ("men's clothing", "Men's Fashion", Icons.checkroom_rounded),
    ("women's clothing", "Women's Fashion", Icons.checkroom_rounded),
    ('jewelery', 'Jewelry', Icons.diamond_rounded),
  ];
}

/// Top bar: a tappable search field (opens the Search tab) plus a camera
/// shortcut and the cart icon — mirrors a storefront's search-first header
/// rather than a plain title + separate icon row.
class _Header extends StatelessWidget {
  const _Header({required this.onSearchTap});

  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              onTap: onSearchTap,
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'What are you looking for?',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    Icon(Icons.camera_alt_outlined, size: 19, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: theme.colorScheme.surface,
          shape: const CircleBorder(),
          child: const CartBadge(),
        ),
      ],
    );
  }
}

/// Hero promo card in the storefront reference's bold coral banner style —
/// a "Best Seller!" tag, a short pitch, and a "Shop Now!" pill that jumps
/// straight to the full catalog (there's no live promotions backend to
/// point at a specific deal instead).
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppConstants.radiusL),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/products'),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.spaceL),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.bannerGradient,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                bottom: -26,
                child: Icon(
                  Icons.shopping_bag_rounded,
                  size: 130,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Best Seller!',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(
                    width: 200,
                    child: Text(
                      'Discover the perfect shopping journey!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Shop Now!',
                      style: TextStyle(
                        color: AppColors.bannerGradient[1],
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One "Categories" grid tile: icon in a soft rounded-square badge, label
/// underneath — the storefront reference's category-grid treatment, in
/// place of the previous horizontal-scrolling pill row.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Icon(icon, size: 24, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
