import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/onboarding_provider.dart';

class _OnboardingSlide {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

// Accents pulled from the same rotation as Home's Featured cards
// ([AppColors.featuredGradients]) rather than one-off hex values, so
// onboarding reads as part of the same visual system instead of a
// leftover from an earlier palette.
const _slides = [
  _OnboardingSlide(
    icon: Icons.bolt_rounded,
    color: Color(0xFF2B2B2E), // charcoal
    title: 'Welcome to ${AppConstants.appName}',
    description: 'Everything you need, in one fast, focused app — '
        'let’s take a quick look at what’s inside.',
  ),
  _OnboardingSlide(
    icon: Icons.search_rounded,
    color: Color(0xFF1F3B57), // steel blue
    title: 'Find it in seconds',
    description: 'Search across the app and get straight to what you\'re '
        'looking for, with results that keep up as you type.',
  ),
  _OnboardingSlide(
    icon: Icons.map_rounded,
    color: Color(0xFF6B4A2A), // bronze/gold
    title: 'Pick up nearby',
    description: 'Find a pickup point close to you on the map and see it '
        'suggested right from a product you\'re about to order.',
  ),
  _OnboardingSlide(
    icon: Icons.notifications_active_rounded,
    color: Color(0xFF7A2E3A), // berry
    title: 'Never miss an update',
    description: 'Get timely alerts on the things that matter to you, and '
        'stay in control from your notifications center.',
  ),
];

/// First-run walkthrough shown once, between splash and login. See
/// `onboarding_provider.dart` for how "already seen" is persisted.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();

  // Continuous scroll position (e.g. 1.35 while swiping from page 1 to 2) —
  // driving the background/icon animations off this, rather than the
  // discrete page index, is what makes them track the user's finger
  // instead of only snapping at the end of each swipe.
  double _pageOffset = 0;

  int get _page => _pageOffset.round().clamp(0, _slides.length - 1);
  bool get _isLastPage => _page == _slides.length - 1;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page;
      if (page != null) setState(() => _pageOffset = page);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color get _accent {
    final lower = _pageOffset.floor().clamp(0, _slides.length - 1);
    final upper = _pageOffset.ceil().clamp(0, _slides.length - 1);
    final t = _pageOffset - lower;
    return Color.lerp(_slides[lower].color, _slides[upper].color, t) ?? _slides[lower].color;
  }

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider).markComplete();
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_isLastPage) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: AppConstants.animMedium,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accent;

    return Scaffold(
      body: Stack(
        children: [
          // Soft, color-shifting glow blobs that track the current slide's
          // accent color — this is what keeps the background from feeling
          // like a flat, static screen as the user swipes.
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    top: -90,
                    right: -70,
                    child: _GlowBlob(color: accent, size: 260),
                  ),
                  Positioned(
                    bottom: -110,
                    left: -90,
                    child: _GlowBlob(color: accent, size: 300),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Skip — reserves its row even on the last page so the
                // layout below doesn't jump.
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spaceM,
                      vertical: AppConstants.spaceS,
                    ),
                    child: AnimatedOpacity(
                      duration: AppConstants.animFast,
                      opacity: _isLastPage ? 0 : 1,
                      child: IgnorePointer(
                        ignoring: _isLastPage,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.7),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          ),
                          onPressed: _finish,
                          child: const Text('Skip'),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final delta = (_pageOffset - index).clamp(-1.0, 1.0);
                      return _SlideView(slide: _slides[index], delta: delta);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.spaceL,
                    AppConstants.spaceM,
                    AppConstants.spaceL,
                    AppConstants.spaceL,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (index) => _DotIndicator(
                            active: index == _page,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spaceL),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: PrimaryButton(
                          label: _isLastPage ? 'Get Started' : 'Next',
                          icon: _isLastPage ? Icons.arrow_forward_rounded : null,
                          onPressed: _next,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  /// -1..1 — this slide's distance from the current scroll position.
  /// 0 = fully centered, ±1 = fully off to one side.
  final double delta;

  const _SlideView({required this.slide, required this.delta});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final absDelta = delta.abs();
    final scale = 1 - (absDelta * 0.3);
    final opacity = (1 - absDelta).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.scale(
            scale: scale,
            // Icon drifts opposite the swipe direction for a subtle
            // parallax "depth" feel, rather than moving in lockstep with
            // the page underneath it.
            child: Transform.translate(
              offset: Offset(-delta * 36, 0),
              child: _IconBadge(icon: slide.icon, color: slide.color),
            ),
          ),
          const SizedBox(height: AppConstants.spaceXXL),
          Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, delta * 24),
              child: Column(
                children: [
                  Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppConstants.spaceM),
                  Text(
                    slide.description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Layered icon badge — a soft outer ring around a solid inner circle.
/// Flat: no gradient, no shadow, per the design system.
/// Layered icon badge — a soft outer ring, a solid inner circle, and a
/// matching drop shadow — instead of a single flat tinted circle.
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      height: 168,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.10),
      ),
      child: Container(
        width: 124,
        height: 124,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, Color.lerp(color, Colors.black, 0.18)!],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Icon(icon, size: 54, color: Colors.white),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.28),
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final bool active;
  final Color color;
  const _DotIndicator({required this.active, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: AppConstants.animFast,
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: active ? 26 : 8,
      decoration: BoxDecoration(
        color: active ? color : theme.colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
