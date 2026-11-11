import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/nav_provider.dart';
import '../models/order.dart';

/// Shown right after a successful checkout: the order id the cart API
/// echoed back, item counts, payment method and the price breakdown.
class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final Order order;

  void _continueShopping(BuildContext context, WidgetRef ref) {
    ref.read(bottomNavIndexProvider.notifier).state = 0;
    // This screen was reached via an imperative Navigator.pushReplacement
    // (from CheckoutScreen), not through GoRouter — so popping the real
    // Navigator back to its root is what dismisses it and lands on Home.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final pricing = order.pricing;
    final name = ref.watch(authNotifierProvider)?.displayName.trim() ?? '';
    final firstName = name.isEmpty ? '' : name.split(' ').first;

    Widget infoRow(String label, Widget value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(label,
                  style: AppFonts.sans(fontSize: 12, color: palette.inkMuted)),
              const Spacer(),
              value,
            ],
          ),
        );
    TextStyle strong([Color? color]) => AppFonts.sans(
        fontSize: 13, fontWeight: FontWeight.w700, color: color ?? palette.ink);
    String money(double v) => '\$${v.toStringAsFixed(2)}';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppConstants.panelPadding,
                    40, AppConstants.panelPadding, 16),
                child: Column(
                  children: [
                    const _SuccessBadge(),
                    const SizedBox(height: 26),
                    Semantics(
                      header: true,
                      child: Text('Order placed!',
                          style:
                              AppFonts.serif(fontSize: 30, color: palette.ink)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      firstName.isEmpty
                          ? 'Your order has been confirmed and is on its way.'
                          : 'Thanks, $firstName. Your order has been confirmed and is on its way.',
                      textAlign: TextAlign.center,
                      style: AppFonts.sans(
                          fontSize: 14, color: palette.inkMuted, height: 1.55),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusM),
                        border: Border.all(color: palette.border),
                      ),
                      child: Column(
                        children: [
                          infoRow('Order number',
                              Text('#${order.id}', style: strong())),
                          Divider(height: 1, color: palette.border),
                          infoRow(
                            'Items',
                            Text(
                              '${order.totalProducts} products · ${order.totalQuantity} units',
                              style: strong(),
                            ),
                          ),
                          Divider(height: 1, color: palette.border),
                          infoRow('Payment',
                              Text(order.paymentMethod.label, style: strong())),
                          Divider(height: 1, color: palette.border),
                          const SizedBox(height: 12),
                          for (final (label, value, color) in [
                            ('Subtotal', money(pricing.subtotal), null),
                            if (pricing.discount > 0)
                              (
                                'Discount',
                                '-${money(pricing.discount)}',
                                palette.success
                              ),
                            (
                              'Shipping',
                              pricing.shipping == 0
                                  ? 'Free'
                                  : money(pricing.shipping),
                              pricing.shipping == 0 ? palette.success : null,
                            ),
                            ('Tax', money(pricing.tax), null),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Text(label,
                                      style: AppFonts.sans(
                                          fontSize: 12,
                                          color: palette.inkMuted)),
                                  const Spacer(),
                                  Text(value,
                                      style: AppFonts.sans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: color ?? palette.ink)),
                                ],
                              ),
                            ),
                          const SizedBox(height: 4),
                          const DashedDivider(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text('Total paid',
                                  style: AppFonts.sans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: palette.ink)),
                              const Spacer(),
                              Text(money(pricing.total),
                                  style: AppFonts.serif(
                                      fontSize: 20, color: palette.ink)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Continue Shopping',
                      onPressed: () => _continueShopping(context, ref),
                    ),
                    const SizedBox(height: 10),
                    SecondaryButton(
                      label: 'View my orders',
                      // Order history isn't built yet — same message as
                      // Profile's "Order history" row.
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Order history is coming soon')),
                      ),
                    ),
                  ],
                ).entrance(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 110px soft circle holding a 74px ink circle with a gold check, plus two
/// small gold confetti dots.
class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ExcludeSemantics(
      child: SizedBox(
        width: 130,
        height: 130,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                  color: palette.surfaceSoft, shape: BoxShape.circle),
            ),
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                  color: AppColors.ink, shape: BoxShape.circle),
              child:
                  Icon(Icons.check_rounded, size: 34, color: palette.goldLight),
            ),
            Positioned(
              top: 8,
              right: 12,
              child: _dot(10, palette.gold),
            ),
            Positioned(
              bottom: 22,
              left: 6,
              child: _dot(6, palette.goldLight),
            ),
          ],
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: AppConstants.animEntrance,
          curve: Curves.easeOutBack,
        );
  }

  Widget _dot(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
