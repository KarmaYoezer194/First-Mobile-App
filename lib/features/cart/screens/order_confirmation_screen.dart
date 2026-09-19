import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../models/order.dart';

/// Shown right after a successful checkout — mirrors a real
/// order-confirmation screen: the id DummyJSON's cart API echoed back, the
/// real price breakdown computed locally, and the payment method chosen at
/// checkout.
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pricing = order.pricing;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spaceL),
          children: [
            const SizedBox(height: AppConstants.spaceM),
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 56),
              ),
            ),
            const SizedBox(height: AppConstants.spaceL),
            Text(
              'Order Placed!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.spaceS),
            Text(
              'Your order has been confirmed and is on its way.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppConstants.spaceL),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spaceM),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Order ID', value: '#${order.id}'),
                    _SummaryRow(
                      label: 'Items',
                      value: '${order.totalProducts} products • ${order.totalQuantity} units',
                    ),
                    _SummaryRow(label: 'Payment', value: order.paymentMethod.label),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppConstants.spaceS),
                      child: Divider(height: 1),
                    ),
                    _SummaryRow(label: 'Subtotal', value: '\$${pricing.subtotal.toStringAsFixed(2)}'),
                    if (pricing.discount > 0)
                      _SummaryRow(
                        label: 'Discount',
                        value: '-\$${pricing.discount.toStringAsFixed(2)}',
                        color: AppColors.success,
                      ),
                    _SummaryRow(
                      label: 'Shipping',
                      value: pricing.shipping == 0
                          ? 'Free'
                          : '\$${pricing.shipping.toStringAsFixed(2)}',
                      color: pricing.shipping == 0 ? AppColors.success : null,
                    ),
                    _SummaryRow(label: 'Tax', value: '\$${pricing.tax.toStringAsFixed(2)}'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppConstants.spaceS),
                      child: Divider(height: 1),
                    ),
                    _SummaryRow(
                      label: 'Total Paid',
                      value: '\$${pricing.total.toStringAsFixed(2)}',
                      emphasize: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spaceXL),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                // This screen was reached via an imperative
                // Navigator.pushReplacement (from CheckoutScreen), not
                // through GoRouter — so `context.go(...)` can't pop it
                // (GoRouter only knows about its own declarative page
                // stack). Popping the real Navigator all the way to its
                // root screen is what actually dismisses it and lands back
                // on Home/Products.
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Back to Shopping'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.color,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: emphasize
                ? theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)
                : theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
