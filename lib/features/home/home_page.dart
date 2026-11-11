import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../providers/nav_provider.dart';
import '../../providers/notifications_provider.dart';
import '../products/models/product.dart';
import '../products/services/firestore_product_service.dart';
import '../products/services/product_api_service.dart' show ApiException;
import '../products/widgets/product_state_views.dart';
import '../products/widgets/product_tile.dart';
import '../search/photo_search.dart';

/// Home tab: logo + alerts bell, search field (opens the Search tab),
/// hero banner, category circles and a "Recommended" product grid.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final FirestoreProductService _service = FirestoreProductService();
  late Future<List<Product>> _recommendedFuture = _loadRecommended();

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  /// Top-rated products — the same query the old "Best Selling" grid used.
  Future<List<Product>> _loadRecommended() async {
    final response =
        await _service.getProducts(limit: 6, sortBy: 'rating', order: 'desc');
    return response.products;
  }

  Future<void> _onRefresh() async {
    final future = _loadRecommended();
    setState(() => _recommendedFuture = future);
    await future;
  }

  void _openSearch({String? categorySlug}) {
    if (categorySlug != null) {
      ref.read(searchCategoryRequestProvider.notifier).state = categorySlug;
    }
    ref.read(bottomNavIndexProvider.notifier).state = kSearchTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppConstants.pagePadding, 14, AppConstants.pagePadding, 0),
                sliver: SliverList.list(
                  children: [
                    const _Header(),
                    const SizedBox(height: 16),
                    _SearchBox(
                      onTap: _openSearch,
                      onCamera: () => searchByPhoto(context, ref),
                    ),
                    const SizedBox(height: 18),
                    _HeroBanner(onShopNow: () => context.push('/products')),
                    const SizedBox(height: 22),
                    const SectionHeader(title: 'Categories'),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (slug, label, icon) in _categories)
                          CategoryCircle(
                            icon: icon,
                            label: label,
                            onTap: () => _openSearch(categorySlug: slug),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SectionHeader(
                      title: 'Recommended',
                      actionLabel: 'See more',
                      onAction: _openSearch,
                    ),
                    const SizedBox(height: 8),
                  ].entranceList(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 0,
                    AppConstants.pagePadding, AppConstants.spaceL),
                sliver: FutureBuilder<List<Product>>(
                  future: _recommendedFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child:
                            ProductGridSkeleton(itemCount: 4, shrinkWrap: true),
                      );
                    }
                    if (snapshot.hasError) {
                      final message = snapshot.error is ApiException
                          ? (snapshot.error as ApiException).message
                          : 'Could not load products right now.';
                      return SliverToBoxAdapter(
                        child: ProductErrorView(
                          message: message,
                          onRetry: () => setState(
                              () => _recommendedFuture = _loadRecommended()),
                        ),
                      );
                    }
                    final products = snapshot.data ?? const [];
                    if (products.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: ProductEmptyView(message: 'No products found.'),
                      );
                    }
                    return SliverGrid(
                      gridDelegate: ProductGridDelegate(
                          columns: isDesktop ? 4 : 2, textScale: textScale),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => ProductTile(
                          product: products[i],
                          tag: homeTagFor(products[i]),
                          index: i,
                        ),
                        childCount: products.length,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The catalog's four categories.
  static const _categories = <(String, String, IconData)>[
    ('electronics', 'Electronics', Icons.devices_other_outlined),
    ("men's clothing", "Men's\nFashion", Icons.checkroom_outlined),
    ("women's clothing", "Women's\nFashion", Icons.woman_outlined),
    ('jewelery', 'Jewelry', Icons.diamond_outlined),
  ];
}

extension on List<Widget> {
  /// Fades the header blocks in one after another.
  List<Widget> entranceList() => [
        for (final (i, w) in indexed) w.entrance(index: i ~/ 2),
      ];
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const GoBuyLogo(size: 26),
        const Spacer(),
        // Alerts moved out of the bottom nav into this bell.
        CircleIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Alerts',
          showDot: ref.watch(hasUnreadNotificationsProvider),
          onPressed: () => context.push('/notifications'),
        ),
      ],
    );
  }
}

/// Looks like a search field; tapping it opens the Search tab.
class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.onTap, required this.onCamera});

  final VoidCallback onTap;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppConstants.radiusInput);
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: palette.border),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: SizedBox(
          height: AppConstants.fieldHeight,
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.search_rounded, size: 19, color: palette.hint),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Search products',
                  excludeSemantics: true,
                  child: Text(
                    'What are you looking for?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.sans(fontSize: 14, color: palette.hint),
                  ),
                ),
              ),
              FieldIconButton(
                icon: Icons.photo_camera_outlined,
                tooltip: 'Search by photo',
                onPressed: onCamera,
              ),
              const SizedBox(width: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onShopNow});

  final VoidCallback onShopNow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppConstants.radiusL);

    return Material(
      color: palette.heroCard,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onShopNow,
        child: Stack(
          children: [
            Positioned(
              right: -14,
              bottom: -30,
              child: ExcludeSemantics(
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 150,
                  color: palette.gold.withValues(alpha: 0.35),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: palette.gold.withValues(alpha: 0.18),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded,
                            size: 13, color: palette.goldLight),
                        const SizedBox(width: 4),
                        Text(
                          'Best Seller!',
                          style: AppFonts.sans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: palette.goldLight),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: Text(
                      'Discover the perfect shopping journey!',
                      style: AppFonts.serif(
                        fontSize: 23,
                        fontWeight: FontWeight.w400,
                        color: palette.onHeroCard,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Pressable(
                    child: Material(
                      color: AppColors.background,
                      shape: const StadiumBorder(),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: onShopNow,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Text(
                            'Shop Now',
                            style: AppFonts.sans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink),
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
      ),
    );
  }
}
