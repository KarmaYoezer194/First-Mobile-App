import 'payment_method.dart';
import 'pricing_summary.dart';

/// The raw confirmation FakeStoreAPI's `/carts` responds with. FakeStoreAPI
/// has no dedicated "place order" endpoint, so (as its docs suggest) that
/// call is used to simulate checkout — this is just enough of its response
/// (an id, and item counts derived from the `products` it echoes back) to
/// prove the order reached a server. It knows nothing about discounts,
/// shipping, tax or payment method, which is why [Order] below layers the
/// real, locally-computed breakdown on top.
class CheckoutReceipt {
  final int id;
  final int totalProducts;
  final int totalQuantity;

  const CheckoutReceipt({
    required this.id,
    required this.totalProducts,
    required this.totalQuantity,
  });

  factory CheckoutReceipt.fromJson(Map<String, dynamic> json) {
    // FakeStoreAPI doesn't send totalProducts/totalQuantity directly (unlike
    // DummyJSON, the previous backend) — derive them from the `products`
    // array it does echo back, falling back to a direct field if a future
    // response ever includes one.
    final rawProducts = json['products'];
    final products = rawProducts is List ? rawProducts.whereType<Map>() : const <Map>[];

    final derivedTotalProducts = products.length;
    final derivedTotalQuantity = products.fold<int>(
      0,
      (sum, p) => sum + _asInt(p['quantity']),
    );

    return CheckoutReceipt(
      id: _asInt(json['id']),
      totalProducts: json.containsKey('totalProducts')
          ? _asInt(json['totalProducts'])
          : derivedTotalProducts,
      totalQuantity: json.containsKey('totalQuantity')
          ? _asInt(json['totalQuantity'])
          : derivedTotalQuantity,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}

/// The confirmed order shown on the confirmation screen: DummyJSON's
/// receipt id and item counts, plus the real subtotal/discount/shipping/tax
/// breakdown and payment method the API never sees.
class Order {
  final int id;
  final int totalProducts;
  final int totalQuantity;
  final PricingSummary pricing;
  final PaymentMethod paymentMethod;

  const Order({
    required this.id,
    required this.totalProducts,
    required this.totalQuantity,
    required this.pricing,
    required this.paymentMethod,
  });
}
