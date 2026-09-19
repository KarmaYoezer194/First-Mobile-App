import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../repositories/places_repository.dart';
import '../services/places_api_service.dart';

final placesHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final placesApiServiceProvider = Provider<PlacesApiService>((ref) {
  return PlacesApiService(client: ref.watch(placesHttpClientProvider));
});

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  return PlacesRepositoryImpl(ref.watch(placesApiServiceProvider));
});
