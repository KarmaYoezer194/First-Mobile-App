# GoBuy

A Flutter shopping app built on Firebase. Users sign in, browse a product
catalog, add items to a cart, check out, and pick a nearby pickup point on a map.

**Stack:** Flutter (Material 3), Firebase Auth + Firestore (+ Storage, optional),
Riverpod, GoRouter, flutter_map + OpenStreetMap, Google Fonts, flutter_animate.

## User flow

1. **Splash** — checks onboarding and login state, then routes on.
2. **Onboarding** — 4 intro slides, shown only on first launch (saved with `shared_preferences`).
3. **Login / Register / Forgot password** — email + password, plus Google, Apple and Facebook sign-in.
4. **Main app** — bottom navigation with 5 tabs: Home, Search, Alerts, Profile, Settings.
5. **Shopping** — Products → Product detail → Cart → Checkout → Order confirmation.

Logged-out users are redirected to Login, and logged-in users are kept out of
the auth screens. `/products` and `/cart` are reachable without logging in.

## Features

### Home
Promo banner, category shortcuts (open the product list pre-filtered),
"Best Selling" and "Recommended" sections.

### Products
- Search, category filter, sort (Popular, Latest, Best Sellers, Price)
- Infinite scroll, with loading / empty / error (retry) states
- Product detail: images, price and discount, stock status, size and quantity
  pickers, description, category and brand chips, **Add to Cart**, **Buy Now**,
  and **Find pickup near me**
- Catalog is read from Firestore (`products`, `categories`), seeded from FakeStoreAPI

### Cart & checkout
- Fly-to-cart animation, "added to cart" sheet, cart badge
- Change quantities, remove items, select all
- Pricing: per-product discount, 8% tax, $4.99 shipping (free from $50)
- Checkout: editable delivery address, voucher codes (`LAZADA10` = 10% off,
  `SAVE5` = $5 off), payment method (Card, PayPal, Cash on Delivery)
- Signed-in users' cart and orders are saved to Firestore under
  `users/{uid}/cart` and `users/{uid}/orders`
- Payment is UI only — no payment is processed

### Pickup location map
- OpenStreetMap map with GPS location and a re-center button
- Place search with autocomplete (Nominatim)
- Category chips that show nearby places within 5 km (Overpass)
- Tap a marker for details and pick it as the pickup point
- Uses free OSM services only, so no API key is needed

### Profile
Profile photo, edit name and email, account info, order / review / points
stats, activity shortcuts, and log out.

### Alerts
Notification list with "Mark all read" and an empty state.

### Settings
Dark mode, notifications, language, change password, biometric login,
active sessions, privacy, support and legal pages, log out.

## Not finished yet

- Notifications and active sessions use sample data.
- Biometric and notification toggles are UI only.
- The theme choice is not saved between restarts.
- Some profile stats are placeholders, and Order history, Saved items and
  My reviews show "coming soon".
- Profile photos are not uploaded to Firebase Storage yet (Storage needs the Blaze plan).
- Google, Apple and Facebook sign-in each need console setup before they work.

## Getting started

```bash
flutter pub get
flutter run -d chrome   # or an Android emulator / device
```

Firebase does not work on the Windows or Linux desktop builds, so use web,
Android, iOS or macOS.

The Firebase project is already connected (`lib/firebase_options.dart`). Before the
app fully works, follow [SETUP.md](SETUP.md) to:

1. Enable Email/Password sign-in in the Firebase console
2. Seed the product catalog with `node tool/seed_firestore.js`
3. (Optional) Enable Firebase Storage
4. Set up each social sign-in provider you want

Security rules are in [firestore.rules](firestore.rules) and [storage.rules](storage.rules).

## Folder structure

```
lib/
  core/
    constants/      # app and social-auth constants
    services/       # auth_service.dart (Firebase Auth + social sign-in)
    theme/          # colors and ThemeData
    widgets/        # app shell (bottom nav) and shared UI components
  features/
    splash/  onboarding/  auth/
    home/  search/  notifications/  profile/  settings/
    products/       # catalog, product detail, Firestore/API services
    cart/           # cart, checkout, order confirmation, Firestore sync
    pickup_location/ # OSM map, search, nearby places
  models/           # user_model.dart
  providers/        # Riverpod providers (auth, cart, theme, nav, onboarding)
  routes/           # app_router.dart (GoRouter)
  main.dart
  firebase_options.dart
tool/
  seed_firestore.js # copies the FakeStoreAPI catalog into Firestore
```
