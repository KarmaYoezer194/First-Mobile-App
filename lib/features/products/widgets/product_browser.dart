import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../providers/nav_provider.dart';
import '../core/category_icons.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/firestore_product_service.dart';
import '../services/product_api_service.dart' show ApiException;
import 'product_state_views.dart';
import 'product_tile.dart';

/// Sentinel category slug for "show every product, unfiltered".
const String _kAllCategorySlug = 'all';

/// The grid's sort order — mirrors a storefront's "Popular / Latest / Best
/// Sellers / Price" tab row. [popular] and [bestSellers] both sort by
/// rating: FakeStoreAPI has no real sales-volume field to rank by, so
/// rating is the closest honest proxy for either.
enum _ProductSort { popular, latest, bestSellers, price }

extension on _ProductSort {
  String get label => switch (this) {
        _ProductSort.popular => 'Popular',
        _ProductSort.latest => 'Latest',
        _ProductSort.bestSellers => 'Best Sellers',
        _ProductSort.price => 'Price',
      };
}

/// Search, category filter, sort, and an infinitely-paginated product grid,
/// with loading / empty / error states.
///
/// Body-only (no [Scaffold]/[AppBar]) so it can be embedded in the Search
/// tab or the standalone `/products` page.
class ProductBrowser extends ConsumerStatefulWidget {
  const ProductBrowser({
    super.key,
    this.initialCategorySlug,
    this.onCamera,
    this.countRowTrailing,
  });

  /// Pre-selects a category chip on first build. Defaults to "All".
  final String? initialCategorySlug;

  /// Shows a camera button inside the search field when set.
  final VoidCallback? onCamera;

  /// Shown at the right of the "N products" row (Search's "Pickup near
  /// me" pill).
  final Widget? countRowTrailing;

  @override
  ConsumerState<ProductBrowser> createState() => _ProductBrowserState();
}

class _ProductBrowserState extends ConsumerState<ProductBrowser> {
  final FirestoreProductService _service = FirestoreProductService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Guards against a stale response (from an old search/category/sort)
  // landing after a newer request has already started.
  int _requestId = 0;

  List<Product> _products = [];
  int? _total;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _paginationError;

  List<Category> _categories = [];
  bool _categoriesLoading = true;
  late String _selectedCategorySlug =
      widget.initialCategorySlug ?? _kAllCategorySlug;

  String _activeQuery = '';

  _ProductSort _sort = _ProductSort.popular;
  // Only meaningful while `_sort == _ProductSort.price`: tapping the Price
  // tab again flips cheapest-first <-> priciest-first instead of doing
  // nothing on a re-tap.
  bool _priceDescending = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCategories();
    _loadPage(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final nearBottom = position.pixels >= position.maxScrollExtent - 300;
    if (nearBottom && !_isLoading && !_isLoadingMore && _hasMore) {
      _loadPage(reset: false);
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      final categories = await _service.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoriesLoading = false;
      });
    } on ApiException {
      // Categories are a secondary feature (chips) — fail quietly so a
      // categories outage doesn't block browsing the product grid.
      if (!mounted) return;
      setState(() => _categoriesLoading = false);
    }
  }

  Future<void> _loadPage({required bool reset}) async {
    final int myRequestId = reset ? ++_requestId : _requestId;

    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _paginationError = null;
        _hasMore = true;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
        _paginationError = null;
      });
    }

    final int skip = reset ? 0 : _products.length;

    try {
      final ProductListResponse response = await _fetch(skip: skip);
      if (!mounted || myRequestId != _requestId) return; // stale, discard

      setState(() {
        _products =
            reset ? response.products : [..._products, ...response.products];
        _total = response.total;
        _hasMore = response.products.isNotEmpty && !response.isFullyLoaded;
        _isLoading = false;
        _isLoadingMore = false;
        _error = null;
        _paginationError = null;
      });
    } on ApiException catch (e) {
      if (!mounted || myRequestId != _requestId) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        if (reset) {
          _error = e.message;
        } else {
          _paginationError = e.message;
        }
      });
    }
  }

  (String?, String?) get _sortParams => switch (_sort) {
        _ProductSort.popular => ('rating', 'desc'),
        _ProductSort.bestSellers => ('rating', 'desc'),
        _ProductSort.latest => ('id', 'desc'),
        _ProductSort.price => ('price', _priceDescending ? 'desc' : 'asc'),
      };

  Future<ProductListResponse> _fetch({required int skip}) {
    final (sortBy, order) = _sortParams;
    if (_activeQuery.isNotEmpty) {
      return _service.searchProducts(_activeQuery,
          skip: skip, sortBy: sortBy, order: order);
    }
    if (_selectedCategorySlug != _kAllCategorySlug) {
      return _service.getProductsByCategory(
        _selectedCategorySlug,
        skip: skip,
        sortBy: sortBy,
        order: order,
      );
    }
    return _service.getProducts(skip: skip, sortBy: sortBy, order: order);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.debounceFast, () {
      final query = value.trim();
      if (query == _activeQuery) return;
      setState(() => _activeQuery = query);
      _loadPage(reset: true);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  void _onCategorySelected(String slug) {
    if (slug == _selectedCategorySlug) return;
    _debounce?.cancel();
    setState(() {
      _selectedCategorySlug = slug;
      _activeQuery = '';
      _searchController.clear();
    });
    _loadPage(reset: true);
  }

  void _onSortSelected(_ProductSort sort) {
    setState(() {
      if (sort == _ProductSort.price && _sort == _ProductSort.price) {
        // Re-tapping the already-active "Price" tab flips direction —
        // there's no separate ascending/descending control otherwise.
        _priceDescending = !_priceDescending;
      } else {
        _sort = sort;
      }
    });
    _loadPage(reset: true);
  }

  Future<void> _openFilterSheet() async {
    final selected = await showModalBottomSheet<_ProductSort>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final palette = ctx.palette;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 0,
                AppConstants.pagePadding, AppConstants.spaceM),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sort & Filter',
                    style: AppFonts.serif(fontSize: 20, color: palette.ink)),
                const SizedBox(height: 14),
                const SectionLabel('Sort by'),
                const SizedBox(height: 8),
                ListRowCard(children: [
                  for (final option in _ProductSort.values)
                    ListRow(
                      icon: switch (option) {
                        _ProductSort.popular =>
                          Icons.local_fire_department_outlined,
                        _ProductSort.latest => Icons.schedule_rounded,
                        _ProductSort.bestSellers => Icons.star_outline_rounded,
                        _ProductSort.price => Icons.sell_outlined,
                      },
                      title: option.label,
                      trailing: option == _sort
                          ? Icon(Icons.check_rounded,
                              size: 20, color: palette.ink)
                          : const SizedBox.shrink(),
                      onTap: () => Navigator.pop(ctx, option),
                    ),
                ]),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) _onSortSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    // Home's category circles ask the Search tab to show a category.
    ref.listen<String?>(searchCategoryRequestProvider, (_, slug) {
      if (slug == null) return;
      _onCategorySelected(slug);
      ref.read(searchCategoryRequestProvider.notifier).state = null;
    });

    const pad = EdgeInsets.symmetric(horizontal: AppConstants.pagePadding);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: pad,
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _searchController,
                  hint: 'What are you looking for?',
                  icon: Icons.search_rounded,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  trailing: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, _) {
                      if (value.text.isNotEmpty) {
                        return IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: _clearSearch,
                        );
                      }
                      if (widget.onCamera == null) {
                        return const SizedBox.shrink();
                      }
                      return FieldIconButton(
                        icon: Icons.photo_camera_outlined,
                        tooltip: 'Search by photo',
                        onPressed: widget.onCamera,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _FilterButton(onTap: _openFilterSheet),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: pad,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.palette.border)),
            ),
            child: SortTabs(
              selectedIndex: _sort.index,
              onChanged: (i) => _onSortSelected(_ProductSort.values[i]),
              items: [
                for (final option in _ProductSort.values)
                  SortTabItem(
                    option.label,
                    trailingIcon: option == _ProductSort.price
                        ? (_sort == _ProductSort.price && _priceDescending
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded)
                        : null,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _CategoryChips(
          categories: _categories,
          isLoading: _categoriesLoading,
          selectedSlug: _selectedCategorySlug,
          onSelected: _onCategorySelected,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppConstants.pagePadding, 6, AppConstants.pagePadding, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _isLoading || _total == null ? '' : '$_total products',
                  style:
                      AppFonts.sans(fontSize: 12, color: context.palette.hint),
                ),
              ),
              if (widget.countRowTrailing != null) widget.countRowTrailing!,
            ],
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading && _products.isEmpty) {
      return const ProductGridSkeleton();
    }

    if (_error != null && _products.isEmpty) {
      return ProductErrorView(
          message: _error!, onRetry: () => _loadPage(reset: true));
    }

    if (_products.isEmpty) {
      return ProductEmptyView(
        icon: _activeQuery.isNotEmpty
            ? Icons.search_off_rounded
            : Icons.inventory_2_outlined,
        message: _activeQuery.isNotEmpty
            ? 'No products match "$_activeQuery".'
            : 'No products found in this category.',
      );
    }

    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;
    return RefreshIndicator(
      onRefresh: () => _loadPage(reset: true),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppConstants.pagePadding, 4, AppConstants.pagePadding, 0),
            sliver: SliverGrid(
              gridDelegate: ProductGridDelegate(
                columns: isDesktop ? 4 : 2,
                textScale: MediaQuery.textScalerOf(context).scale(1),
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = _products[index];
                  return ProductTile(
                    product: product,
                    tag: shortCategoryLabel(product.category),
                    index: index,
                  );
                },
                childCount: _products.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildFooter()),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final palette = context.palette;
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }
    if (_paginationError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Text(
              _paginationError!,
              textAlign: TextAlign.center,
              style: AppFonts.sans(fontSize: 12, color: palette.inkMuted),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Retry',
              expand: false,
              onPressed: () => _loadPage(reset: false),
            ),
          ],
        ),
      );
    }
    if (!_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'You\'ve reached the end · ${_products.length} products',
          textAlign: TextAlign.center,
          style: AppFonts.sans(fontSize: 11, color: palette.hint),
        ),
      );
    }
    return const SizedBox(height: 24);
  }
}

/// 50×50 ink rounded-square button that opens the sort/filter sheet.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppConstants.radiusInput);
    return Tooltip(
      message: 'Sort & filter',
      child: Semantics(
        button: true,
        label: 'Sort and filter',
        excludeSemantics: true,
        child: Pressable(
          child: Material(
            color: scheme.primary,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: SizedBox(
                width: AppConstants.fieldHeight,
                height: AppConstants.fieldHeight,
                child:
                    Icon(Icons.tune_rounded, size: 20, color: scheme.onPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.isLoading,
    required this.selectedSlug,
    required this.onSelected,
  });

  final List<Category> categories;
  final bool isLoading;
  final String selectedSlug;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    const padding = EdgeInsets.symmetric(horizontal: AppConstants.pagePadding);

    if (isLoading) {
      return SizedBox(
        height: AppConstants.minTapTarget,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: padding,
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) => Center(
            child: const SkeletonBlock(
                    width: 96, height: 34, radius: AppConstants.radiusPill)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(
                    duration: AppConstants.animShimmer,
                    color: palette.surface.withValues(alpha: 0.5)),
          ),
        ),
      );
    }

    return SizedBox(
      height: AppConstants.minTapTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final bool isAll = index == 0;
          final String slug =
              isAll ? _kAllCategorySlug : categories[index - 1].slug;
          final String label = isAll ? 'All' : categories[index - 1].name;
          final IconData icon =
              isAll ? CategoryIcons.all : CategoryIcons.iconFor(slug);
          return AppChip(
            label: label,
            icon: icon,
            selected: slug == selectedSlug,
            onTap: () => onSelected(slug),
          );
        },
      ),
    );
  }
}
