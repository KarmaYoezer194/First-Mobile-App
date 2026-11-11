import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// Which provider a [SocialAuthButtons] tap came from.
enum SocialProvider { google, apple, facebook }

/// "or continue with" divider + three equal logo buttons (Google, Apple,
/// Facebook). Shared by Login and Register.
class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({
    super.key,
    required this.onPressed,
    this.loadingProvider,
    this.dividerLabel = 'or continue with',
  });

  /// Caller drives the actual sign-in call and owns error handling — this
  /// widget only reports which button was tapped.
  final ValueChanged<SocialProvider> onPressed;

  /// Set while a sign-in is in flight so only that provider's button shows
  /// a spinner and every button is disabled — avoids two social sign-ins
  /// racing each other.
  final SocialProvider? loadingProvider;

  final String dividerLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Widget button(SocialProvider provider, String name, Widget logo) =>
        Expanded(
          child: _SocialButton(
            semanticLabel: 'Continue with $name',
            logo: logo,
            busy: loadingProvider == provider,
            disabled: loadingProvider != null,
            onPressed: () => onPressed(provider),
          ),
        );

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: palette.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                dividerLabel,
                style: AppFonts.sans(fontSize: 12, color: palette.hint),
              ),
            ),
            Expanded(child: Divider(color: palette.border)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            button(SocialProvider.google, 'Google',
                SvgPicture.string(_googleLogoSvg, width: 18, height: 18)),
            const SizedBox(width: 10),
            button(SocialProvider.apple, 'Apple',
                Icon(Icons.apple, size: 20, color: palette.ink)),
            const SizedBox(width: 10),
            button(
                SocialProvider.facebook,
                'Facebook',
                const Icon(Icons.facebook_rounded,
                    size: 20, color: Color(0xFF1877F2))),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.semanticLabel,
    required this.logo,
    required this.busy,
    required this.disabled,
    required this.onPressed,
  });

  final String semanticLabel;
  final Widget logo;
  final bool busy;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppConstants.radiusInput);

    return Tooltip(
      message: semanticLabel,
      child: Semantics(
        button: true,
        enabled: !disabled,
        label: semanticLabel,
        excludeSemantics: true,
        child: Pressable(
          enabled: !disabled,
          child: Material(
            color: palette.surface,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: palette.border),
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: disabled ? null : onPressed,
              child: SizedBox(
                height: 46,
                child: Center(
                  child: AnimatedOpacity(
                    duration: AppConstants.animToggle,
                    opacity: disabled && !busy ? 0.5 : 1,
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : logo,
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

/// Google's multi-colour "G" mark, as used on Google sign-in buttons.
const String _googleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
<path fill="#FFC107" d="M43.611 20.083H42V20H24v8h11.303c-1.649 4.657-6.08 8-11.303 8-6.627 0-12-5.373-12-12s5.373-12 12-12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 12.955 4 4 12.955 4 24s8.955 20 20 20 20-8.955 20-20c0-1.341-.138-2.65-.389-3.917z"/>
<path fill="#FF3D00" d="M6.306 14.691l6.571 4.819C14.655 15.108 18.961 12 24 12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 16.318 4 9.656 8.337 6.306 14.691z"/>
<path fill="#4CAF50" d="M24 44c5.166 0 9.86-1.977 13.409-5.192l-6.19-5.238A11.91 11.91 0 0 1 24 36c-5.202 0-9.619-3.317-11.283-7.946l-6.522 5.025C9.505 39.556 16.227 44 24 44z"/>
<path fill="#1976D2" d="M43.611 20.083H42V20H24v8h11.303a12.04 12.04 0 0 1-4.087 5.571l.003-.002 6.19 5.238C36.971 39.205 44 34 44 24c0-1.341-.138-2.65-.389-3.917z"/>
</svg>
''';
