import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/cart_provider.dart';
import 'cart_icon_anchor.dart';

/// Shopping-cart icon with a live item-count badge that bumps whenever the
/// count changes. Also registers its on-screen position with
/// [CartIconAnchor] so `flyToCart` (see fly_to_cart.dart) knows where to
/// land its animation — drop this into any AppBar's `actions` (or a FAB)
/// to give a product-browsing screen both quick cart access and a valid
/// fly-to-cart target.
class CartBadge extends ConsumerStatefulWidget {
  const CartBadge({super.key});

  @override
  ConsumerState<CartBadge> createState() => _CartBadgeState();
}

class _CartBadgeState extends ConsumerState<CartBadge>
    with SingleTickerProviderStateMixin {
  final GlobalKey _anchorKey = GlobalKey();

  late final AnimationController _bumpController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _bump = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 60),
  ]).animate(CurvedAnimation(parent: _bumpController, curve: Curves.easeOut));

  int? _lastCount;

  @override
  void initState() {
    super.initState();
    CartIconAnchor.register(_anchorKey);
  }

  @override
  void dispose() {
    CartIconAnchor.unregister(_anchorKey);
    _bumpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(cartProvider.select((s) => s.totalQuantity));

    // Bump on every count change (add or remove) — starting an
    // AnimationController mid-build isn't safe, so this is scheduled for
    // right after the frame that shows the new count instead.
    if (_lastCount != null && count != _lastCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _bumpController.forward(from: 0);
      });
    }
    _lastCount = count;

    return IconButton(
      key: _anchorKey,
      tooltip: 'Cart',
      onPressed: () => context.push('/cart'),
      icon: ScaleTransition(
        scale: _bump,
        child: Badge(
          label: Text('$count'),
          isLabelVisible: count > 0,
          child: const Icon(Icons.shopping_cart_outlined),
        ),
      ),
    );
  }
}
