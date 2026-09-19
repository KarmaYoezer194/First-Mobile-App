import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../products/core/api_constants.dart';
import '../../products/services/product_api_service.dart'
    show ApiException, NetworkException;
import '../core/cart_api_constants.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

/// Talks to FakeStoreAPI's cart endpoints so checkout is a real network
/// call, not just a local state mutation. Errors are normalized the same
/// way [ProductApiService] does, so the UI only needs one catch clause.
class CartApiService {
  CartApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Posts the cart's contents to FakeStoreAPI's `/carts` and returns the
  /// server-issued [CheckoutReceipt] (id, item counts) it responds with.
  /// This only proves the order reached a server — the real price
  /// breakdown and payment method are computed and attached locally, in
  /// [CartNotifier.checkout].
  Future<CheckoutReceipt> placeOrder({
    required int userId,
    required List<CartItem> items,
  }) async {
    late final http.Response response;
    try {
      response = await _client
          .post(
            CartApiConstants.addCart(),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'date': DateTime.now().toIso8601String(),
              // FakeStoreAPI names the field "productId", not "id".
              'products': [
                for (final item in items)
                  {'productId': item.product.id, 'quantity': item.quantity},
              ],
            }),
          )
          .timeout(ApiConstants.requestTimeout);
    } on TimeoutException {
      throw NetworkException('The request timed out. Please try again.');
    } on SocketException {
      throw NetworkException();
    } on HttpException {
      throw NetworkException();
    } on http.ClientException {
      throw NetworkException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Could not place your order (status ${response.statusCode}). Please try again.',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw ApiException('Received an unexpected response while placing the order.');
      }
      return CheckoutReceipt.fromJson(decoded);
    } on FormatException {
      throw ApiException('Received invalid data from the server.');
    }
  }

  void dispose() => _client.close();
}
