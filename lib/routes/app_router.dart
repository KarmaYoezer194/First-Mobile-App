import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
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

/// Every route uses the same transition: a quick fade with a slight slide
/// in from the right ([AppConstants.animPage]).
CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppConstants.animPage,
    reverseTransitionDuration: AppConstants.animPage,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: AppConstants.animCurve);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0.06, 0), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
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
      GoRoute(
          path: '/splash',
          pageBuilder: (context, state) => _page(state, const SplashPage())),
      GoRoute(
          path: '/onboarding',
          pageBuilder: (context, state) =>
              _page(state, const OnboardingPage())),
      GoRoute(
          path: '/login',
          pageBuilder: (context, state) => _page(state, const LoginPage())),
      GoRoute(
          path: '/register',
          pageBuilder: (context, state) => _page(state, const RegisterPage())),
      GoRoute(
          path: '/forgot-password',
          pageBuilder: (context, state) =>
              _page(state, const ForgotPasswordPage())),

      // Standalone (non-tab) routes some pages push to.
      GoRoute(
          path: '/search',
          pageBuilder: (context, state) => _page(state, const SearchPage())),
      // `extra` carries the optional PlaceCategory to preselect (e.g. from a
      // product's "Find pickup near me" tile); push with
      // `context.push<PickupPoint>('/pickup-location', extra: category)` to
      // get a typed result back, same as the old imperative Navigator.push.
      GoRoute(
        path: '/pickup-location',
        pageBuilder: (context, state) => _page(
            state,
            PickupLocationScreen(
              initialCategory: state.extra as PlaceCategory?,
            )),
      ),
      GoRoute(
          path: '/notifications',
          pageBuilder: (context, state) =>
              _page(state, const NotificationsPage())),
      GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => _page(state, const ProfilePage())),
      // `extra` optionally carries a category slug to preselect — e.g. Home's
      // category pills deep-linking straight into "electronics" — with
      // `context.push('/products', extra: slug)`.
      GoRoute(
        path: '/products',
        pageBuilder: (context, state) => _page(
            state, ProductScreen(initialCategorySlug: state.extra as String?)),
      ),
      GoRoute(
          path: '/cart',
          pageBuilder: (context, state) => _page(state, const CartScreen())),
      GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => _page(state, const SettingsPage())),

      // TEMPORARY: shared-widget gallery, debug builds only.
      if (kDebugMode)
        GoRoute(
            path: '/_gallery',
            pageBuilder: (context, state) =>
                _page(state, const WidgetGalleryPage())),

      // Bottom-nav shell: Home, Search, Cart and Profile tabs. Alerts
      // and Settings are the pushed routes above.
      GoRoute(
          path: '/home',
          pageBuilder: (context, state) => _page(state, const AppShell())),
    ],
  );
});
