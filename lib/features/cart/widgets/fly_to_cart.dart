import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'cart_icon_anchor.dart';

/// Plays a small copy of [imageUrl] lobbing in an arc from [start] to
/// wherever the on-screen cart icon currently is (see [CartIconAnchor]) —
/// the flying "add to cart" flourish familiar from Lazada/Shopee-style
/// shopping apps.
///
/// This is purely a visual flourish laid on top of the real overlay — it
/// doesn't touch cart state itself. Call it alongside (never instead of)
/// the actual `ref.read(cartProvider.notifier).addProduct(...)` call.
void flyToCart(BuildContext context, {required Offset start, required String imageUrl}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  // No cart icon on screen right now (e.g. the Search tab, which embeds the
  // product grid without its own AppBar) — lob toward the top-right corner
  // instead of not animating at all.
  final end = CartIconAnchor.currentCenter() ??
      Offset(MediaQuery.sizeOf(context).width - 32, MediaQuery.paddingOf(context).top + 32);

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _FlyingItem(
      start: start,
      end: end,
      imageUrl: imageUrl,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _FlyingItem extends StatefulWidget {
  const _FlyingItem({
    required this.start,
    required this.end,
    required this.imageUrl,
    required this.onDone,
  });

  final Offset start;
  final Offset end;
  final String imageUrl;
  final VoidCallback onDone;

  @override
  State<_FlyingItem> createState() => _FlyingItemState();
}

class _FlyingItemState extends State<_FlyingItem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  late final Animation<double> _t =
      CurvedAnimation(parent: _controller, curve: Curves.easeInCubic);

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 44;
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final t = _t.value;
        final dx = ui.lerpDouble(widget.start.dx, widget.end.dx, t)!;
        final straightDy = ui.lerpDouble(widget.start.dy, widget.end.dy, t)!;
        // A parabolic lift layered over the straight-line fall, peaking at
        // the midpoint — the "lob" arc, not a flat slide.
        final lift = -90 * 4 * t * (1 - t);
        final scale = ui.lerpDouble(1.0, 0.2, t)!;
        final opacity = t < 0.8 ? 1.0 : (1 - (t - 0.8) / 0.2).clamp(0.0, 1.0);

        return Positioned(
          left: dx - size / 2,
          top: straightDy + lift - size / 2,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(scale: scale, child: child),
            ),
          ),
        );
      },
      child: _Thumbnail(imageUrl: widget.imageUrl, size: size),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isEmpty
          ? const ColoredBox(
              color: Colors.white,
              child: Icon(Icons.shopping_bag_outlined, size: 20),
            )
          : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
    );
  }
}
