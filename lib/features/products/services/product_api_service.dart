import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/api_constants.dart';
import '../models/category.dart';
import '../models/product.dart';

/// Thrown when the server was reached but responded with something the app
/// can't use: a non-2xx status code, or a body that isn't valid/expected
/// JSON.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Thrown when the request never got a response at all: no connection, DNS
/// failure, or the request timed out.
class NetworkException extends ApiException {
  NetworkException([
    super.message = 'No internet connection. Please check your network and try again.',
  ]);
}

/// The single place in the app that talks to the FakeStoreAPI.
///
/// UI screens call these methods and only ever deal with [Product],
/// [Category] and [ProductListResponse] objects (or a thrown
/// [ApiException]/[NetworkException]) — no widget performs an HTTP request
/// or parses JSON directly.
///
/// FakeStoreAPI has no server-side pagination or search, so `/products` and
/// `/products/category/:slug` are each fetched once, cached for the life of
/// this service instance, and then filtered/sorted/sliced client-side —
/// callers still page with `skip`/`limit` exactly as before.
class ProductApiService {
  ProductApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  List<Product>? _allProductsCache;
  final Map<String, List<Product>> _categoryCache = {};

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
  }) async {
    final all = await _fetchAllProducts();
    final q = query.trim().toLowerCase();
    final matches = q.isEmpty
        ? List<Product>.of(all)
        : all
            .where((p) =>
                p.title.toLowerCase().contains(q) || p.category.toLowerCase().contains(q))
            .toList();
    return _page(matches, skip: skip, limit: limit);
  }

  Future<List<Category>> getCategories() async {
    final json = await _getJson(ApiConstants.categories());
    if (json is! List) {
      throw ApiException('Received an unexpected response for categories.');
    }
    return json.map(Category.fromJson).toList();
  }

  Future<ProductListResponse> getProductsByCategory(
    String slug, {
    int limit = ApiConstants.pageLimit,
    int skip = 0,
  }) async {
    final products = await _fetchProductsByCategory(slug);
    return _page(products, skip: skip, limit: limit);
  }

  Future<Product> getProductById(int id) async {
    final json = await _getJsonObject(ApiConstants.productById(id));
    return Product.fromJson(json);
  }

  Future<List<Product>> _fetchAllProducts() async {
    final cached = _allProductsCache;
    if (cached != null) return cached;

    final products = await _fetchProductList(ApiConstants.products());
    _allProductsCache = products;
    return products;
  }

  Future<List<Product>> _fetchProductsByCategory(String slug) async {
    final cached = _categoryCache[slug];
    if (cached != null) return cached;

    final products = await _fetchProductList(ApiConstants.productsByCategory(slug));
    _categoryCache[slug] = products;
    return products;
  }

  Future<List<Product>> _fetchProductList(Uri uri) async {
    final json = await _getJson(uri);
    if (json is! List) {
      throw ApiException('Received an unexpected response for products.');
    }
    return json.whereType<Map<String, dynamic>>().map(Product.fromJson).toList();
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

  /// Slices [source] into one `skip`/`limit` page, reporting `source.length`
  /// as the total so [ProductListResponse.isFullyLoaded] still works the
  /// way callers already expect.
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

  /// Performs the GET request and returns the decoded JSON body, whatever
  /// its shape (object or array). Every failure mode — no connection, a
  /// timeout, a non-2xx status, or a malformed body — is normalized into an
  /// [ApiException] or [NetworkException] so callers only need one catch
  /// clause.
  Future<dynamic> _getJson(Uri uri) async {
    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(ApiConstants.requestTimeout);
    } on TimeoutException {
      throw NetworkException('The request timed out. Please try again.');
    } on SocketException {
      throw NetworkException();
    } on HttpException {
      throw NetworkException();
    } on http.ClientException {
      throw NetworkException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'The server returned an error (status ${response.statusCode}). Please try again.',
      );
    }

    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw ApiException('Received invalid data from the server.');
    }
  }

  /// Same as [_getJson] but asserts the decoded body is a JSON object, which
  /// is what `/products/:id` returns.
  Future<Map<String, dynamic>> _getJsonObject(Uri uri) async {
    final decoded = await _getJson(uri);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException('Received an unexpected response format from the server.');
  }

  void dispose() {
    _client.close();
  }
}
