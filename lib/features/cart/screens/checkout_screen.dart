import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../providers/cart_provider.dart';
import '../models/cart_item.dart';
import '../models/payment_method.dart';
import '../models/pricing_summary.dart';
import 'order_confirmation_screen.dart';

/// Order summary (real subtotal/discount/shipping/tax breakdown), a
/// delivery-address card, a voucher/promo-code field, and payment method
/// selection — the pieces of a Lazada-style checkout. "Place Order" here
/// is what actually submits the order to DummyJSON and produces the
/// confirmed [Order].
///
/// Normally reads the cart's checked items. Pass [buyNowItem] instead for
/// a "Buy Now" purchase — see [ProductDetailScreen]'s split button — which
/// checks out just that one item without touching the cart at all.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key}) : buyNowItem = null;

  const CheckoutScreen.buyNow({super.key, required CartItem this.buyNowItem});

  final CartItem? buyNowItem;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _cardFormKey = GlobalKey<FormState>();
  // Pre-filled with a fake test card in debug builds only, so you don't
  // have to retype it on every hot restart. Stripped from release builds.
  // Card details are never transmitted (see class doc above).
  final _cardNameController =
      TextEditingController(text: kDebugMode ? 'Test User' : '');
  final _cardNumberController =
      TextEditingController(text: kDebugMode ? '4242 4242 4242 4242' : '');
  final _cardExpiryController =
      TextEditingController(text: kDebugMode ? '12/29' : '');
  final _cardCvvController =
      TextEditingController(text: kDebugMode ? '123' : '');
  final _voucherController = TextEditingController();

  // Demo delivery address — not persisted anywhere, same fidelity as the
  // card-detail form above (edited via _editAddress, shown as a card).
  String _addressName = 'Test User';
  String _addressPhone = '+66 90 000 0000';
  String _addressLine = '123 Sukhumvit Road, Watthana, Bangkok 10110';

  PaymentMethod _method = PaymentMethod.card;
  bool _isSubmitting = false;
  double _voucherDiscount = 0;
  String? _appliedVoucherCode;
  String? _voucherError;

  @override
  void dispose() {
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  /// A tiny fixed set of demo codes — this is a front-end simulation same
  /// as the card form, not a real promotions backend.
  void _applyVoucher(PricingSummary basePricing) {
    final code = _voucherController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final double? discount = switch (code) {
      'LAZADA10' => basePricing.subtotal * 0.10,
      'SAVE5' => 5.0,
      _ => null,
    };

    setState(() {
      if (discount == null) {
        _voucherError = 'That code isn\'t valid or has expired.';
        _voucherDiscount = 0;
        _appliedVoucherCode = null;
      } else {
        _voucherError = null;
        _voucherDiscount = discount;
        _appliedVoucherCode = code;
      }
    });
  }

  void _removeVoucher() {
    setState(() {
      _voucherDiscount = 0;
      _appliedVoucherCode = null;
      _voucherController.clear();
    });
  }

  Future<void> _editAddress() async {
    final nameController = TextEditingController(text: _addressName);
    final phoneController = TextEditingController(text: _addressPhone);
    final addressController = TextEditingController(text: _addressLine);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 0,
                AppConstants.pagePadding, AppConstants.pagePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Delivery address',
                    style:
                        AppFonts.serif(fontSize: 22, color: ctx.palette.ink)),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Recipient name',
                  controller: nameController,
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Phone number',
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  icon: Icons.phone_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Address',
                  controller: addressController,
                  maxLines: 2,
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'Save',
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == true && mounted) {
      setState(() {
        _addressName = nameController.text.trim();
        _addressPhone = phoneController.text.trim();
        _addressLine = addressController.text.trim();
      });
    }
  }

  Future<void> _placeOrder() async {
    // Card details never leave this screen — DummyJSON's cart API only ever
    // receives a user id and product list — so this validation is purely
    // to make the demo feel real, not to protect real payment data.
    if (_method == PaymentMethod.card &&
        !(_cardFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final buyNowItem = widget.buyNowItem;
      final order = buyNowItem != null
          ? await ref.read(cartProvider.notifier).buyNow(
                product: buyNowItem.product,
                quantity: buyNowItem.quantity,
                method: _method,
                extraDiscount: _voucherDiscount,
              )
          : await ref.read(cartProvider.notifier).checkout(
                method: _method,
                extraDiscount: _voucherDiscount,
              );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => OrderConfirmationScreen(order: order)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final message =
          ref.read(cartProvider).error ?? 'Could not place your order.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final buyNowItem = widget.buyNowItem;
    final items = buyNowItem != null
        ? [buyNowItem]
        : ref.watch(cartProvider.select((s) => s.selectedItems));
    final basePricing = buyNowItem != null
        ? PricingSummary.fromItems([buyNowItem])
        : ref.watch(cartProvider.select((s) => s.selectedPricing));
    final pricing = basePricing.applyVoucher(_voucherDiscount);
    final voucherAmount = pricing.discount - basePricing.discount;
    final itemCount = items.fold<int>(0, (sum, i) => sum + i.quantity);

    Widget section(String label, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [SectionLabel(label), const SizedBox(height: 10), child],
          ),
        );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Back button + centred title.
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: SizedBox(
                height: AppConstants.minTapTarget,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CircleIconButton(
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    Semantics(
                      header: true,
                      child: Text('Checkout',
                          style: AppFonts.sans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: palette.ink)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppConstants.pagePadding, 14, AppConstants.pagePadding, 24),
                children: [
                  section(
                    'Delivery address',
                    _AddressCard(
                      name: _addressName,
                      phone: _addressPhone,
                      address: _addressLine,
                      onEdit: _editAddress,
                    ),
                  ),
                  section(
                    'Voucher',
                    _VoucherSection(
                      controller: _voucherController,
                      appliedCode: _appliedVoucherCode,
                      appliedAmount: voucherAmount,
                      error: _voucherError,
                      onApply: () => _applyVoucher(basePricing),
                      onRemove: _removeVoucher,
                    ),
                  ),
                  section(
                    'Payment method',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListenableBuilder(
                          listenable: _cardNumberController,
                          builder: (context, _) => _PaymentMethods(
                            selected: _method,
                            cardNumber: _cardNumberController.text,
                            onChanged: (method) =>
                                setState(() => _method = method),
                          ),
                        ),
                        AnimatedSize(
                          duration: AppConstants.animToggle,
                          curve: AppConstants.animCurve,
                          child: _method == PaymentMethod.card
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // A visual-only preview — this app has
                                      // no real payment processor behind it
                                      // (see PaymentMethod's doc comment), so
                                      // nothing here is saved; it mirrors the
                                      // form below as you type.
                                      ListenableBuilder(
                                        listenable: Listenable.merge([
                                          _cardNameController,
                                          _cardNumberController,
                                          _cardExpiryController,
                                        ]),
                                        builder: (context, _) => _CardPreview(
                                          name: _cardNameController.text,
                                          number: _cardNumberController.text,
                                          expiry: _cardExpiryController.text,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      _CardForm(
                                        formKey: _cardFormKey,
                                        nameController: _cardNameController,
                                        numberController: _cardNumberController,
                                        expiryController: _cardExpiryController,
                                        cvvController: _cardCvvController,
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                      ],
                    ),
                  ),
                  section(
                    'Order summary',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SummaryCard(
                          lines: [
                            SummaryLine(
                                'Subtotal ($itemCount ${itemCount == 1 ? 'item' : 'items'})',
                                _money(basePricing.subtotal)),
                            if (basePricing.discount > 0)
                              SummaryLine('Discount',
                                  '-${_money(basePricing.discount)}',
                                  valueColor: palette.success),
                            if (_appliedVoucherCode != null)
                              SummaryLine('Voucher $_appliedVoucherCode',
                                  '-${_money(voucherAmount)}',
                                  highlight: true),
                            SummaryLine(
                              'Shipping',
                              pricing.shipping == 0
                                  ? 'Free'
                                  : _money(pricing.shipping),
                              valueColor: pricing.shipping == 0
                                  ? palette.success
                                  : null,
                            ),
                            SummaryLine(
                              'Tax (${(PricingSummary.taxRate * 100).toStringAsFixed(0)}%)',
                              _money(pricing.tax),
                            ),
                          ],
                          totalValue: _money(pricing.total),
                        ),
                        if (pricing.remainingForFreeShipping > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Add ${_money(pricing.remainingForFreeShipping)} more to get free shipping',
                            textAlign: TextAlign.center,
                            style: AppFonts.sans(
                                fontSize: 11.5, color: palette.hint),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border(top: BorderSide(color: palette.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppConstants.pagePadding, 14, AppConstants.pagePadding, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  label: 'Place Order · ${_money(pricing.total)}',
                  loading: _isSubmitting,
                  onPressed: _placeOrder,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 13, color: palette.hint),
                    const SizedBox(width: 5),
                    Text(
                      // Honest wording: checkout is a demo and no payment
                      // is taken (see PaymentMethod's doc comment).
                      'Demo checkout · no real payment is taken',
                      style: AppFonts.sans(fontSize: 11, color: palette.hint),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

/// Recipient, address and phone, with a gold "Change" link that opens the
/// edit sheet. Demo-only: nothing here is persisted.
class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.name,
    required this.phone,
    required this.address,
    required this.onEdit,
  });

  final String name;
  final String phone;
  final String address;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppConstants.radiusM);
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
          borderRadius: radius, side: BorderSide(color: palette.border)),
      child: InkWell(
        borderRadius: radius,
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: palette.surfaceSoft,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusIconWell),
                ),
                child: Icon(Icons.location_on_outlined,
                    size: 17, color: palette.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppFonts.sans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: palette.ink)),
                    const SizedBox(height: 4),
                    Text(address,
                        style: AppFonts.sans(
                            fontSize: 12,
                            color: palette.inkMuted,
                            height: 1.45)),
                    const SizedBox(height: 2),
                    Text(phone,
                        style: AppFonts.sans(
                            fontSize: 12, color: palette.inkMuted)),
                  ],
                ),
              ),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: palette.gold,
                  minimumSize: const Size(AppConstants.minTapTarget, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  textStyle:
                      AppFonts.sans(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                child: const Text('Change'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Voucher field + ink Apply button. Once applied, a dashed gold row shows
/// the code, what it took off, and a remove button. Try `LAZADA10` (10%
/// off) or `SAVE5` ($5 off) — a front-end simulation, not a real backend.
class _VoucherSection extends StatelessWidget {
  const _VoucherSection({
    required this.controller,
    required this.appliedCode,
    required this.appliedAmount,
    required this.error,
    required this.onApply,
    required this.onRemove,
  });

  final TextEditingController controller;
  final String? appliedCode;
  final double appliedAmount;
  final String? error;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                controller: controller,
                hint: 'Enter voucher code',
                icon: Icons.local_offer_outlined,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onApply(),
              ),
            ),
            const SizedBox(width: 10),
            Pressable(
              child: Material(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(AppConstants.radiusInput),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppConstants.radiusInput),
                  onTap: onApply,
                  child: SizedBox(
                    height: AppConstants.fieldHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Text('Apply',
                            style: AppFonts.sans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: scheme.onPrimary)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (error != null)
          Text(error!,
              style: AppFonts.sans(fontSize: 12, color: palette.danger))
        else if (appliedCode == null)
          Text('Try LAZADA10 or SAVE5',
              style: AppFonts.sans(fontSize: 11.5, color: palette.hint)),
        if (appliedCode != null)
          CustomPaint(
            painter: _DashedBorderPainter(
                color: palette.gold, radius: AppConstants.radiusInput),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              decoration: BoxDecoration(
                color: palette.gold.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppConstants.radiusInput),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: palette.gold,
                      borderRadius: BorderRadius.circular(AppConstants.radiusTag),
                    ),
                    child: Text(appliedCode!,
                        style: AppFonts.sans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            letterSpacing: 0.5)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${_money(appliedAmount)} off applied',
                        style: AppFonts.sans(
                            fontSize: 12, color: palette.inkMuted)),
                  ),
                  IconButton(
                    tooltip: 'Remove voucher',
                    iconSize: 18,
                    color: palette.hint,
                    onPressed: onRemove,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(0.5), Radius.circular(radius));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
        distance += 7;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// The app's payment options as radio rows. UI only, as before.
class _PaymentMethods extends StatelessWidget {
  const _PaymentMethods({
    required this.selected,
    required this.cardNumber,
    required this.onChanged,
  });

  final PaymentMethod selected;
  final String cardNumber;
  final ValueChanged<PaymentMethod> onChanged;

  IconData _icon(PaymentMethod method) => switch (method) {
        PaymentMethod.card => Icons.credit_card_rounded,
        PaymentMethod.paypal => Icons.account_balance_wallet_outlined,
        PaymentMethod.cashOnDelivery => Icons.payments_outlined,
      };

  String _subtitle(PaymentMethod method) {
    if (method == PaymentMethod.card) {
      final digits = cardNumber.replaceAll(' ', '');
      if (digits.length >= 4) {
        return 'Card •••• ${digits.substring(digits.length - 4)}';
      }
    }
    return method.description;
  }

  @override
  Widget build(BuildContext context) {
    return ListRowCard(children: [
      for (final method in PaymentMethod.values)
        Semantics(
          inMutuallyExclusiveGroup: true,
          checked: method == selected,
          child: ListRow(
            icon: _icon(method),
            title: method.label,
            subtitle: _subtitle(method),
            trailing: _RadioDot(selected: method == selected),
            onTap: () => onChanged(method),
          ),
        ),
    ]);
  }
}

/// Selected: 6px ink ring. Unselected: thin warm-grey ring.
class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedContainer(
      duration: AppConstants.animToggle,
      curve: AppConstants.animCurve,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.surface,
        border: Border.all(
          color: selected ? palette.ink : palette.borderStrong,
          width: selected ? 6 : 1.5,
        ),
      ),
    );
  }
}

/// Ink card art that mirrors [_CardForm] as the user types. Purely
/// decorative: nothing here is transmitted or stored.
class _CardPreview extends StatelessWidget {
  const _CardPreview(
      {required this.name, required this.number, required this.expiry});

  final String name;
  final String number;
  final String expiry;

  String get _displayNumber {
    final digits = number.replaceAll(' ', '').padRight(16, '•');
    final groups = [for (int i = 0; i < 16; i += 4) digits.substring(i, i + 4)];
    return groups.join('  ');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final label = AppFonts.sans(
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        color: palette.onHeroCard.withValues(alpha: 0.55),
        letterSpacing: 0.8);
    final value = AppFonts.sans(
        fontSize: 13, fontWeight: FontWeight.w600, color: palette.onHeroCard);

    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: palette.heroCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory_rounded, color: palette.goldLight, size: 26),
                const Spacer(),
                Text('CARD',
                    style:
                        AppFonts.serif(fontSize: 16, color: palette.goldLight)),
              ],
            ),
            const SizedBox(height: 22),
            Text(_displayNumber,
                style: AppFonts.sans(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: palette.onHeroCard,
                    letterSpacing: 1.2)),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CARD HOLDER', style: label),
                      const SizedBox(height: 4),
                      Text(
                        name.trim().isEmpty
                            ? 'YOUR NAME'
                            : name.trim().toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: value,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('EXPIRES', style: label),
                    const SizedBox(height: 4),
                    Text(expiry.trim().isEmpty ? 'MM/YY' : expiry.trim(),
                        style: value),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card-detail fields, shown only when [PaymentMethod.card] is selected.
/// Purely a front-end simulation: validated for shape, never transmitted.
class _CardForm extends StatelessWidget {
  const _CardForm({
    required this.formKey,
    required this.nameController,
    required this.numberController,
    required this.expiryController,
    required this.cvvController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController numberController;
  final TextEditingController expiryController;
  final TextEditingController cvvController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Name on card',
            controller: nameController,
            icon: Icons.person_outline_rounded,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Enter the name on the card'
                : null,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Card number',
            hint: '1234 5678 9012 3456',
            controller: numberController,
            keyboardType: TextInputType.number,
            icon: Icons.credit_card_rounded,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            validator: (v) {
              final digits = (v ?? '').replaceAll(' ', '');
              if (digits.length < 16) {
                return 'Enter a valid 16-digit card number';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Expiry (MM/YY)',
                  hint: 'MM/YY',
                  controller: expiryController,
                  keyboardType: TextInputType.number,
                  icon: Icons.calendar_today_outlined,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryDateFormatter(),
                  ],
                  validator: (v) {
                    final match =
                        RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(v ?? '');
                    return match ? null : 'MM/YY';
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'CVV',
                  controller: cvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  icon: Icons.lock_outline_rounded,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (v) =>
                      (v != null && v.length >= 3) ? null : 'Enter a valid CVV',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Inserts a space every 4 digits as the user types a card number.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Inserts a `/` after the 2nd digit as the user types an expiry date.
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
