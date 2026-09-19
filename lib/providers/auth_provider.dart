import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Holds the current logged-in [AppUser], or null when signed out.
/// The router, splash screen, home, and profile pages all watch this.
class AuthNotifier extends StateNotifier<AppUser?> {
  AuthNotifier(this._authService) : super(_authService.currentUser) {
    // Keeps state in sync with Firebase's own session — not just changes
    // made through this notifier's methods, but also token expiry, the
    // account being deleted elsewhere, etc.
    _subscription = _authService.authStateChanges.listen((user) => state = user);
  }

  final AuthService _authService;
  late final StreamSubscription<AppUser?> _subscription;

  Future<void> signIn({required String email, required String password}) async {
    final user = await _authService.signInWithEmail(email: email, password: password);
    state = user;
  }

  Future<void> signInWithGoogle() async {
    state = await _authService.signInWithGoogle();
  }

  Future<void> signInWithApple() async {
    state = await _authService.signInWithApple();
  }

  Future<void> signInWithFacebook() async {
    state = await _authService.signInWithFacebook();
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final user = await _authService.registerWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
    state = user;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = null;
  }

  /// Returns an optional notice to surface instead of a generic "Profile
  /// updated" message — set when an email change needs confirming via a
  /// link before it actually takes effect. See [AuthService.updateProfile].
  Future<String?> updateProfile({String? displayName, String? email}) async {
    final result = await _authService.updateProfile(displayName: displayName, email: email);
    state = result.user;
    return result.notice;
  }

  Future<void> updatePhoto({required Uint8List bytes, required String fileExtension}) async {
    state = await _authService.updatePhoto(bytes: bytes, fileExtension: fileExtension);
  }

  Future<void> removePhoto() async {
    state = await _authService.removePhoto();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AppUser?>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

/// Convenience bool provider for widgets/router that just need to know
/// "is someone logged in".
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider) != null;
});
