/// A single FakeStoreAPI product, converted from the raw API JSON.
///
/// Every field is read defensively: the API occasionally omits fields or
/// sends an unexpected type, and a bad product should never crash the list
/// or the detail screen. FakeStoreAPI also lacks a few fields the rest of
/// the app expects (`stock`, `brand`, `discountPercentage`, multiple
/// `images`) — those get sensible fallbacks below rather than left unset.
class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final double rating;
  final int stock;
  final String category;
  final String brand;
  final String thumbnail;
  final List<String> images;
  // Percentage off `price`, as DummyJSON computes it per product (e.g.
  // 12.96 for ~13% off). Drives the real discount math in the cart/checkout.
  final double discountPercentage;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rating,
    required this.stock,
    required this.category,
    required this.brand,
    required this.thumbnail,
    required this.images,
    this.discountPercentage = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // FakeStoreAPI ships a single `image` string, not a `thumbnail` +
    // `images[]` pair — reuse it for both so the detail screen's gallery
    // still has one image to show.
    final singleImage = json['image'];
    final imageList = _asStringList(json['images']);

    return Product(
      id: _asInt(json['id']),
      title: _asString(json['title'], fallback: 'Untitled product'),
      description: _asString(
        json['description'],
        fallback: 'No description available.',
      ),
      price: _asDouble(json['price']),
      // FakeStoreAPI nests rating as {"rate": 3.9, "count": 120}.
      rating: _asRating(json['rating']),
      // FakeStoreAPI has no stock field at all — every product is always
      // orderable there, so a missing key means "plenty in stock", not the
      // 0 a bare int parse would default to (which would show every
      // product as out of stock).
      stock: json.containsKey('stock') ? _asInt(json['stock']) : 999,
      category: _asString(json['category'], fallback: 'Uncategorized'),
      // FakeStoreAPI doesn't send a brand at all.
      brand: _asString(json['brand'], fallback: 'Unbranded'),
      thumbnail: _asString(json['thumbnail'] ?? singleImage, fallback: ''),
      images: imageList.isNotEmpty
          ? imageList
          : (singleImage is String && singleImage.isNotEmpty ? [singleImage] : const <String>[]),
      // FakeStoreAPI has no discount field, so checkout math just sees 0%.
      discountPercentage: _asDouble(json['discountPercentage']),
    );
  }

  static double _asRating(dynamic value) {
    if (value is Map) return _asDouble(value['rate']);
    return _asDouble(value);
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String _asString(dynamic value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) return value;
    return fallback;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  /// Round-trips through the same field names [Product.fromJson] reads, so
  /// this is what both the Firestore `products` collection documents look
  /// like and what a [CartItem] embeds when it's persisted to a user's
  /// Firestore cart/order.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'rating': rating,
      'stock': stock,
      'category': category,
      'brand': brand,
      'thumbnail': thumbnail,
      'images': images,
      'discountPercentage': discountPercentage,
    };
  }
}

/// Wraps one client-side page of products together with the metadata that
/// pagination decisions (has-more / stop) are based on.
///
/// FakeStoreAPI itself doesn't paginate, so [ProductApiService] builds
/// this directly from a slice of the full, locally-fetched product list
/// rather than parsing it out of a server response.
class ProductListResponse {
  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  const ProductListResponse({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  /// True once every product the API knows about has been loaded.
  bool get isFullyLoaded => skip + products.length >= total;
}
