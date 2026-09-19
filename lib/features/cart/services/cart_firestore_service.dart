import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../../models/user_model.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

/// Persists a signed-in user's cart and completed orders to Firestore, under
/// `users/{uid}/cart/current` and `users/{uid}/orders/{orderId}` — see
/// firestore.rules, which only lets a user read/write their own subtree.
///
/// This runs alongside [CartApiService]/FakeStoreAPI rather than replacing
/// it: FakeStoreAPI's `/carts` call still proves checkout hit a real server
/// (that's its whole documented purpose), while this is what actually makes
/// the cart survive an app restart and gives orders somewhere permanent to
/// live.
class CartFirestoreService {
  CartFirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _cartDoc(String uid) =>
      _db.collection('users').doc(uid).collection('cart').doc('current');

  CollectionReference<Map<String, dynamic>> _ordersCollection(String uid) =>
      _db.collection('users').doc(uid).collection('orders');

  /// Denormalizes just enough of [user] onto the `users/{uid}` document
  /// itself (merge — never touches the `cart`/`orders` subcollections living
  /// under the same path). Firebase Auth stays the source of truth for the
  /// profile (see [AppUser]'s doc comment); this copy exists purely so the
  /// Firestore console shows a real name instead of a bare, field-less
  /// document with nothing to identify it but the uid.
  Future<void> syncUserProfile(AppUser user) async {
    try {
      await _db.collection('users').doc(user.uid).set({
        'name': user.displayName,
        'email': user.email,
        'photoUrl': user.photoUrl,
      }, SetOptions(merge: true));
    } catch (_) {
      // Best-effort, same as saveCart/loadCart above.
    }
  }

  /// Returns the persisted cart, or an empty list if the user has never had
  /// one (or it couldn't be reached — a fresh sign-in shouldn't hard-fail
  /// just because the cart failed to load).
  Future<List<CartItem>> loadCart(String uid) async {
    try {
      final snapshot = await _cartDoc(uid).get();
      final rawItems = snapshot.data()?['items'];
      if (rawItems is! List) return const [];
      return rawItems
          .whereType<Map>()
          .map((m) => CartItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Write-through save, called after every local cart mutation. Failures
  /// are swallowed on purpose — the cart still works locally for this
  /// session even if the write couldn't reach Firestore right now.
  Future<void> saveCart(String uid, List<CartItem> items) async {
    try {
      await _cartDoc(uid).set({
        'items': items.map((i) => i.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Best-effort — see doc comment above.
    }
  }

  /// Records a completed order under the user's own `orders` subcollection.
  /// Uses an auto-generated document id rather than FakeStoreAPI's receipt
  /// `order.id` — FakeStoreAPI is a mock backend that hands back the same
  /// id (e.g. `11`) for every checkout, and firestore.rules deliberately
  /// makes `orders` create-only (an order should never be silently
  /// overwritten), so reusing that id would make every checkout after the
  /// first fail with permission-denied. `order.id` is still stored as a
  /// field, purely for reference.
  ///
  /// [items] are the actual lines that were purchased, written out as their
  /// product id/title/thumbnail/price/quantity — not just [order]'s
  /// aggregate counts — so opening an order in the Firestore console shows
  /// what was bought, not only how many.
  ///
  /// Updating the cart itself (removing whatever was just bought) is the
  /// caller's job — see [saveCart] — since a partial checkout may leave
  /// unselected items behind.
  Future<void> recordOrder(String uid, Order order, List<CartItem> items) async {
    await _ordersCollection(uid).add({
      'receiptId': order.id,
      'totalProducts': order.totalProducts,
      'totalQuantity': order.totalQuantity,
      'paymentMethod': order.paymentMethod.name,
      'items': items
          .map((i) => {
                'productId': i.product.id,
                'title': i.product.title,
                'thumbnail': i.product.thumbnail,
                'price': i.product.price,
                'quantity': i.quantity,
              })
          .toList(),
      'pricing': {
        'subtotal': order.pricing.subtotal,
        'discount': order.pricing.discount,
        'shipping': order.pricing.shipping,
        'tax': order.pricing.tax,
        'total': order.pricing.total,
      },
      'placedAt': FieldValue.serverTimestamp(),
    });
  }
}
