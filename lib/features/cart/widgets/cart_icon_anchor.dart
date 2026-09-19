import 'package:flutter/widgets.dart';

/// Tracks where the currently-visible cart icon sits on screen, so
/// [flyToCart] (see fly_to_cart.dart) knows where to land its animation.
///
/// Every [CartBadge] registers its own [GlobalKey] here on mount and
/// unregisters on dispose — last-registered wins, which in practice means
/// "whichever screen's cart icon was built most recently", i.e. the one
/// currently on top of the navigation stack. A screen with no [CartBadge]
/// at all just falls back to whatever [currentCenter] returns for the
/// screen below it (or null, if none has ever mounted).
class CartIconAnchor {
  CartIconAnchor._();

  static final List<GlobalKey> _stack = [];

  static void register(GlobalKey key) {
    _stack
      ..remove(key)
      ..add(key);
  }

  static void unregister(GlobalKey key) => _stack.remove(key);

  /// The global-coordinate center of the topmost still-attached registered
  /// cart icon, or null if none is currently on screen.
  static Offset? currentCenter() {
    for (final key in _stack.reversed) {
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject is RenderBox && renderObject.attached) {
        return renderObject.localToGlobal(renderObject.size.center(Offset.zero));
      }
    }
    return null;
  }
}
