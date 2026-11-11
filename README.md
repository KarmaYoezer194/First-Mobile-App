# GoBuy

A Flutter shopping app built on Firebase. Users sign in, browse a product
catalog, add items to a cart, check out, and pick a nearby pickup point on a map.

**Stack:** Flutter (Material 3), Firebase Auth + Firestore (+ Storage, optional),
Riverpod, GoRouter, flutter_map + OpenStreetMap, Google Fonts (Lora + Inter),
flutter_animate, flutter_svg.

**Design:** "Warm Ivory" — ivory background, ink text and buttons, one gold
accent, serif (Lora) headlines. Light and dark themes. The reference
screenshots are in `gobuy_redesign/design_reference/`.

## User flow

1. **Splash** — checks onboarding and login state, then routes on.
2. **Onboarding** — 3 illustrated slides, shown only on first launch (saved
   with `shared_preferences`). "Get started" opens Register, "Sign in" opens Login.
3. **Login / Register / Forgot password** — email + password, plus Google,
   Apple and Facebook sign-in.
4. **Main app** — bottom navigation with 4 tabs: Home, Search, Cart, Profile.
   Alerts open from the bell on Home; Settings open from the gear on Profile.
5. **Shopping** — Product → Cart → Checkout → Order confirmation (or Buy Now
   straight to checkout).

Logged-out users are redirected to Login, and logged-in users are kept out of
the auth screens. `/products` and `/cart` are reachable without logging in.

## Features

### Home
Logo and alerts bell, search field (opens Search) with a camera button, hero
banner ("Shop Now" opens the product list), category circles (open Search on
that category), and a "Recommended" grid of top-rated products.

### Search and products
- Search, sort (Popular, Latest, Best Sellers, Price), category chips,
  product count and a "Pickup near me" shortcut
- Infinite scroll, with loading / empty / error (retry) states
- Product cards: wishlist heart, tag, rating, price, **Add to Cart** (with a
  fly-to-cart animation) and **Buy Now**
- Product detail: image gallery, category, stock, price and discount, rating,
  free-shipping note, sizes (clothing only), quantity, **Find pickup near me**,
  description, sticky Add to Cart / Buy Now bar
- Catalog is read from Firestore (`products`, `categories`), seeded from FakeStoreAPI

### Cart & checkout
- Cart tab with a live count badge; free-shipping banner; select all, item
  checkboxes, quantity stepper, remove / swipe to remove; price summary
- Pricing: per-product discount, 8% tax, $4.99 shipping (free from $50)
- Checkout: editable delivery address, voucher codes (`LAZADA10` = 10% off,
  `SAVE5` = $5 off), payment method (Card, PayPal, Cash on Delivery)
- Signed-in users' cart and orders are saved to Firestore under
  `users/{uid}/cart` and `users/{uid}/orders`
- Payment is UI only — no payment is processed

### Pickup location map
- OpenStreetMap map (warm-tinted tiles) with GPS location and a recenter button
- Place search with autocomplete (Nominatim)
- Place-type chips that show nearby places within 5 km (Overpass)
- Tap a marker to see the place (type, address, distance, opening status) and
  set it as the pickup point
- Uses free OSM services only, so no API key is needed

### Profile
Profile photo (add, change, remove), edit name and email, account info,
activity shortcuts, Settings and log out.

### Alerts
Alerts grouped by Today / Earlier, unread markers, mark read, mark all read,
swipe to dismiss, empty state.

### Settings
Dark mode, notifications, language, change password, biometric login,
active sessions, privacy, support and legal pages, log out.

## Not finished yet

- Alerts and active sessions use sample data.
- The wishlist (hearts) is kept in memory only and resets on restart.
- Biometric and notification toggles are UI only.
- The theme choice is not saved between restarts.
- Order history, Saved items, My reviews and "View my orders" show "coming soon".
- The camera button lets you pick a photo, but searching by photo isn't built.
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
assets/
  onboarding/       # splash and onboarding illustrations (SVG)
lib/
  core/
    constants/      # app constants: spacing, radii, motion tokens
    services/       # auth_service.dart (Firebase Auth + social sign-in)
    theme/          # color tokens (AppColors, AppPalette) and ThemeData
    widgets/        # app shell (bottom nav) and shared UI components
                    # (import core/widgets/widgets.dart)
  features/
    splash/  onboarding/  auth/
    home/  search/  notifications/  profile/  settings/
    products/       # catalog, product detail, product cards, Firestore/API services
    cart/           # cart, checkout, order confirmation, Firestore sync
    pickup_location/ # OSM map, search, nearby places
  models/           # user_model.dart
  providers/        # Riverpod providers (auth, cart, theme, nav, onboarding,
                    # wishlist, notifications)
  routes/           # app_router.dart (GoRouter)
  main.dart
  firebase_options.dart
tool/
  seed_firestore.js # copies the FakeStoreAPI catalog into Firestore
```
