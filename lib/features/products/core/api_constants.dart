/// Central place for the FakeStoreAPI base URL and endpoint builders.
///
/// Keeping every URL builder here means no widget or service has to
/// hand-assemble a path string, and the base URL only needs to change
/// in one place if it ever moves.
///
/// Unlike DummyJSON (the previous backend), FakeStoreAPI has no
/// server-side pagination or search endpoint — `/products` always
/// returns the full catalog. [ProductApiService] fetches that list once
/// and does paging/search/sorting client-side, so callers still page
/// with a `skip`/`limit` the same way they did before.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://fakestoreapi.com';

  /// Page size used for the client-side pagination [ProductApiService] does.
  static const int pageLimit = 12;

  /// How long a single HTTP request is allowed to take before it is
  /// treated as a network failure.
  static const Duration requestTimeout = Duration(seconds: 15);

  static Uri products() => Uri.parse('$baseUrl/products');

  static Uri categories() => Uri.parse('$baseUrl/products/categories');

  static Uri productsByCategory(String slug) {
    return Uri.parse('$baseUrl/products/category/${Uri.encodeComponent(slug)}');
  }

  static Uri productById(int id) => Uri.parse('$baseUrl/products/$id');
}
