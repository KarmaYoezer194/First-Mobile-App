import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/circle_icon_button.dart';
import '../../core/widgets/go_buy_logo.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/onboarding_provider.dart';

/// Size the onboarding SVGs were drawn at. Art and its text labels share
/// this coordinate space.
const Size _artDesignSize = Size(390, 480);

/// How far the text panel overlaps the bottom of the art.
const double _panelOverlap = 28;

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.asset,
    required this.title,
    required this.body,
    this.labels = const [],
  });

  final String asset;
  final String title;
  final String body;

  /// Text drawn on top of the art. The SVGs' own `<text>` elements were
  /// removed because flutter_svg can't render their fonts reliably.
  final List<_ArtLabel> labels;
}

/// A text label placed in the art's 390×480 coordinate space.
class _ArtLabel {
  const _ArtLabel({
    required this.text,
    required this.rect,
    required this.style,
    this.angleDegrees = 0,
    this.pivot,
    this.alignment = Alignment.center,
  });

  final String text;

  /// Box (in art coordinates) the text is aligned inside.
  final Rect rect;
  final TextStyle style;

  /// Rotation, matching the SVG group's `rotate(angle cx cy)`.
  final double angleDegrees;
  final Offset? pivot;
  final Alignment alignment;
}

final List<_OnboardingSlide> _slides = [
  _OnboardingSlide(
    asset: 'assets/onboarding/onboarding_1.svg',
    title: 'Good finds,\nbetter prices',
    body: 'Gadgets, fashion, jewelry and home — thousands of deals, '
        'refreshed every day.',
    labels: [
      _ArtLabel(
        text: '-50%',
        rect: Rect.fromCenter(
            center: const Offset(324, 162), width: 60, height: 30),
        style: AppFonts.serif(
            fontSize: 18, color: AppColors.background, height: 1),
        angleDegrees: 14,
        pivot: const Offset(330, 160),
      ),
      _ArtLabel(
        text: r'$9',
        rect: Rect.fromCenter(
            center: const Offset(50, 300), width: 36, height: 30),
        style: AppFonts.serif(fontSize: 14, color: AppColors.ink, height: 1),
        angleDegrees: -12,
        pivot: const Offset(52, 300),
      ),
    ],
  ),
  const _OnboardingSlide(
    asset: 'assets/onboarding/onboarding_2.svg',
    title: 'Snap it.\nFind it.',
    body: 'See something you love? Take a photo and GoBuy shows you where '
        'to get it for less.',
  ),
  _OnboardingSlide(
    asset: 'assets/onboarding/onboarding_3.svg',
    title: 'Pick up\nnear you',
    body: 'Choose a nearby mall, café or gas station on the map and collect '
        'your order on the way.',
    labels: [
      // The distance chip sits inside `translate(23 34) scale(.88)`, so its
      // box and font size are converted into the art's own coordinates.
      _ArtLabel(
        text: '450 m · 6 min',
        rect: const Rect.fromLTWH(
            23 + .88 * 152, 34 + .88 * 196, .88 * 96, .88 * 38),
        style: AppFonts.sans(
            fontSize: 13 * .88,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            height: 1),
        alignment: Alignment.centerLeft,
      ),
    ],
  ),
];

/// First-run walkthrough (3 slides), shown once between splash and login.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _page = 0;

  bool get _isLastPage => _page == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Marks onboarding as seen (so it never shows again) and leaves.
  Future<void> _finish(String route) async {
    await ref.read(onboardingControllerProvider).markComplete();
    if (mounted) context.go(route);
  }

  void _goTo(int page) => _pageController.animateToPage(
        page,
        duration: AppConstants.animEntrance,
        curve: AppConstants.animCurve,
      );

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final screen = MediaQuery.sizeOf(context);
    // 480px on a 844px-tall phone. Shorter screens shrink the art (it's
    // cropped, not squashed) so the text and buttons below always fit.
    final double artHeight = (screen.height - 350)
        .clamp(240.0, math.min(_artDesignSize.height, screen.height * 0.57))
        .toDouble();

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) => _SlideView(
              slide: _slides[index],
              index: index,
              artHeight: artHeight,
            ),
          ),

          // Top bar: logo on the first slide, back button after that;
          // Skip on every slide but the last.
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
                height: AppConstants.minTapTarget,
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: AppConstants.animToggle,
                      child: _page == 0
                          ? const Padding(
                              key: ValueKey('logo'),
                              padding: EdgeInsets.only(left: 4),
                              child: GoBuyLogo(size: 22, color: AppColors.ink),
                            )
                          : CircleIconButton(
                              key: const ValueKey('back'),
                              icon: Icons.chevron_left_rounded,
                              tooltip: 'Back',
                              bordered: false,
                              background:
                                  AppColors.illoCream.withValues(alpha: 0.85),
                              iconColor: AppColors.ink,
                              onPressed: () => _goTo(_page - 1),
                            ),
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      duration: AppConstants.animToggle,
                      opacity: _isLastPage ? 0 : 1,
                      child: IgnorePointer(
                        ignoring: _isLastPage,
                        child: _SkipPill(onTap: () => _finish('/login')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls: dots + progress button, or the final CTAs.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppConstants.panelPadding, 0,
                    AppConstants.panelPadding, 25),
                child: AnimatedSwitcher(
                  duration: AppConstants.animEntrance,
                  switchInCurve: AppConstants.animCurve,
                  child: _isLastPage
                      ? _FinalActions(
                          key: const ValueKey('final'),
                          onGetStarted: () => _finish('/register'),
                          onSignIn: () => _finish('/login'),
                        )
                      : Padding(
                          key: const ValueKey('progress'),
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Row(
                            children: [
                              _PageDots(count: _slides.length, current: _page),
                              const Spacer(),
                              _ProgressNextButton(
                                progress: (_page + 1) / _slides.length,
                                onTap: () => _goTo(_page + 1),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.index,
    required this.artHeight,
  });

  final _OnboardingSlide slide;
  final int index;
  final double artHeight;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final number = (index + 1).toString().padLeft(2, '0');
    final total = _slides.length.toString().padLeft(2, '0');

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: artHeight,
          child: ExcludeSemantics(
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox.fromSize(
                  size: _artDesignSize,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: SvgPicture.asset(slide.asset, fit: BoxFit.fill),
                      ),
                      for (final label in slide.labels) _ArtLabelView(label),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: artHeight - _panelOverlap,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.radiusXL)),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              // Bottom padding keeps the text clear of the fixed controls.
              padding: const EdgeInsets.fromLTRB(AppConstants.panelPadding, 28,
                  AppConstants.panelPadding, 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number / $total',
                    semanticsLabel: 'Step ${index + 1} of ${_slides.length}',
                    style: AppFonts.sans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.gold,
                      letterSpacing: 11 * 0.14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Semantics(
                    header: true,
                    child: Text(
                      slide.title,
                      style: AppFonts.serif(
                          fontSize: 31, color: palette.ink, height: 1.12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    slide.body,
                    style: AppFonts.sans(
                        fontSize: 14, color: palette.inkMuted, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArtLabelView extends StatelessWidget {
  const _ArtLabelView(this.label);

  final _ArtLabel label;

  @override
  Widget build(BuildContext context) {
    final rect = label.rect;
    final pivot = label.pivot ?? rect.center;
    return Positioned.fromRect(
      rect: rect,
      child: Transform.rotate(
        angle: label.angleDegrees * math.pi / 180,
        // `origin` is measured from the box's center.
        origin: pivot - rect.center,
        child: Align(
          alignment: label.alignment,
          child: Text(label.text, style: label.style, maxLines: 1),
        ),
      ),
    );
  }
}

class _SkipPill extends StatelessWidget {
  const _SkipPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Skip onboarding',
      excludeSemantics: true,
      child: SizedBox(
        height: AppConstants.minTapTarget,
        child: Center(
          child: Pressable(
            child: Material(
              color: AppColors.illoCream.withValues(alpha: 0.85),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onTap,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  child: Text(
                    'Skip',
                    style: AppFonts.sans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: 'Page ${current + 1} of $count',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: AppConstants.animToggle,
              curve: AppConstants.animCurve,
              margin: const EdgeInsets.only(right: 6),
              width: i == current ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == current ? palette.ink : palette.switchTrackOff,
                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
              ),
            ),
        ],
      ),
    );
  }
}

/// 58px ink circle with a chevron, inside a 76px ring whose gold arc shows
/// how far through the slides the user is.
class _ProgressNextButton extends StatelessWidget {
  const _ProgressNextButton({required this.progress, required this.onTap});

  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Next',
      child: Semantics(
        button: true,
        label: 'Next',
        excludeSemantics: true,
        child: SizedBox(
          width: 76,
          height: 76,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: AppConstants.animEntrance,
            curve: AppConstants.animCurve,
            builder: (context, value, child) => CustomPaint(
              painter: _RingPainter(
                progress: value,
                track: palette.switchTrackOff,
                arc: palette.gold,
              ),
              child: child,
            ),
            child: Center(
              child: Pressable(
                child: Material(
                  color: scheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onTap,
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: Icon(Icons.chevron_right_rounded,
                          size: 26, color: scheme.onPrimary),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(
      {required this.progress, required this.track, required this.arc});

  final double progress;
  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.5;
    final rect = Offset.zero & size;
    final circle = rect.deflate(stroke / 2);
    canvas.drawArc(
      circle,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      circle,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = arc
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.arc != arc;
}

class _FinalActions extends StatelessWidget {
  const _FinalActions({
    super.key,
    required this.onGetStarted,
    required this.onSignIn,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(label: 'Get started', onPressed: onGetStarted),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: 'I already have an account. Sign in',
          excludeSemantics: true,
          child: InkWell(
            onTap: onSignIn,
            borderRadius: BorderRadius.circular(AppConstants.radiusPill),
            child: SizedBox(
              height: AppConstants.minTapTarget,
              child: Center(
                child: Text.rich(
                  TextSpan(
                    text: 'I already have an account ',
                    style: AppFonts.sans(fontSize: 13, color: palette.inkMuted),
                    children: [
                      TextSpan(
                        text: 'Sign in',
                        style: AppFonts.sans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: palette.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
