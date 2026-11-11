import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/go_buy_logo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';

/// Shown on cold start while auth state is resolved, then routes to
/// Onboarding, Home or Login.
///
/// The art is drawn at its 390×844 design size and scaled to fit, with the
/// logo, tagline and dots placed in the same coordinates, so everything
/// stays lined up on any screen. The splash is a fixed brand screen: it
/// looks the same in light and dark mode.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _designSize = Size(390, 844);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppConstants.animSlow,
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(
      CurvedAnimation(parent: _controller, curve: AppConstants.animCurve));

  @override
  void initState() {
    super.initState();
    // No real backend to "wait" on right now, so just hold the splash
    // for a moment (long enough to see the animation) then route based
    // on onboarding + auth state.
    Future.delayed(AppConstants.animSlow + const Duration(milliseconds: 400),
        () async {
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Semantics(
        label: '${AppConstants.appName}. ${AppConstants.appTagline}',
        excludeSemantics: true,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox.fromSize(
              size: _designSize,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SvgPicture.asset(
                      'assets/onboarding/splash_art.svg',
                      fit: BoxFit.fill,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 536,
                    child: FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: Column(
                          children: [
                            const GoBuyLogo(size: 48, color: AppColors.ink),
                            const SizedBox(height: 14),
                            Text(
                              AppConstants.appTagline,
                              style: AppFonts.sans(
                                  fontSize: 14, color: AppColors.inkMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 781,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Dot(AppColors.ink),
                        SizedBox(width: 9),
                        _Dot(AppColors.gold),
                        SizedBox(width: 9),
                        _Dot(AppColors.illoSand),
                      ],
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

class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
