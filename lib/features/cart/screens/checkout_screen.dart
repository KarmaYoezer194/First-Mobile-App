import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
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
  final _cardNameController = TextEditingController(text: kDebugMode ? 'Test User' : '');
  final _cardNumberController = TextEditingController(text: kDebugMode ? '4242 4242 4242 4242' : '');
  final _cardExpiryController = TextEditingController(text: kDebugMode ? '12/29' : '');
  final _cardCvvController = TextEditingController(text: kDebugMode ? '123' : '');
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
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spaceL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivery address', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: AppConstants.spaceL),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Recipient name'),
                ),
                const SizedBox(height: AppConstants.spaceM),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                const SizedBox(height: AppConstants.spaceM),
                TextFormField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: AppConstants.spaceL),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Save'),
                  ),
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
        MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: order)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final message = ref.read(cartProvider).error ?? 'Could not place your order.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final buyNowItem = widget.buyNowItem;
    final basePricing = buyNowItem != null
        ? PricingSummary.fromItems([buyNowItem])
        : ref.watch(cartProvider.select((s) => s.selectedPricing));
    final pricing = basePricing.applyVoucher(_voucherDiscount);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spaceM),
        children: [
          const SectionHeader(title: 'Delivery Address'),
          const SizedBox(height: AppConstants.spaceSM),
          _AddressCard(
            name: _addressName,
            phone: _addressPhone,
            address: _addressLine,
            onEdit: _editAddress,
          ),
          const SizedBox(height: AppConstants.spaceL),
          const SectionHeader(title: 'Bill Details'),
          const SizedBox(height: AppConstants.spaceSM),
          _PricingCard(pricing: pricing),
          const SizedBox(height: AppConstants.spaceL),
          const SectionHeader(title: 'Voucher'),
          const SizedBox(height: AppConstants.spaceSM),
          _VoucherRow(
            controller: _voucherController,
            appliedCode: _appliedVoucherCode,
            error: _voucherError,
            onApply: () => _applyVoucher(basePricing),
            onRemove: _removeVoucher,
          ),
          const SizedBox(height: AppConstants.spaceL),
          const SectionHeader(title: 'Payment Method'),
          const SizedBox(height: AppConstants.spaceSM),
          _PaymentMethodCard(
            selected: _method,
            onChanged: (method) => setState(() => _method = method),
          ),
          AnimatedSize(
            duration: AppConstants.animFast,
            child: _method == PaymentMethod.card
                ? Padding(
                    padding: const EdgeInsets.only(top: AppConstants.spaceL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Save Card'),
                        const SizedBox(height: AppConstants.spaceSM),
                        // A visual-only preview — this app has no real
                        // payment processor behind it (see PaymentMethod's
                        // doc comment), so nothing here is actually saved;
                        // it just mirrors the form below as you type, the
                        // way a real "Save Card" screen's card art would.
                        ListenableBuilder(
                          listenable: Listenable.merge(
                            [_cardNameController, _cardNumberController, _cardExpiryController],
                          ),
                          builder: (context, _) => _CardPreview(
                            name: _cardNameController.text,
                            number: _cardNumberController.text,
                            expiry: _cardExpiryController.text,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spaceM),
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
                : const SizedBox.shrink(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spaceM,
            AppConstants.spaceSM,
            AppConstants.spaceM,
            AppConstants.spaceM,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _placeOrder,
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      // FilledButton's default label color is already
                      // `onPrimary` — match it so the spinner doesn't wash
                      // out against the lighter coral this button becomes in
                      // dark mode.
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  // The total is already shown in Bill Details' "Total"
                  // row right above this button — matches the reference's
                  // plain "Order Now" rather than repeating the amount here.
                  : const Text('Order Now'),
            ),
          ),
        ),
      ),
    );
  }
}

/// The "Deliver to" card every Lazada checkout opens with — recipient,
/// phone, and address, with a tap-to-edit bottom sheet. Demo-only: nothing
/// here is persisted, same as the card-payment form below it.
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
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spaceM),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: AppConstants.spaceSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text(
                          phone,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(address, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Promo-code entry: an active voucher shows as a dismissible chip-like
/// row; otherwise a text field + Apply button. Try `LAZADA10` (10% off) or
/// `SAVE5` ($5 off) — this is a front-end simulation, not a real backend.
class _VoucherRow extends StatelessWidget {
  const _VoucherRow({
    required this.controller,
    required this.appliedCode,
    required this.error,
    required this.onApply,
    required this.onRemove,
  });

  final TextEditingController controller;
  final String? appliedCode;
  final String? error;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (appliedCode != null) {
      return Card(
        margin: EdgeInsets.zero,
        color: AppColors.success.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceM,
            vertical: AppConstants.spaceSM,
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer_rounded, color: AppColors.success),
              const SizedBox(width: AppConstants.spaceSM),
              Expanded(
                child: Text(
                  '"$appliedCode" applied',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.success),
                ),
              ),
              TextButton(onPressed: onRemove, child: const Text('Remove')),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter voucher code',
                  prefixIcon: const Icon(Icons.local_offer_outlined),
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => onApply(),
              ),
            ),
            const SizedBox(width: AppConstants.spaceSM),
            FilledButton.tonal(onPressed: onApply, child: const Text('Apply')),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(
            'Try LAZADA10 or SAVE5',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({required this.pricing});

  final PricingSummary pricing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final freeShippingGap = pricing.remainingForFreeShipping;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceM),
        child: Column(
          children: [
            _PriceRow(label: 'Subtotal', value: pricing.subtotal),
            if (pricing.discount > 0)
              _PriceRow(label: 'Discount', value: -pricing.discount, isDiscount: true),
            _PriceRow(
              label: 'Shipping',
              value: pricing.shipping,
              freeLabel: pricing.shipping == 0,
            ),
            _PriceRow(label: 'Tax (${(PricingSummary.taxRate * 100).toStringAsFixed(0)}%)', value: pricing.tax),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppConstants.spaceS),
              child: Divider(height: 1),
            ),
            _PriceRow(label: 'Total', value: pricing.total, emphasize: true),
            if (freeShippingGap > 0) ...[
              const SizedBox(height: AppConstants.spaceSM),
              Text(
                'Add \$${freeShippingGap.toStringAsFixed(2)} more to get free shipping',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.isDiscount = false,
    this.freeLabel = false,
  });

  final String label;
  final double value;
  final bool emphasize;
  final bool isDiscount;
  final bool freeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueText = freeLabel
        ? 'Free'
        : '${isDiscount ? '-' : ''}\$${value.abs().toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: emphasize
                ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                : theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            valueText,
            style: emphasize
                ? theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)
                : theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDiscount || freeLabel ? AppColors.success : null,
                  ),
          ),
        ],
      ),
    );
  }
}

/// A row of selectable icon+label tiles — one per [PaymentMethod] — styled
/// after the reference's "Others way to payment" row, rather than the
/// vertical radio list this replaced.
class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({required this.selected, required this.onChanged});

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < PaymentMethod.values.length; i++) ...[
          if (i > 0) const SizedBox(width: AppConstants.spaceSM),
          Expanded(
            child: _PaymentMethodTile(
              method: PaymentMethod.values[i],
              selected: selected == PaymentMethod.values[i],
              onTap: () => onChanged(PaymentMethod.values[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (method) {
        PaymentMethod.card => Icons.credit_card_rounded,
        PaymentMethod.paypal => Icons.account_balance_wallet_rounded,
        PaymentMethod.cashOnDelivery => Icons.payments_rounded,
      };

  // A distinct brand-ish color per method — the little colored icon is
  // what makes the row scannable at a glance, the way Lazada's list was.
  Color get _brandColor => switch (method) {
        PaymentMethod.card => Colors.blue.shade600,
        PaymentMethod.paypal => Colors.indigo.shade600,
        PaymentMethod.cashOnDelivery => Colors.green.shade600,
      };

  // A short label fits this tile's width better than method.label's full
  // "Credit / Debit Card" — the full text is still one tap away via the
  // long-press tooltip below.
  String get _shortLabel => switch (method) {
        PaymentMethod.card => 'Card',
        PaymentMethod.paypal => 'PayPal',
        PaymentMethod.cashOnDelivery => 'COD',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      color: selected ? theme.colorScheme.primary.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        onTap: onTap,
        child: Tooltip(
          message: method.description,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceM, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon, color: _brandColor, size: 24),
                const SizedBox(height: 6),
                Text(
                  _shortLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dark card-art preview, styled after the reference's "Save Card" screen —
/// mirrors [_CardForm]'s fields live as the user types. Purely decorative:
/// see [_CardForm]'s doc comment, nothing here is transmitted or stored
/// anywhere either.
class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.name, required this.number, required this.expiry});

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spaceL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B2B36), Color(0xFF17171F)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARD TYPE',
                    style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.6),
                  ),
                  SizedBox(height: 6),
                  Icon(Icons.memory_rounded, color: Colors.white70, size: 26),
                ],
              ),
              Spacer(),
              Text(
                'VISA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceL),
          Text(
            _displayNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppConstants.spaceM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CARD HOLDER',
                      style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name.trim().isEmpty ? 'YOUR NAME' : name.trim().toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'EXPIRES',
                    style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expiry.trim().isEmpty ? 'MM/YY' : expiry.trim(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name on Card',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter the name on the card' : null,
          ),
          const SizedBox(height: AppConstants.spaceSM),
          TextFormField(
            controller: numberController,
            keyboardType: TextInputType.number,
            maxLength: 19,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: 'Card Number',
              hintText: '1234 5678 9012 3456',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            validator: (v) {
              final digits = (v ?? '').replaceAll(' ', '');
              if (digits.length < 16) return 'Enter a valid 16-digit card number';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: expiryController,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ExpiryDateFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Expiry (MM/YY)',
                    hintText: 'MM/YY',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (v) {
                    final match = RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(v ?? '');
                    return match ? null : 'MM/YY';
                  },
                ),
              ),
              const SizedBox(width: AppConstants.spaceSM),
              Expanded(
                child: TextFormField(
                  controller: cvvController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
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
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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
