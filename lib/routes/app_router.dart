import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/app_shell.dart';
import '../features/auth/forgot_password_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/debug/widget_gallery_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/pickup_location/pickup_location.dart';
import '../features/products/screens/product_screen.dart';
import '../features/profile/profile_page.dart';
import '../features/search/search_page.dart';
import '../features/settings/settings_page.dart';
import '../features/splash/splash_page.dart';
import '../providers/auth_provider.dart';

/// Bridges Riverpod state changes into something GoRouter's
/// `refreshListenable` can listen to, so `redirect` re-runs whenever
/// login state changes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final loggedIn = ref.read(isAuthenticatedProvider);
      final path = state.matchedLocation;

      final isSplash = path == '/splash';
      final isOnboarding = path == '/onboarding';
      final isProducts = path == '/products';
      final isCart = path == '/cart';
      final isAuthRoute =
          path == '/login' || path == '/register' || path == '/forgot-password';

      // Let splash and onboarding own their own navigation decisions.
      // The DummyJSON product browser (and the cart/checkout flow built on
      // top of it) is a standalone API demo with no auth of its own, so
      // both stay reachable regardless of login state.
      if (isSplash || isOnboarding || isProducts || isCart) return null;
      // Temporary widget gallery (debug builds only).
      if (kDebugMode && path == '/_gallery') return null;

      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordPage()),

      // Standalone (non-tab) routes some pages push to.
      GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
      // `extra` carries the optional PlaceCategory to preselect (e.g. from a
      // product's "Find pickup near me" tile); push with
      // `context.push<PickupPoint>('/pickup-location', extra: category)` to
      // get a typed result back, same as the old imperative Navigator.push.
      GoRoute(
        path: '/pickup-location',
        builder: (context, state) => PickupLocationScreen(
          initialCategory: state.extra as PlaceCategory?,
        ),
      ),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsPage()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
      // `extra` optionally carries a category slug to preselect — e.g. Home's
      // category pills deep-linking straight into "electronics" — with
      // `context.push('/products', extra: slug)`.
      GoRoute(
        path: '/products',
        builder: (context, state) => ProductScreen(initialCategorySlug: state.extra as String?),
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),

      // TEMPORARY: shared-widget gallery, debug builds only.
      if (kDebugMode)
        GoRoute(path: '/_gallery', builder: (context, state) => const WidgetGalleryPage()),

      // Bottom-nav shell owns Home + the 4 other tabs internally.
      GoRoute(path: '/home', builder: (context, state) => const AppShell()),
    ],
  );
});
