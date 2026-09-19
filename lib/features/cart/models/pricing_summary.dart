import 'cart_item.dart';

/// The full price breakdown for a cart: what a real checkout would compute,
/// not just a sum of `price × quantity`.
///
///   subtotal   – every line at full price
///   discount   – what each product's own `discountPercentage` takes off
///   shipping   – a flat fee, waived above [freeShippingThreshold]
///   tax        – a flat sales-tax rate applied to the discounted subtotal
///   total      – what actually gets charged
class PricingSummary {
  final double subtotal;
  final double discount;
  final double shipping;
  final double tax;
  final double total;

  const PricingSummary({
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.tax,
    required this.total,
  });

  /// Spend at/above this (post-discount) and shipping is free.
  static const double freeShippingThreshold = 50.0;
  static const double flatShippingFee = 4.99;
  /// Flat sales-tax rate, applied to the discounted subtotal — the same
  /// order most real storefronts compute it in (discount first, tax after).
  static const double taxRate = 0.08;

  static const PricingSummary empty = PricingSummary(
    subtotal: 0,
    discount: 0,
    shipping: 0,
    tax: 0,
    total: 0,
  );

  factory PricingSummary.fromItems(List<CartItem> items) {
    if (items.isEmpty) return empty;

    final subtotal = items.fold(0.0, (sum, item) => sum + item.lineSubtotal);
    final discount = items.fold(0.0, (sum, item) => sum + item.lineDiscount);
    final discountedSubtotal = subtotal - discount;
    final shipping = discountedSubtotal >= freeShippingThreshold ? 0.0 : flatShippingFee;
    final tax = discountedSubtotal * taxRate;
    final total = discountedSubtotal + shipping + tax;

    return PricingSummary(
      subtotal: subtotal,
      discount: discount,
      shipping: shipping,
      tax: tax,
      total: total,
    );
  }

  /// How much more the user needs to spend (post-discount) to unlock free
  /// shipping, or 0 if they already qualify.
  double get remainingForFreeShipping {
    final discountedSubtotal = subtotal - discount;
    final remaining = freeShippingThreshold - discountedSubtotal;
    return remaining > 0 ? remaining : 0.0;
  }

  /// Applies a voucher/promo-code discount on top of everything else —
  /// [amount] comes straight off the total (capped so it can never go
  /// negative) and is folded into [discount] so it shows up in the "you
  /// saved" line too.
  PricingSummary applyVoucher(double amount) {
    final capped = amount.clamp(0, total);
    return PricingSummary(
      subtotal: subtotal,
      discount: discount + capped,
      shipping: shipping,
      tax: tax,
      total: total - capped,
    );
  }
}
