import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/firestore_product_service.dart';
import '../services/product_api_service.dart' show ApiException;
import '../widgets/product_state_views.dart';
import '../widgets/product_tile.dart';

/// A single-purpose, paginated product grid for a fixed sort order — e.g.
/// "Popular" (highest rated) or "New Arrivals" (most recently added). No
/// search field or category chips; those live in
/// [ProductBrowser] on the Search tab. This just answers "give me real API
/// products for this Home-screen category tile".
class SortedProductsScreen extends StatefulWidget {
  const SortedProductsScreen({
    super.key,
    required this.title,
    required this.sortBy,
    required this.order,
  });

  final String title;
  final String sortBy;
  final String order;

  @override
  State<SortedProductsScreen> createState() => _SortedProductsScreenState();
}

class _SortedProductsScreenState extends State<SortedProductsScreen> {
  final FirestoreProductService _service = FirestoreProductService();
  final ScrollController _scrollController = ScrollController();

  List<Product> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _paginationError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  Future<void> _loadPage({required bool reset}) async {
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
      final response = await _service.getProducts(
        skip: skip,
        sortBy: widget.sortBy,
        order: widget.order,
      );
      if (!mounted) return;
      setState(() {
        _products =
            reset ? response.products : [..._products, ...response.products];
        _hasMore = response.products.isNotEmpty && !response.isFullyLoaded;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _buildBody(),
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
      return const ProductEmptyView(message: 'No products found.');
    }

    return RefreshIndicator(
      onRefresh: () => _loadPage(reset: true),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverGrid(
              gridDelegate: ProductGridDelegate(
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'You\'ve reached the end • ${_products.length} products',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
