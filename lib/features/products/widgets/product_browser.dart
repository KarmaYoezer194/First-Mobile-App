import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../core/category_icons.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../screens/product_detail_screen.dart';
import '../services/firestore_product_service.dart';
import '../services/product_api_service.dart' show ApiException;
import 'product_card.dart';
import 'product_state_views.dart';

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
/// with every loading/empty/error state the assignment calls for.
///
/// This is the body-only version — no [Scaffold]/[AppBar] — so it can be
/// embedded inside any page (the dedicated [ProductScreen] route, or the
/// Search tab) as well as used standalone.
class ProductBrowser extends StatefulWidget {
  const ProductBrowser({super.key, this.initialCategorySlug});

  /// Pre-selects a category chip on first build — e.g. Home's category
  /// pills deep-linking straight into "electronics" instead of landing on
  /// the unfiltered "All" view. Defaults to "All" when omitted.
  final String? initialCategorySlug;

  @override
  State<ProductBrowser> createState() => _ProductBrowserState();
}

class _ProductBrowserState extends State<ProductBrowser> {
  final FirestoreProductService _service = FirestoreProductService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Guards against a stale response (from an old search/category/sort)
  // landing after a newer request has already started.
  int _requestId = 0;

  List<Product> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _paginationError;

  List<Category> _categories = [];
  bool _categoriesLoading = true;
  late String _selectedCategorySlug = widget.initialCategorySlug ?? _kAllCategorySlug;

  String _activeQuery = '';

  _ProductSort _sort = _ProductSort.popular;
  // Only meaningful while `_sort == _ProductSort.price`: tapping the Price
  // tab again flips cheapest-first <-> priciest-first instead of doing
  // nothing on a re-tap.
  bool _priceDescending = false;

  // Local-only wishlist toggles — see HomeProductCard's doc comment on the
  // same pattern; no wishlist backend to persist to yet, and kept separate
  // from Home's own set since this is a different browsing surface.
  final Set<int> _favoriteIds = {};

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
        _products = reset ? response.products : [..._products, ...response.products];
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
      return _service.searchProducts(_activeQuery, skip: skip, sortBy: sortBy, order: order);
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

  void _toggleFavorite(int productId) {
    setState(() {
      if (!_favoriteIds.remove(productId)) _favoriteIds.add(productId);
    });
  }

  Future<void> _openFilterSheet() async {
    final selected = await showModalBottomSheet<_ProductSort>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusL)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppConstants.spaceM),
              child: Text('Sort & Filter', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final option in _ProductSort.values)
              ListTile(
                title: Text(option.label),
                trailing: option == _sort ? const Icon(Icons.check_rounded) : null,
                onTap: () => Navigator.pop(ctx, option),
              ),
            const SizedBox(height: AppConstants.spaceS),
          ],
        ),
      ),
    );
    if (selected != null) _onSortSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SearchField(controller: _searchController, onChanged: _onSearchChanged),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _FilterButton(onTap: _openFilterSheet),
            ),
          ],
        ),
        _SortTabs(selected: _sort, onSelected: _onSortSelected),
        const SizedBox(height: AppConstants.spaceS),
        _CategoryChips(
          categories: _categories,
          isLoading: _categoriesLoading,
          selectedSlug: _selectedCategorySlug,
          onSelected: _onCategorySelected,
        ),
        const Divider(height: 1),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading && _products.isEmpty) {
      return const ProductGridSkeleton();
    }

    if (_error != null && _products.isEmpty) {
      return ProductErrorView(message: _error!, onRetry: () => _loadPage(reset: true));
    }

    if (_products.isEmpty) {
      return ProductEmptyView(
        icon: _activeQuery.isNotEmpty ? Icons.search_off_rounded : Icons.inventory_2_outlined,
        message: _activeQuery.isNotEmpty
            ? 'No products match "$_activeQuery".'
            : 'No products found in this category.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPage(reset: true),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = _products[index];
                  return ProductCard(
                    product: product,
                    index: index,
                    isFavorite: _favoriteIds.contains(product.id),
                    onToggleFavorite: () => _toggleFavorite(product.id),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(productId: product.id),
                      ),
                    ),
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
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
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
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _loadPage(reset: false),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (!_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              'You\'ve reached the end • ${_products.length} products',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'What are you looking for?',
            prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                );
              },
            ),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small pill button that opens the sort/filter sheet — the storefront
/// reference's "Filter" affordance alongside the search field.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Filter',
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Popular / Latest / Best Sellers / Price" row — the active tab is
/// underlined in the accent color, the rest read as plain secondary text.
class _SortTabs extends StatelessWidget {
  const _SortTabs({required this.selected, required this.onSelected});

  final _ProductSort selected;
  final ValueChanged<_ProductSort> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final option in _ProductSort.values) ...[
            InkWell(
              onTap: () => onSelected(option),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: option == selected ? FontWeight.w700 : FontWeight.w500,
                            color: option == selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (option == _ProductSort.price) ...[
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down_rounded,
                              size: 16,
                              color: option == selected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: AppConstants.animFast,
                      height: 2,
                      width: option == selected ? 22 : 0,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
        ],
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
    if (isLoading) {
      final theme = Theme.of(context);
      return SizedBox(
        height: 66,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            return Container(
              width: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: AppConstants.animShimmer);
          },
        ),
      );
    }

    return SizedBox(
      height: 66,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final bool isAll = index == 0;
          final String slug = isAll ? _kAllCategorySlug : categories[index - 1].slug;
          final String label = isAll ? 'All' : categories[index - 1].name;
          final IconData icon = isAll ? CategoryIcons.all : CategoryIcons.iconFor(slug);
          final bool selected = slug == selectedSlug;

          return _CategoryTile(
            label: label,
            icon: icon,
            selected: selected,
            onTap: () => onSelected(slug),
          );
        },
      ),
    );
  }
}

/// A category's icon+label tile in the horizontal row above the grid —
/// the reference's compact "icon over label" treatment rather than a wide
/// pill chip, so more categories fit on screen at once.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppConstants.animFast,
                curve: Curves.easeOut,
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
