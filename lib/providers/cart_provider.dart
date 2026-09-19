import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/cart/models/cart_item.dart';
import '../features/cart/models/order.dart';
import '../features/cart/models/payment_method.dart';
import '../features/cart/models/pricing_summary.dart';
import '../features/cart/services/cart_api_service.dart';
import '../features/cart/services/cart_firestore_service.dart';
import '../features/products/models/product.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

final cartApiServiceProvider = Provider<CartApiService>((ref) {
  final service = CartApiService();
  ref.onDispose(service.dispose);
  return service;
});

final cartFirestoreServiceProvider = Provider<CartFirestoreService>((ref) {
  return CartFirestoreService();
});

/// Demo user id sent to FakeStoreAPI's cart API. This app's own sign-in
/// ([authNotifierProvider]) is a separate Firebase-style system with no
/// numeric id FakeStoreAPI understands, so cart/order calls use a fixed
/// FakeStoreAPI test user instead of the real logged-in account.
const int kCartApiUserId = 1;

/// Cart contents, which of them are checked for checkout, plus in-flight
/// checkout status. [selectedIds] is Lazada-style: every item ships
/// selected by default, but you can uncheck some and only buy the rest.
class CartState {
  final List<CartItem> items;
  final Set<int> selectedIds;
  final bool isPlacingOrder;
  final String? error;

  const CartState({
    this.items = const [],
    this.selectedIds = const {},
    this.isPlacingOrder = false,
    this.error,
  });

  bool get isEmpty => items.isEmpty;
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  List<CartItem> get selectedItems =>
      items.where((item) => selectedIds.contains(item.product.id)).toList();

  bool get allSelected => items.isNotEmpty && selectedIds.length == items.length;
  bool isSelected(int productId) => selectedIds.contains(productId);

  /// Every line in the cart, selected or not — shown as the running total
  /// on the cart screen itself.
  PricingSummary get pricing => PricingSummary.fromItems(items);

  /// Only the checked lines — what "Proceed to Checkout" actually charges.
  PricingSummary get selectedPricing => PricingSummary.fromItems(selectedItems);

  int quantityOf(int productId) {
    for (final item in items) {
      if (item.product.id == productId) return item.quantity;
    }
    return 0;
  }

  CartState copyWith({
    List<CartItem>? items,
    Set<int>? selectedIds,
    bool? isPlacingOrder,
    String? error,
    bool clearError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      selectedIds: selectedIds ?? this.selectedIds,
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Owns the cart: adding/removing/adjusting items and selection locally,
/// checking out against DummyJSON's cart API, and — for a signed-in user —
/// persisting the cart and finished orders to Firestore so they survive an
/// app restart. Browsing/cart stays usable while signed out (see the
/// router's comment on why `/products` and `/cart` never redirect to
/// `/login`); Firestore sync simply switches off until someone signs in.
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(this._api, this._firestore, this._ref) : super(const CartState()) {
    _authSubscription = _ref.listen<AppUser?>(
      authNotifierProvider,
      (previous, next) => _onAuthChanged(previous, next),
      fireImmediately: true,
    );
  }

  final CartApiService _api;
  final CartFirestoreService _firestore;
  final Ref _ref;
  late final ProviderSubscription<AppUser?> _authSubscription;

  Future<void> _onAuthChanged(AppUser? previous, AppUser? next) async {
    if (previous?.uid == next?.uid) return;

    if (next == null) {
      // Signed out: clear the on-screen cart. The signed-in user's copy is
      // untouched in Firestore for next time they log in.
      state = const CartState();
      return;
    }

    // Denormalize the name/email/photo onto users/{uid} itself, so the
    // Firestore console shows who this document belongs to instead of just
    // the bare uid — see syncUserProfile's doc comment.
    unawaited(_firestore.syncUserProfile(next));

    if (state.items.isNotEmpty) {
      // Already had items — added while browsing signed out, since /cart
      // never requires login. Keep them and push them to this account's
      // Firestore cart instead of overwriting with whatever (likely empty)
      // cart was persisted there before.
      if (state.selectedIds.length != state.items.length) {
        state = state.copyWith(selectedIds: state.items.map((i) => i.product.id).toSet());
      }
      _persist();
      return;
    }

    final items = await _firestore.loadCart(next.uid);
    state = CartState(items: items, selectedIds: items.map((i) => i.product.id).toSet());
  }

  void _persist() {
    final uid = _ref.read(authNotifierProvider)?.uid;
    if (uid == null) return;
    unawaited(_firestore.saveCart(uid, state.items));
  }

  void addProduct(Product product, {int quantity = 1}) {
    final items = [...state.items];
    final index = items.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      items.add(CartItem(product: product, quantity: quantity));
    } else {
      items[index] = items[index].copyWith(quantity: items[index].quantity + quantity);
    }
    // New (or re-added) items start checked, same as Lazada.
    final selected = {...state.selectedIds, product.id};
    state = state.copyWith(items: items, selectedIds: selected, clearError: true);
    _persist();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.product.id == productId) item.copyWith(quantity: quantity) else item,
      ],
      clearError: true,
    );
    _persist();
  }

  void removeProduct(int productId) {
    final selected = {...state.selectedIds}..remove(productId);
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
      selectedIds: selected,
      clearError: true,
    );
    _persist();
  }

  void toggleSelected(int productId) {
    final selected = {...state.selectedIds};
    if (!selected.remove(productId)) selected.add(productId);
    state = state.copyWith(selectedIds: selected);
  }

  /// "Select all" header checkbox — checks or unchecks every line at once.
  void selectAll(bool selectAll) {
    state = state.copyWith(
      selectedIds: selectAll ? state.items.map((i) => i.product.id).toSet() : <int>{},
    );
  }

  /// Checks or unchecks every item in [productIds] at once — the
  /// shop-level checkbox in a Lazada-style grouped cart, where "shop" is a
  /// stand-in for [Product.brand] since this catalog has no real seller
  /// concept of its own.
  void selectGroup(Iterable<int> productIds, bool selected) {
    final ids = {...state.selectedIds};
    if (selected) {
      ids.addAll(productIds);
    } else {
      ids.removeAll(productIds);
    }
    state = state.copyWith(selectedIds: ids);
  }

  void clear() {
    state = const CartState();
    _persist();
  }

  /// Submits only the **checked** items to FakeStoreAPI (proving the order
  /// actually hit a server) and combines its receipt with the real,
  /// locally-computed price breakdown (plus any [extraDiscount] from a
  /// voucher code) and the chosen [PaymentMethod] into a full [Order].
  /// Unchecked items are left in the cart — same partial checkout behavior
  /// Lazada's cart has. When signed in, the finished order is also
  /// recorded to Firestore and the trimmed-down cart is persisted there too.
  Future<Order> checkout({required PaymentMethod method, double extraDiscount = 0}) async {
    final selected = state.selectedItems;
    if (selected.isEmpty) {
      throw StateError('Select at least one item to check out.');
    }
    final pricing = state.selectedPricing.applyVoucher(extraDiscount);
    state = state.copyWith(isPlacingOrder: true, clearError: true);
    try {
      final receipt = await _api.placeOrder(
        userId: kCartApiUserId,
        items: selected,
      );
      final order = Order(
        id: receipt.id,
        totalProducts: receipt.totalProducts,
        totalQuantity: receipt.totalQuantity,
        pricing: pricing,
        paymentMethod: method,
      );

      final purchasedIds = selected.map((i) => i.product.id).toSet();
      final remainingItems =
          state.items.where((i) => !purchasedIds.contains(i.product.id)).toList();
      final remainingSelected = state.selectedIds.difference(purchasedIds);

      final uid = _ref.read(authNotifierProvider)?.uid;
      if (uid != null) {
        await _firestore.recordOrder(uid, order, selected);
        await _firestore.saveCart(uid, remainingItems);
      }

      state = CartState(items: remainingItems, selectedIds: remainingSelected);
      return order;
    } catch (e) {
      state = state.copyWith(isPlacingOrder: false, error: e.toString());
      rethrow;
    }
  }

  /// A direct, cart-bypassing purchase — Lazada/Shopee's "Buy Now" — for
  /// exactly [quantity] of [product] and nothing else, regardless of what's
  /// sitting in the cart or checked there. Doesn't touch cart state at all:
  /// nothing is added, nothing is removed, nothing's selection changes.
  Future<Order> buyNow({
    required Product product,
    required int quantity,
    required PaymentMethod method,
    double extraDiscount = 0,
  }) async {
    final items = [CartItem(product: product, quantity: quantity)];
    final pricing = PricingSummary.fromItems(items).applyVoucher(extraDiscount);

    final receipt = await _api.placeOrder(userId: kCartApiUserId, items: items);
    final order = Order(
      id: receipt.id,
      totalProducts: receipt.totalProducts,
      totalQuantity: receipt.totalQuantity,
      pricing: pricing,
      paymentMethod: method,
    );

    final uid = _ref.read(authNotifierProvider)?.uid;
    if (uid != null) {
      await _firestore.recordOrder(uid, order, items);
    }
    return order;
  }

  @override
  void dispose() {
    _authSubscription.close();
    super.dispose();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(
    ref.watch(cartApiServiceProvider),
    ref.watch(cartFirestoreServiceProvider),
    ref,
  );
});
