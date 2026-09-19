# Premium Auth & Profile Module

A complete Authentication + User Profile module built with Flutter, Firebase, Riverpod, and GoRouter.

## What's included

**Auth screens:** Splash, Welcome, Sign In, Sign Up, Forgot Password, Verify Email
**Profile screens:** Profile, Edit Profile

**Stack:** Firebase Auth + Firestore + Storage, Riverpod (StateNotifier), GoRouter (with auth-aware redirects), Material 3, Google Fonts, flutter_animate, responsive_framework.

## 1. Install dependencies

```bash
flutter pub get
```

## 2. Connect your Firebase project (required)

`lib/firebase_options.dart` in this project is a **placeholder** — the app will not run against real data until you generate your own:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Follow the prompts to select/create a Firebase project and platforms (Android, iOS, web). This overwrites `firebase_options.dart` with real values and downloads `google-services.json` / `GoogleService-Info.plist` automatically.

In the Firebase Console, enable:
- **Authentication** → Sign-in method → Email/Password, Google, Apple, Facebook, GitHub (as needed)
- **Firestore Database** → start in production mode, then add rules (see below)
- **Storage** → default bucket is fine

### Suggested Firestore rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## 3. Social sign-in setup (per provider)

- **Google** — works out of the box on Android once SHA-1 is added in Firebase Console; iOS needs the reversed client ID added to `Info.plist` (flutterfire configure handles most of this).
- **Apple** — requires enabling "Sign in with Apple" capability in Xcode and configuring your App ID in the Apple Developer portal.
- **Facebook** — add your Facebook App ID/Client Token to `android/app/src/main/res/values/strings.xml` and `Info.plist` per the `flutter_facebook_auth` package docs.
- **GitHub** — enabled directly in Firebase Console → Authentication → Sign-in method → GitHub (uses Firebase's OAuth provider flow, no extra SDK config needed).

## 4. Run

```bash
flutter run
```

## Folder structure

```
lib/
  core/
    constants/        # app-wide constants
    theme/             # colors, ThemeData, radii, shadows
    utils/              # validators.dart
  models/               # user_model.dart
  services/             # auth_service, firestore_service, storage_service
  providers/            # Riverpod providers/controllers
  routes/                # app_router.dart (GoRouter)
  screens/
    splash/
    welcome/
    auth/
      signin/
      signup/
      forgot_password/
      verify_email/
    profile/
    edit_profile/
  widgets/                # reusable UI components
  main.dart
  firebase_options.dart  # <-- replace via flutterfire configure
```

## Notes

- The **profile completion percentage**, **account stats**, and **membership status** are all driven from the Firestore user document (`lib/models/user_model.dart`) — extend that model if you add more fields.
- Theme toggle (dark/light) is in-memory via Riverpod; wire it to `shared_preferences` if you want it to persist across restarts.
- Email verification polls every 4 seconds and auto-advances once the user clicks the link in their inbox — no manual "I've verified" button needed.
