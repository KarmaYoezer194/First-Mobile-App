import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';

/// Shown on cold start while auth state is resolved. Fades the logo/name
/// in, then routes to Home or Login based on [authNotifierProvider].
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppConstants.animSlow,
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    // No real backend to "wait" on right now, so just hold the splash
    // for a moment (long enough to see the animation) then route based
    // on onboarding + auth state.
    Future.delayed(AppConstants.animSlow + const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      final seenOnboarding = await ref.read(onboardingCompleteProvider.future);
      if (!mounted) return;
      if (!seenOnboarding) {
        context.go('/onboarding');
        return;
      }
      final loggedIn = ref.read(isAuthenticatedProvider);
      context.go(loggedIn ? '/home' : '/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Also redirect immediately if auth state changes while splash is
    // still showing (e.g. hot reload during dev).
    ref.listen(authNotifierProvider, (previous, next) {
      if (!mounted) return;
      context.go(next != null ? '/home' : '/login');
    });

    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        // A fixed ink-to-coral gradient rather than `colorScheme.primary`:
        // in dark mode that role becomes a *lighter* coral (for contrast
        // against dark surfaces elsewhere), which would wash out this
        // screen's hardcoded white logo/text. The splash is a brand
        // moment, not theme-reactive UI, so it stays constant either way.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.lightTextPrimary, AppColors.primary],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    // Fixed coral rather than `colorScheme.primary`,
                    // which lightens in dark mode and would wash out
                    // against this box's fixed white background.
                    child: const Icon(Icons.bolt_rounded,
                        size: 52, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.appTagline,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
