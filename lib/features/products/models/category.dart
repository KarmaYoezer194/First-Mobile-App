/// A product category as returned by `GET /products/categories`.
///
/// DummyJSON has shipped two shapes for this endpoint over time: a plain
/// list of slug strings, and a list of `{slug, name, url}` objects. Both are
/// handled so the app keeps working regardless of which one the API is
/// currently serving.
class Category {
  final String slug;
  final String name;

  const Category({required this.slug, required this.name});

  factory Category.fromJson(dynamic json) {
    if (json is String) {
      return Category(slug: json, name: _labelFromSlug(json));
    }
    if (json is Map<String, dynamic>) {
      final slug = (json['slug'] as String?)?.trim();
      final name = (json['name'] as String?)?.trim();
      final effectiveSlug = (slug != null && slug.isNotEmpty) ? slug : 'unknown';
      return Category(
        slug: effectiveSlug,
        name: (name != null && name.isNotEmpty) ? name : _labelFromSlug(effectiveSlug),
      );
    }
    return const Category(slug: 'unknown', name: 'Unknown');
  }

  static String _labelFromSlug(String slug) {
    return slug
        .split('-')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
