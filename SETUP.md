# Finishing the Firebase setup

Most of this was done for you already (see below). A few steps only the
project owner can do — they need clicks in the Firebase console, or a
security-rule change that's deliberately left for you to run rather than
have an AI open a public write hole on your behalf, even temporarily.

## Already done

- Firebase project **`premium-auth-app-97063`** created
  (console: https://console.firebase.google.com/project/premium-auth-app-97063)
- Firestore database created (region: `asia-southeast1`) with
  [firestore.rules](firestore.rules) deployed — public read, no client
  writes, everything scoped to `request.auth.uid` under `/users/{uid}`
- Android, iOS, Web and Windows apps registered; [lib/firebase_options.dart](lib/firebase_options.dart),
  [android/app/google-services.json](android/app/google-services.json) generated
- `main.dart` calls `Firebase.initializeApp()` on startup
- Auth (`AuthService`/`AuthNotifier`) now runs on real Firebase Auth
  (email/password) instead of the old in-memory fake
- Product catalog reads from Firestore (`FirestoreProductService`)
  instead of FakeStoreAPI
- Signed-in users' carts and orders persist to Firestore
  (`CartFirestoreService`), under `users/{uid}/cart` and `users/{uid}/orders`

## 1. Enable Email/Password sign-in

Firebase console → **Authentication → Sign-in method → Email/Password → Enable**.
(No CLI command does this — it's always a console click, for every FlutterFire project.)

https://console.firebase.google.com/project/premium-auth-app-97063/authentication/providers

Without this, login/register will fail with `operation-not-allowed`.

## 2. Seed the product catalog

The `products`/`categories` collections are empty until you seed them —
[tool/seed_firestore.js](tool/seed_firestore.js) copies FakeStoreAPI's
catalog in. It needs a brief, one-time write window:

```bash
# 1. Open firestore.rules and change BOTH of these:
#      allow write: if false;
#    under match /categories/{categoryId} and match /products/{productId} to:
#      allow write: if true;

# 2. Deploy that
firebase deploy --only firestore:rules

# 3. Seed
node tool/seed_firestore.js

# 4. Put firestore.rules back (both lines to `if false;`) and redeploy
firebase deploy --only firestore:rules
```

## 3. (Optional) Firebase Storage — for profile photos

Storage needs "Get Started" clicked once in the console, and on new
projects that now requires the **Blaze** (pay-as-you-go) plan — the free
Spark plan no longer includes new Storage buckets:

https://console.firebase.google.com/project/premium-auth-app-97063/storage

[storage.rules](storage.rules) is already written (per-user photo folder,
5MB cap) and will deploy automatically the next time you run
`firebase deploy --only storage` once Storage is enabled. The app doesn't
upload profile photos to it yet — the picker on the Profile page is
still local-preview-only.

## Testing the app

`cloud_firestore`/`firebase_auth` only ship official plugin
implementations for **Android, iOS, macOS and Web** — not Windows/Linux
desktop. Despite `firebase_options.dart` having a `windows` entry (needed
so the file compiles), `flutter run -d windows` will not be able to reach
Firebase. Use:

```bash
flutter run -d chrome --web-port 5000   # easiest on this machine
# or an Android emulator / physical device
```

A fixed port (`--web-port 5000`, or the "GoBuy (Chrome, port 5000)" run
configuration in VS Code) is optional; it just keeps the address the same
between runs.

## iOS

`flutterfire configure` couldn't write `ios/Runner/GoogleService-Info.plist`
from Windows (no Xcode project tooling here). Before building for iOS,
run `flutterfire configure` again from a Mac, or download
`GoogleService-Info.plist` for the iOS app from the console and drop it
into `ios/Runner/`.

## Social sign-in (Google / Apple / Facebook)

Wired up in code: `AuthService`/`AuthNotifier` have
`signInWithGoogle`/`signInWithApple`/`signInWithFacebook`, and Login/Register
both show a "Continue with ..." row (`SocialAuthButtons`) below the email
form. `AuthService.signOut()` also clears the native Google/Facebook
sessions so re-tapping shows the account picker again.

Each provider still needs its own one-time console setup before it will
actually work — none of this can be done from here:

- **Google** — Firebase console → **Authentication → Sign-in method →
  Google → Enable**
  (https://console.firebase.google.com/project/premium-auth-app-97063/authentication/providers).
  This is what actually generates the OAuth client; right now
  `android/app/google-services.json` has an empty `oauth_client` list,
  which is why Google sign-in will fail until this is enabled (then re-run
  `flutterfire configure`, or re-download `google-services.json`, to pick
  up the generated client). Android also needs your debug/release **SHA-1**
  fingerprint added under Project settings → Your apps → Android app.
  For iOS, open Firebase console → your iOS app → download
  `GoogleService-Info.plist`, and copy its `REVERSED_CLIENT_ID` into the
  placeholder `com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID` URL
  scheme in [ios/Runner/Info.plist](ios/Runner/Info.plist).
  For **web** (e.g. `flutter run -d chrome`), once Google sign-in is
  enabled the same provider page shows a "Web SDK configuration" client
  ID — paste that into the `google-signin-client_id` meta tag in
  [web/index.html](web/index.html) (already done). Skipping this is why
  "Continue with Google" fails immediately on web with a generic error.
  On web, Google / Apple / Facebook sign-in all go through Firebase's
  own popup (`signInWithPopup`), so they only need the provider enabled
  in Firebase Authentication and the page's domain listed under
  **Authentication → Settings → Authorized domains** (`localhost` is
  there by default). The port doesn't matter, so the old "Error 400:
  origin_mismatch" from the `google_sign_in` web popup no longer applies.

- **Apple** — Firebase console → **Authentication → Sign-in method →
  Apple → Enable**. Native iOS also needs the **Sign in with Apple**
  capability added in Xcode (Signing & Capabilities) — this project ships
  a starter [ios/Runner/Runner.entitlements](ios/Runner/Runner.entitlements)
  but it isn't linked into `project.pbxproj` yet since that requires Xcode
  on a Mac; adding the capability there will link it (or regenerate it).
  Requires a paid Apple Developer account.

- **Facebook** — create an app at https://developers.facebook.com, add the
  **Facebook Login** product, and copy its App ID/Client Token into the
  placeholders in three places: [android/app/src/main/res/values/strings.xml](android/app/src/main/res/values/strings.xml),
  [ios/Runner/Info.plist](ios/Runner/Info.plist) (`FacebookAppID`/
  `FacebookClientToken`, plus the `fbYOUR_FACEBOOK_APP_ID` URL scheme), and
  Firebase console → **Authentication → Sign-in method → Facebook →
  Enable** (paste the same App ID/secret there, and copy the OAuth
  redirect URI it shows back into the Facebook app's Login settings).

Until a given provider is enabled in the Firebase console, tapping its
button fails with a clear "Sign-in failed" error rather than crashing —
email/password sign-in is unaffected either way.
