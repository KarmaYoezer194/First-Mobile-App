import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/pressable.dart';

/// Shared page layout for Login, Register and Forgot password: a top bar
/// (logo or back button), serif headline + subtitle, the form, and an
/// optional footer pinned to the bottom of the screen.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.topBar,
    this.headerIcon,
    this.footer,
    this.pinFooter = true,
  });

  /// Logo (Login) or [AuthBackButton] (Register, Forgot password).
  final Widget? topBar;

  /// Optional 64px icon tile above the title (Forgot password).
  final IconData? headerIcon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  final Widget? footer;

  /// true: footer sits at the bottom of the screen (Login, Forgot
  /// password). false: right under the form (Register).
  final bool pinFooter;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppConstants.panelPadding,
                        12,
                        AppConstants.panelPadding,
                        16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (topBar != null)
                          SizedBox(
                            height: AppConstants.minTapTarget,
                            child: Align(
                                alignment: Alignment.centerLeft, child: topBar),
                          ),
                        SizedBox(height: headerIcon != null ? 20 : 30),
                        if (headerIcon != null) ...[
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: palette.surfaceSoft,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child:
                                Icon(headerIcon, size: 28, color: palette.ink),
                          ),
                          const SizedBox(height: 26),
                        ],
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: AppFonts.serif(
                                fontSize: headerIcon != null ? 30 : 32,
                                color: palette.ink,
                                height: 1.15),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: AppFonts.sans(
                              fontSize: 14,
                              color: palette.inkMuted,
                              height: 1.55),
                        ),
                        const SizedBox(height: 26),
                        ...children,
                        if (footer != null) ...[
                          if (pinFooter) const Spacer(),
                          SizedBox(height: pinFooter ? 24 : 18),
                          Center(child: footer),
                        ],
                      ],
                    ).entrance(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 40px circular back button. Falls back to [fallbackRoute] when there's
/// nothing to go back to (e.g. Register opened from onboarding).
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, this.fallbackRoute = '/login'});

  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    // Shifted left so the visible 40px circle lines up with the 20px edge
    // used in the mockups (its tap area is 44px).
    return Transform.translate(
      offset: const Offset(-6, 0),
      child: CircleIconButton(
        icon: Icons.chevron_left_rounded,
        tooltip: 'Back',
        onPressed: () => goBackOr(context, fallbackRoute),
      ),
    );
  }
}

/// Pops if there's a page underneath, otherwise goes to [route].
void goBackOr(BuildContext context, String route) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(route);
  }
}

/// "Question? **Action**" footer link, with the action underlined.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
  });

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: '$question $action',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(minHeight: AppConstants.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              widthFactor: 1,
              child: Text.rich(
                TextSpan(
                  text: '$question ',
                  style: AppFonts.sans(fontSize: 13, color: palette.inkMuted),
                  children: [
                    TextSpan(
                      text: action,
                      style: AppFonts.sans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ).copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: palette.ink,
                        decorationThickness: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
