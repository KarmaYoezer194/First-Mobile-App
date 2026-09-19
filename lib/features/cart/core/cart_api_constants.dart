import '../../products/core/api_constants.dart';

/// URL builders for FakeStoreAPI's cart endpoints. Shares [ApiConstants.baseUrl]
/// with the product API rather than redefining it, since both hit the same
/// host.
class CartApiConstants {
  CartApiConstants._();

  static Uri addCart() => Uri.parse('${ApiConstants.baseUrl}/carts');

  static Uri cartById(int id) => Uri.parse('${ApiConstants.baseUrl}/carts/$id');
}
