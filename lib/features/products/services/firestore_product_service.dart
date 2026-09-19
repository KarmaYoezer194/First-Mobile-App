import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/api_constants.dart';
import '../models/category.dart';
import '../models/product.dart';
import 'product_api_service.dart' show ApiException, NetworkException;

/// The Firestore-backed replacement for [ProductApiService].
///
/// Same public surface (`getProducts`, `searchProducts`, `getCategories`,
/// `getProductsByCategory`, `getProductById`, `dispose`) so every screen
/// that used to construct a `ProductApiService()` can construct this
/// instead without changing anything else. The `products` and `categories`
/// collections have no server-side pagination or search either (Firestore
/// full-text search would need a third-party extension), so — just like
/// the old FakeStoreAPI-backed service — the whole catalog is fetched once,
/// cached for the life of this instance, and filtered/sorted/sliced
/// client-side.
class FirestoreProductService {
  FirestoreProductService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  List<Product>? _allProductsCache;
  List<Category>? _categoriesCache;

  Future<ProductListResponse> getProducts({
    int limit = ApiConstants.pageLimit,
    int skip = 0,
    String? sortBy,
    String? order,
  }) async {
    final products = List<Product>.of(await _fetchAllProducts());
    _sort(products, sortBy: sortBy, order: order);
    return _page(products, skip: skip, limit: limit);
  }

  Future<ProductListResponse> searchProducts(
    String query, {
    int limit = ApiConstants.pageLimit,
    int skip = 0,
    String? sortBy,
    String? order,
  }) async {
    final all = await _fetchAllProducts();
    final q = query.trim().toLowerCase();
    final matches = q.isEmpty
        ? List<Product>.of(all)
        : all
            .where((p) =>
                p.title.toLowerCase().contains(q) || p.category.toLowerCase().contains(q))
            .toList();
    _sort(matches, sortBy: sortBy, order: order);
    return _page(matches, skip: skip, limit: limit);
  }

  Future<List<Category>> getCategories() async {
    final cached = _categoriesCache;
    if (cached != null) return cached;

    final snapshot = await _guard(() => _db.collection('categories').get());
    final categories = snapshot.docs.map((d) => Category.fromJson(d.data())).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    _categoriesCache = categories;
    return categories;
  }

  Future<ProductListResponse> getProductsByCategory(
    String slug, {
    int limit = ApiConstants.pageLimit,
    int skip = 0,
    String? sortBy,
    String? order,
  }) async {
    final all = await _fetchAllProducts();
    final products = all.where((p) => p.category == slug).toList();
    _sort(products, sortBy: sortBy, order: order);
    return _page(products, skip: skip, limit: limit);
  }

  Future<Product> getProductById(int id) async {
    for (final product in _allProductsCache ?? const <Product>[]) {
      if (product.id == id) return product;
    }

    final doc = await _guard(() => _db.collection('products').doc('$id').get());
    if (!doc.exists) {
      throw ApiException('Product $id was not found.');
    }
    return Product.fromJson(doc.data()!);
  }

  Future<List<Product>> _fetchAllProducts() async {
    final cached = _allProductsCache;
    if (cached != null) return cached;

    final snapshot = await _guard(() => _db.collection('products').get());
    final products = snapshot.docs.map((d) => Product.fromJson(d.data())).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    _allProductsCache = products;
    return products;
  }

  void _sort(List<Product> products, {String? sortBy, String? order}) {
    if (sortBy == null) return;

    final int Function(Product, Product) compare = switch (sortBy) {
      'rating' => (a, b) => a.rating.compareTo(b.rating),
      'price' => (a, b) => a.price.compareTo(b.price),
      'title' => (a, b) => a.title.compareTo(b.title),
      _ => (a, b) => a.id.compareTo(b.id),
    };
    products.sort(order == 'desc' ? (a, b) => compare(b, a) : compare);
  }

  ProductListResponse _page(List<Product> source, {required int skip, required int limit}) {
    final start = skip.clamp(0, source.length);
    final end = (start + limit).clamp(start, source.length);
    return ProductListResponse(
      products: source.sublist(start, end),
      total: source.length,
      skip: start,
      limit: limit,
    );
  }

  /// Runs a Firestore call and normalizes every failure mode — no
  /// connection, a timeout, or a permissions/config problem — into the same
  /// [ApiException]/[NetworkException] pair the old HTTP service threw, so
  /// callers only need one catch clause regardless of the backend.
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        throw NetworkException();
      }
      throw ApiException(e.message ?? 'Could not reach the product catalog.');
    }
  }

  void dispose() {}
}
