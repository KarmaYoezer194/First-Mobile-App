/// The payment options offered at checkout. This is a demo app with no real
/// payment processor behind it — selecting Card never sends card details
/// anywhere (DummyJSON's cart API only ever receives a user id and product
/// list); it's UI-only, same as the rest of this checkout flow.
enum PaymentMethod {
  card,
  paypal,
  cashOnDelivery;

  String get label => switch (this) {
        PaymentMethod.card => 'Credit / Debit Card',
        PaymentMethod.paypal => 'PayPal',
        PaymentMethod.cashOnDelivery => 'Cash on Delivery',
      };

  String get description => switch (this) {
        PaymentMethod.card => 'Visa, Mastercard, or any major card',
        PaymentMethod.paypal => 'Pay via your PayPal balance',
        PaymentMethod.cashOnDelivery => 'Pay in cash when your order arrives',
      };
}
