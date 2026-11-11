import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Product ids the user has hearted. In memory only: there's no wishlist
/// backend yet, so this resets when the app restarts. It lives in a
/// provider so the heart stays in sync across Home, Search and Product
/// detail.
class WishlistNotifier extends StateNotifier<Set<int>> {
  WishlistNotifier() : super(const {});

  void toggle(int productId) => state = state.contains(productId)
      ? ({...state}..remove(productId))
      : {...state, productId};
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, Set<int>>(
  (ref) => WishlistNotifier(),
);
