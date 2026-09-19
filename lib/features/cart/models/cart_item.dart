import '../../products/models/product.dart';

/// A single line in the shopping cart: a product plus how many the user
/// wants of it. Kept as a thin wrapper so cart state never has to duplicate
/// (and risk drifting from) product fields like price or title.
class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  /// Undiscounted line total (unit price × quantity).
  double get lineSubtotal => product.price * quantity;

  /// Discount this line contributes, using the product's own
  /// `discountPercentage` from DummyJSON applied across the full quantity.
  double get lineDiscount => lineSubtotal * (product.discountPercentage / 100);

  /// What this line actually costs after its discount.
  double get lineTotal => lineSubtotal - lineDiscount;

  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }

  Map<String, dynamic> toJson() => {'product': product.toJson(), 'quantity': quantity};

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(Map<String, dynamic>.from(json['product'] as Map)),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
