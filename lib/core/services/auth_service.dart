import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart' as storage;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../models/user_model.dart';

/// Talks to real Firebase Authentication. Every method signature here
/// matches what the UI already expects (see the old local `AuthService`
/// this replaced), so [AuthNotifier] and the screens above it didn't need
/// to change shape — only what happens inside each method did.
class AuthService {
  AuthService({fb.FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  /// Fires immediately with the current user (or null), then again on every
  /// sign-in/sign-out — including ones that happen outside this app's own
  /// UI, e.g. the session expiring or being revoked elsewhere.
  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().map(_toAppUser);

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _toAppUser(credential.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(displayName.trim());
      await credential.user?.reload();
      return _toAppUser(_auth.currentUser)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  /// Opens the native Google account picker and exchanges the result for a
  /// Firebase session. Creates the Firebase account automatically the first
  /// time a given Google account signs in — same as email sign-up, there's
  /// no separate "register with Google" step.
  Future<AppUser> signInWithGoogle() async {
    if (kIsWeb) {
      return _signInWithWebPopup(fb.GoogleAuthProvider()..addScope('email'));
    }
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User dismissed the account picker — not a real failure.
        throw AuthException('Sign-in cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return _toAppUser(userCredential.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  /// Apple only ever sends the account's name on the *first* authorization
  /// a user grants this app — Firebase has nowhere to store that, so it's
  /// copied onto the Firebase profile's `displayName` right here, once,
  /// while it's still available.
  Future<AppUser> signInWithApple() async {
    if (kIsWeb) {
      return _signInWithWebPopup(fb.OAuthProvider('apple.com')
        ..addScope('email')
        ..addScope('name'));
    }
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final oauthCredential = fb.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      final fullName = [appleCredential.givenName, appleCredential.familyName]
          .where((part) => part != null && part.trim().isNotEmpty)
          .join(' ')
          .trim();
      if (user != null && fullName.isNotEmpty && (user.displayName?.trim().isEmpty ?? true)) {
        await user.updateDisplayName(fullName);
        await user.reload();
      }

      return _toAppUser(_auth.currentUser)!;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthException('Sign-in cancelled.');
      }
      throw AuthException('Apple sign-in failed. Please try again.');
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<AppUser> signInWithFacebook() async {
    if (kIsWeb) {
      return _signInWithWebPopup(fb.FacebookAuthProvider()..addScope('email'));
    }
    try {
      final result = await FacebookAuth.instance.login(permissions: const ['email', 'public_profile']);

      if (result.status == LoginStatus.cancelled) {
        throw AuthException('Sign-in cancelled.');
      }
      final accessToken = result.accessToken;
      if (result.status != LoginStatus.success || accessToken == null) {
        throw AuthException(result.message ?? 'Facebook sign-in failed. Please try again.');
      }

      final credential = fb.FacebookAuthProvider.credential(accessToken.tokenString);
      final userCredential = await _auth.signInWithCredential(credential);
      return _toAppUser(userCredential.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  /// Web sign-in for Google / Apple / Facebook through Firebase's own popup.
  ///
  /// The native plugins' web flows check the page's exact origin (including
  /// its port) against the OAuth client, which fails with
  /// "origin_mismatch" on `flutter run -d chrome`. Firebase's popup signs in
  /// through `<project>.firebaseapp.com`, which is already registered, and
  /// only needs the page's domain (localhost is allowed by default) to be in
  /// Firebase Authentication's authorized domains.
  Future<AppUser> _signInWithWebPopup(fb.AuthProvider provider) async {
    try {
      final userCredential = await _auth.signInWithPopup(provider);
      return _toAppUser(userCredential.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  /// A cryptographically random string, hashed with SHA-256 before being
  /// sent to Apple as the `nonce` — Firebase compares the raw value against
  /// that hash to make sure the ID token it receives back was minted for
  /// *this* sign-in attempt and not replayed from another one.
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  /// Updates [displayName] immediately. Firebase no longer allows changing
  /// the sign-in email in place — [email] instead triggers a verification
  /// link sent to the new address, and the account keeps its old (still
  /// valid) email until that link is clicked. When that happens, the
  /// returned [ProfileUpdateResult.notice] explains it so the UI can show
  /// something more accurate than "Profile updated".
  Future<ProfileUpdateResult> updateProfile({String? displayName, String? email}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('You need to be signed in to update your profile.');
    }

    try {
      if (displayName != null && displayName.trim() != user.displayName) {
        await user.updateDisplayName(displayName.trim());
      }

      String? notice;
      final trimmedEmail = email?.trim();
      if (trimmedEmail != null && trimmedEmail != user.email) {
        await user.verifyBeforeUpdateEmail(trimmedEmail);
        notice = 'Name saved. We sent a confirmation link to $trimmedEmail — '
            'your sign-in email changes once you click it.';
      }

      await user.reload();
      return ProfileUpdateResult(_toAppUser(_auth.currentUser)!, notice: notice);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  /// Uploads [bytes] to Firebase Storage under this user's own UID (so
  /// re-uploading overwrites the previous photo rather than accumulating
  /// orphaned files) and points the Auth profile's `photoURL` at it. The
  /// refreshed [AppUser] carries the new URL back to every screen watching
  /// [AuthNotifier], including Home's avatar.
  Future<AppUser> updatePhoto({required Uint8List bytes, required String fileExtension}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('You need to be signed in to update your profile.');
    }

    try {
      final ref = storage.FirebaseStorage.instance.ref('profile_photos/${user.uid}.$fileExtension');
      await ref.putData(bytes, storage.SettableMetadata(contentType: _contentTypeFor(fileExtension)));
      final url = await ref.getDownloadURL();

      await user.updatePhotoURL(url);
      await user.reload();
      return _toAppUser(_auth.currentUser)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } on storage.FirebaseException {
      throw AuthException('Could not upload your photo. Please try again.');
    }
  }

  /// Clears `photoURL` so the UI falls back to the initials avatar again.
  /// Leaves the file in Storage rather than deleting it — cheap to keep,
  /// and re-adding the same photo later needs no re-upload.
  Future<AppUser> removePhoto() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('You need to be signed in to update your profile.');
    }

    try {
      await user.updatePhotoURL(null);
      await user.reload();
      return _toAppUser(_auth.currentUser)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  String _contentTypeFor(String fileExtension) {
    switch (fileExtension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // On web, sign-in goes through Firebase's popup, so there's no native
    // Google/Facebook session to clear (and FB.logout() can wait forever
    // when the Facebook SDK isn't set up).
    if (kIsWeb) return;
    // Best-effort: also drop the native Google/Facebook sessions so the
    // next "Continue with ..." tap shows the account picker again instead
    // of silently reusing whichever account was cached. Neither of these
    // failing (e.g. that provider was never used this session) should stop
    // sign-out from completing.
    await Future.wait([
      _googleSignIn.signOut().catchError((_) => null),
      FacebookAuth.instance.logOut().catchError((_) {}),
    ]);
  }

  AppUser? _toAppUser(fb.User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? 'User'),
      photoUrl: user.photoURL,
    );
  }

  String _messageFor(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'requires-recent-login':
        return 'Please sign in again before changing your email.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Sign-in cancelled.';
      case 'popup-blocked':
        return 'Your browser blocked the sign-in window. Allow pop-ups for this site and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method isn\'t turned on yet.';
      case 'unauthorized-domain':
        return 'This web address isn\'t allowed to sign in yet.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but a different sign-in method.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}

/// Wraps the refreshed [AppUser] together with an optional human-readable
/// [notice] — set when part of the update (currently: an email change)
/// didn't take effect immediately and needs the user to do something else
/// first (click a confirmation link).
class ProfileUpdateResult {
  final AppUser user;
  final String? notice;

  const ProfileUpdateResult(this.user, {this.notice});
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
}
