# GoBuy — Warm Ivory UI Redesign (Claude Code prompt)

You are redesigning the **UI layer** of GoBuy, a Flutter (Material 3) e-commerce app using Riverpod, go_router, Google Fonts, flutter_animate, flutter_map (OpenStreetMap) and Firebase.

The target design is in `design_reference/` (18 PNG screenshots, 390×844 logical px). Match them closely: layout, spacing, colors, typography, component shapes. Illustrations for splash/onboarding are in `assets/onboarding/` as SVG.

---

## 0. Hard rules — read before touching anything

1. **Do NOT modify Firebase, auth, Firestore, Storage, repositories, services, or Riverpod providers' business logic.** Only widgets, theme, routing/shell, and assets. If a screen needs data, read it from the existing providers exactly as today.
2. **Do NOT remove any existing feature.** Every button, flow and screen that exists today must still exist and still work after the redesign.
3. **Do NOT invent backend features.** Where the mockups show sample content (addresses, payment options, variant names, alerts, ratings), render the app's **real data** from existing models. If the app has no data for an element, hide that element — don't hardcode fake data.
4. Work in small, reviewable steps (see §7). Run `flutter analyze` after each step; it must be clean.
5. Before starting, read `lib/` to map every existing screen, route, widget and provider. Write that map as a short checklist at the top of your first reply so I can confirm nothing is missed.

---

## 1. Design tokens

Replace the contents of `app_colors.dart` and `app_constants.dart` (keep file names and any public names other files import; add new names, deprecate old ones by pointing them to the new values).

### Colors
| Token | Hex | Use |
|---|---|---|
| `background` | `#F7F2EA` | Page background (warm ivory) |
| `surface` | `#FFFFFF` | Cards, inputs, bottom nav, sheets |
| `surfaceSoft` | `#F0E8DB` | Icon wells, camera button, quantity buttons, image placeholders |
| `tile` | `#EEE7DC` | Product image tile background |
| `border` | `#ECE4D8` | Hairline borders, dividers |
| `borderStrong` | `#DCCFBD` | Outline buttons, inactive switch track `#E2D8C9` |
| `ink` | `#2B2420` | Primary text, primary buttons, dark hero/profile cards, active nav |
| `inkMuted` | `#6B6054` | Secondary text |
| `hint` | `#A89C8C` | Placeholders, meta text, section labels |
| `navInactive` | `#B3A696` | Inactive nav icons/labels |
| `gold` | `#C8902E` | Accent: badges, active switch, ratings stars, "See more", progress ring, selected-state dots |
| `goldLight` | `#E2B566` | Gold text/icons on dark (`ink`) surfaces |
| `success` | `#5E7D5A` | "In stock", "Free" shipping |
| `danger` | `#A2483A` / bg `#F6E3DC` | Log out row only |
| Illustration only | terra `#C96F4A`, sage `#8A9E7E`, blush `#EFC9B4`, sand `#E6D7C1`, cream `#FFFDF8` | Onboarding art |
| Onboarding backgrounds | `#E9DCC8`, `#DCE2D2`, `#F2DCCB` | Slides 1, 2, 3 |

Rule: one accent (gold) per screen, used sparingly. No gradients on UI surfaces. No colored shadows.

### Typography (Google Fonts)
- **Display / serif:** `Lora` weight 700 (Georgia-like). Used for: logo "GoBuy", screen titles (Search 26, My Cart 26, Profile 26), auth headlines (30–32), onboarding titles (31, line-height 1.12), hero banner headline (23, weight 400), big prices/totals (22–26), profile stats numbers (22).
- **UI / sans:** `Inter`. Body 13–14, labels 12 w600, meta 10–11, buttons 14 w700 (11 w600 on product-card buttons), nav labels 10.
- Logo = "GoBuy" in Lora 700 + a gold "." (`gold`).

### Shape & spacing
- Page horizontal padding **20** (auth/onboarding text panels **24**).
- Radius: inputs **14**, list cards **16**, product card **22** with image tile **16**, hero/profile dark cards **20–22**, bottom sheets **24–28** top corners, buttons/chips/tags **pill (100)**, icon buttons **circle 40×40** (white, 1px `border`).
- Text fields: height **50**, white, 1px `border`, leading icon in `hint`, label above in 12 w600.
- Shadows: only product cards (`0 2 10 rgba(43,36,32,.04)`), floating map controls and the wishlist heart (`0 1 3 rgba(43,36,32,.14)`).

### Motion (flutter_animate, use the same values everywhere)
- Screen content entrance: fade 0→1 + slideY 0.04→0, **250ms**, `Curves.easeOutCubic`.
- Grids/lists: stagger **40ms** per item, max 8 items animated.
- Button press: scale to **0.97** on tap down, 120ms.
- Toggle/selection changes: 180ms.
- Page transitions: fade-through 220ms (pushed routes slide from right).
- Keep the existing fly-to-cart animation, restyled to the new colors.

---

## 2. Shared widgets (`lib/widgets/` or wherever shared widgets live today)

Build these once and use them everywhere — no one-off styling inside screens:

- `GoBuyLogo({double size})`
- `PrimaryButton` — full-width pill, `ink` bg, `background` text, 14 w700, vertical padding 15.
- `SecondaryButton` — pill, white bg, 1px `#E2D8C9`, ink text, optional leading icon.
- `AppTextField` — label above, icon, optional trailing (eye toggle / camera button).
- `CircleIconButton` — 40px white circle, 1px border, optional badge (gold dot or count).
- `SectionHeader(title, actionLabel?, onAction?)` — title 15 w700; action 12 w600 `gold`.
- `SectionLabel` — 12 w700 uppercase, letter-spacing .06em, `hint` (used in Checkout/Profile/Settings/Alerts).
- `CategoryCircle(icon, label)` — 58px white circle + 1px border, label 11 `inkMuted` under it.
- `AppChip(selected)` — pill; selected = `ink` bg/`background` text; unselected = white bg, 1px border, `inkMuted`.
- `SortTabs` — text tabs with a 2px `ink` underline on the active tab.
- **`ProductCard`** (see §4 Home) — used on Home and Search.
- `ListRowCard` — white card (radius 16, 1px border) containing rows: 34px `surfaceSoft` icon well (radius 10) + title 13 w600 + optional subtitle 11 `hint` + trailing chevron / switch.
- `GoldSwitch` — 44×26, track `#E2D8C9` off / `gold` on, white thumb.
- `QuantityStepper` — pill container, 24px white circular − / + buttons, value 13–14 w700.
- `SummaryCard` — subtotal / voucher / shipping / tax rows (13, `inkMuted`), dashed divider, Total row with serif 22 amount.
- `GoBuyBottomNav` — see §3.

---

## 3. Navigation restructure

Current bottom nav has 5 tabs: Home, Search, Alerts, Profile, Settings. Change to **4 tabs: Home, Search, Cart, Profile** using a go_router `StatefulShellRoute` (or the existing shell, if there is one):

- **Cart tab** is new as a tab (the cart screen already exists). Show a live item-count badge (gold circle, ink 9px w800 number) from the existing cart provider.
- **Alerts** moves to a bell `CircleIconButton` in the Home header (gold unread dot). It opens the existing notifications screen as a pushed route.
- **Settings** moves inside Profile: gear icon in the Profile header and a "Settings" row; opens the existing settings screen as a pushed route.
- Remove the floating cart FAB and the header cart icon on Home/Search (the Cart tab replaces them). Keep the cart icon on Product detail.
- Nav style: white bar, 1px top border, icons 20px, labels 10. Active = `ink` icon (stroke 2.2), bold label, 4px gold dot under the label. Inactive = `navInactive`.
- **Register the missing routes** `pickup_location_screen.dart` and `camera_screen.dart` in `app_router.dart`, and wire every entry point to them.
- Keep the existing redirect logic (onboarding first launch, `/products` and `/cart` reachable logged-out).

---

## 4. Screen-by-screen spec

Match each `design_reference/NN_*.png`. Text below lists structure and behavior; the PNG is the source of truth for look.

### 01 Splash
`background` page. `assets/onboarding/splash_art.svg` (arch with gold bag) centered; logo 48 below; tagline "Good finds. Better prices." 14 `inkMuted`; three small dots (ink / gold / sand) near the bottom. Keep current splash timing/logic.

### 02–04 Onboarding (3 slides, first launch only)
- Top 480px: illustration `onboarding_1/2/3.svg` (use `flutter_svg`). Overlaid top bar: slide 1 shows the logo; slides 2–3 show a back `CircleIconButton` (85% cream bg, no border). "Skip" pill (85% cream) top-right on slides 1–2 → Login.
- Bottom panel overlaps the art by 28px, `background` color, top radius 28, padding 28/24: "0N / 03" (11 w700 gold, letter-spacing .14em), serif title 31, body 14 `inkMuted`.
- Slides 1–2 bottom row: page dots (active = 22×6 ink pill, others 6×6 `#E2D8C9`) left; right a 58px ink circle with chevron inside a 76px **progress ring** (gold arc = 1/3, 2/3).
- Slide 3: `PrimaryButton` "Get started" → Register; below it "I already have an account **Sign in**" → Login.
- Copy: 1 "Good finds, better prices" / "Gadgets, fashion, jewelry and home — thousands of deals, refreshed every day." 2 "Snap it. Find it." / "See something you love? Take a photo and GoBuy shows you where to get it for less." 3 "Pick up near you" / "Choose a nearby mall, café or gas station on the map and collect your order on the way."
- Swipeable `PageView` as today. Note: the SVGs contain `<text>` elements (price tags, distance chip); if flutter_svg renders them poorly, convert those labels to Flutter `Text` overlays or outline them.

### 05 Login · 06 Register · 07 Forgot password
- Login: logo, serif "Welcome back" 32, "Sign in to continue to GoBuy", Email + Password (eye toggle) fields, right-aligned "Forgot password?" (gold 12 w600), `PrimaryButton` "Sign In", divider "or continue with", **three equal square-ish buttons** (white, radius 14, 1px border) with Google / Apple / Facebook logos only, footer "Don't have an account? **Sign up**" (underlined).
- Register: back button, serif "Create account", fields exactly as the current register form (same fields, same validation), "Create Account", same social row, footer link to Sign in.
- Forgot: back button, 64px `surfaceSoft` key icon tile, serif title, explainer, Email field, "Send reset link", bottom "‹ Back to sign in".
- Keep all existing auth logic, validation messages, loading and error states — restyle only (errors: 12px `danger` text under field, field border `danger`).

### 08 Home
Order top→bottom:
1. Header: logo (26) left; bell `CircleIconButton` with gold unread dot right → Alerts.
2. Search field: search icon, "What are you looking for?", trailing 36px `surfaceSoft` rounded-10 **camera button → camera screen**. Tapping/typing behaves as today.
3. Hero banner: `ink` card radius 20, faint large gold bag icon bottom-right (35% opacity), chip "⚡ Best Seller!" (gold 18% bg, `goldLight` text), serif headline "Discover the perfect shopping journey!" (23, `background`), cream pill "Shop Now". Keep existing hero content/carousel if it's data-driven.
4. "Categories" + 4 `CategoryCircle`s (the app's real categories: Electronics, Men's Fashion, Women's Fashion, Jewelry) → filtered Search.
5. `SectionHeader` "Recommended" / "See more" → Search.
6. 2-column grid of **ProductCard**, column gap 12, row gap 22:
   - White card radius 22, 1px `border`, soft shadow, padding 8 (bottom 10).
   - Image tile: square, radius 16, `tile` bg, image `BoxFit.cover`.
   - **Wishlist heart**: 28px white circle top-left of the image (filled gold when saved) — existing wishlist logic.
   - **Tag pill** top-right of the image, white, 10 w700: "New" on Home (existing badge logic); category name on Search.
   - Name: 14 w700, 1 line, ellipsis.
   - Row: gold star + rating + "(count)" 10.5 `hint` on the left (**only if the product model has rating data — otherwise omit**), price 15 w800 on the right.
   - Two pill buttons (gap 6): "Add to Cart" (`background` bg, 1px `borderStrong`) → existing add-to-cart action + fly-to-cart animation; "Buy Now" (`ink`) → existing buy-now flow.
   - Tap image or name → Product detail.
7. Keep infinite scroll / loading / empty states; style skeletons as `tile`-colored rounded blocks.

### 09 Search
1. Serif title "Search" 26.
2. Row: search field (with camera button → camera screen) + 50×50 `ink` rounded-14 **Filter** button (opens the existing filter sheet).
3. `SortTabs`: Popular · Latest · Best Sellers · Price ▾ (existing sort options).
4. Horizontal `AppChip`s with small icons: All + the real categories.
5. Row: "N products" (12 `hint`) left; right a white pill "**Pickup near me ›**" with a 22px ink circle holding a gold pin → **pickup location screen**. (This replaces the large "Choose Pickup Location" card at the top.)
6. ProductCard grid (tag = category).

### 10 Camera search
Full-screen camera preview (existing camera_screen logic). Top: close (✕) circle → back, title "Search by photo", flash toggle — both 40px circles at 55% ink. Center: four rounded white corner brackets as a scan frame, hint "Point at a product to search". Bottom gradient to 75% ink: gallery button (46px rounded-14 translucent) left, 74px white shutter ring center.

### 11 Pickup location
Full-screen flutter_map (keep OSM/Nominatim/Overpass logic). Map tiles get a warm look via a `ColorFiltered` (≈ saturation 0.5 + slight sepia); keep the required OSM attribution visible. Top: back `CircleIconButton` + search field ("Search for a pickup location") with light shadow; below it horizontal place-type chips (Gas Station, Mall, Bakery, Salon… — the app's existing types; selected = ink). Markers: places = 28px white circles with an ink icon; selected = ink teardrop pin with gold icon; user location = gold dot with white border + gold halo. My-location button: 46px white circle bottom-right above the sheet. Bottom sheet (white, top radius 24, grab handle): selected place icon well, name 14 w700, "type · address · distance" 12 `inkMuted`, `PrimaryButton` "Set as pickup location" (existing confirm action).

### 12 Product detail
- Top image area ~330px on a dark (`#121212`) or `tile` bg depending on the image, image `contain`; floating back, wishlist, cart (with count badge) `CircleIconButton`s; gallery dots if multiple images.
- Content sheet overlapping by 20px, `background`, top radius 24: category label (11 w700 gold, uppercase), stock indicator right ("● In stock · N left" in `success`; out of stock in `danger`), name 19 w700, price row: serif 26 price + struck original price (`hint`) + "-X%" ink pill (only when the product has a discount).
- Variant selector(s) from real variant data: label 12 w600 + pill chips (selected = ink, unavailable = 45% opacity + strikethrough).
- Quantity row with `QuantityStepper`.
- "Find pickup near me" `ListRowCard` row → pickup location.
- Description.
- Sticky bottom bar (white, top border): `SecondaryButton` "🛒 Add to Cart" + `PrimaryButton` "Buy Now", equal width.

### 13 Cart (tab)
Serif "My Cart" 26 + item count. If the subtotal qualifies for free shipping, an `ink` banner "You've unlocked **free shipping** on orders over $50" (truck icon `goldLight`); otherwise show how much more is needed. Items: white card radius 16, 84px rounded image, name (1 line), variant meta 11 `hint`, trash icon, price 15 w700, `QuantityStepper`. `SummaryCard` (Subtotal, Shipping — "Free" in `success` or $4.99, Tax 8%, Total). Sticky `PrimaryButton` "Checkout · $total" above the nav bar. Keep empty-cart state (illustrated, with "Start shopping"). Pricing logic stays exactly as implemented.

### 14 Checkout
Back + centered title. Sections with `SectionLabel`s:
- **Delivery address** card (pin well, name, address, phone, gold "Change") — real user data.
- **Voucher**: field + ink "Apply" button; when applied, a dashed-gold-border row with a gold code tag (e.g. `SAVE5`), description, ✕ remove. Use existing voucher validation (`LAZADA10`, `SAVE5`).
- **Payment method**: `ListRowCard` radio rows — use the app's **existing** payment options (UI only, as today). Selected radio = 6px ink ring.
- **Order summary**: `SummaryCard` including the voucher line in gold.
- Sticky white bottom bar: `PrimaryButton` "Place Order · $total" + "🛡 Payments are secure and encrypted" 11 `hint`.

### 15 Order confirmed
110px `surfaceSoft` circle containing a 74px ink circle with a gold check, two small gold confetti dots; serif "Order placed!" 30; thank-you line; card with Order number / Estimated delivery / Payment / Total paid rows; `PrimaryButton` "Continue Shopping" → Home; `SecondaryButton` "View my orders" → Profile/order history.

### 16 Alerts (pushed from Home bell)
Back + title. Filter chips (All / Orders / Deals) + "Mark all read" (gold). Grouped by `SectionLabel` (Today / Earlier). Unread item = white card with 1px border + gold dot right; read = transparent. Icon well 40px; order/shipping alerts use an ink well with `goldLight` icon. Keep the current (sample) data source.

### 17 Profile (tab)
Serif "Profile" + gear `CircleIconButton` → Settings. `ink` header card radius 22 (faint gold ring decoration top-right): 68px avatar (photo if set, else gold circle with serif initial) with a small cream camera button (existing change-photo action), name 17 w700, email `#BFB3A2`, edit button (12% cream circle) → existing edit profile. Three stat cards (gold icon, serif 22 number, 11 `hint` label: Orders / Reviews / Points). `SectionLabel` + `ListRowCard` groups: **Account information** (only fields the app actually has), **My activity** (Order history, Saved items, My reviews — keep "coming soon" behavior), **More** (Settings, Log out in `danger`).

### 18 Settings (pushed from Profile)
Back + title. Profile summary card (gold initial avatar, name, email, chevron). **Preferences**: Dark mode (`GoldSwitch`), Notifications (`GoldSwitch`), Language (subtitle = current, chevron). **Security**: Change password, Biometric login (`GoldSwitch`), Active sessions. **Account**: Log out. Footer "GoBuy · Version x.y.z" from package info. Keep every existing setting row and its current behavior (UI-only toggles stay UI-only).

> Any existing screen not listed here (e.g. edit profile, order history, change password, language picker, product list states): restyle it with the same tokens and shared widgets so it's indistinguishable from the rest.

---

## 5. Dark mode
The app has a dark mode toggle. Provide a dark `ThemeData` that maps the tokens: background `#1E1A17`, surface `#2B2420`, surfaceSoft `#3A322C`, border `#3F3630`, text `#F7F2EA`, muted `#BFB3A2`, gold unchanged. Primary buttons invert (cream bg, ink text). Don't change how the toggle is stored.

## 6. Accessibility
- Every icon-only button gets a `Semantics`/`tooltip` label (wishlist, camera, filter, bell, back, cart).
- Minimum tap target 44×44 (visual can be smaller; pad the hit area).
- Text contrast: never put `hint` text on `tile`; gold text only at ≥12px w600.

## 7. Build order (stop after each step, summarize the diff, then continue)
1. Tokens + `ThemeData` (light + dark) + fonts. App should look partially restyled.
2. Shared widgets (§2) with a temporary `/_gallery` debug route showing all of them.
3. Router: 4-tab shell, Alerts/Settings as pushed routes, register pickup & camera routes, cart badge.
4. Splash + onboarding (add `flutter_svg`, copy `assets/onboarding/*.svg`, declare in `pubspec.yaml`).
5. Auth screens.
6. Home + ProductCard, then Search.
7. Product detail, Cart, Checkout, Order confirmed.
8. Camera search, Pickup location.
9. Alerts, Profile, Settings, and any remaining screens.
10. Consistency pass: grep for hardcoded `Color(0x…)`, `TextStyle(` and `BorderRadius.circular(` outside the theme/widgets and replace with tokens; remove the `/_gallery` route; `flutter analyze` clean; run on a 390-wide device and compare each screen to `design_reference/`.

## 8. Done means
- All 18 reference screens match visually (spacing within a few px, same colors/fonts/radii).
- Every pre-existing feature still works (list them and tick them off).
- No Firebase/provider logic changed (`git diff` shows only UI/theme/router/assets/pubspec).
- `flutter analyze` has zero issues.
