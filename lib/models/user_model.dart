/// App-facing user profile, built from Firebase's [firebase_auth.User] plus
/// the extra fields (kept in sync with `displayName`) that only live on the
/// Firebase Auth account itself — there is no separate Firestore profile
/// document to fall out of sync with.
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  AppUser copyWith({String? email, String? displayName, String? photoUrl}) {
    return AppUser(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
