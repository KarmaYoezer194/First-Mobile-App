import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Which provider a [SocialAuthButtons] tap came from.
enum SocialProvider { google, apple, facebook }

/// "or continue with" divider + one full-width button per [SocialProvider].
/// Shared by Login/Register so both screens offer the same providers with
/// identical styling.
class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({
    super.key,
    required this.onPressed,
    this.loadingProvider,
    this.dividerLabel = 'or continue with',
  });

  /// Caller drives the actual sign-in call and owns error handling — this
  /// widget only reports which button was tapped, matching how
  /// [PrimaryButton]'s `onPressed` already works on these screens.
  final ValueChanged<SocialProvider> onPressed;

  /// Set while a sign-in is in flight so only that provider's button shows
  /// a spinner and every button is disabled — avoids two social sign-ins
  /// racing each other.
  final SocialProvider? loadingProvider;

  final String dividerLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceS),
              child: Text(
                dividerLabel,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppConstants.spaceM),
        _SocialButton(
          label: 'Continue with Google',
          leading: const _GoogleGlyph(),
          busy: loadingProvider == SocialProvider.google,
          disabled: loadingProvider != null,
          onPressed: () => onPressed(SocialProvider.google),
        ),
        const SizedBox(height: AppConstants.spaceS),
        _SocialButton(
          label: 'Continue with Apple',
          leading: const Icon(Icons.apple, size: 22),
          busy: loadingProvider == SocialProvider.apple,
          disabled: loadingProvider != null,
          onPressed: () => onPressed(SocialProvider.apple),
        ),
        const SizedBox(height: AppConstants.spaceS),
        _SocialButton(
          label: 'Continue with Facebook',
          leading: const Icon(Icons.facebook_rounded, size: 22, color: Color(0xFF1877F2)),
          busy: loadingProvider == SocialProvider.facebook,
          disabled: loadingProvider != null,
          onPressed: () => onPressed(SocialProvider.facebook),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.leading,
    required this.busy,
    required this.disabled,
    required this.onPressed,
  });

  final String label;
  final Widget leading;
  final bool busy;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: disabled ? null : onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 22,
            width: 22,
            child: busy
                ? const CircularProgressIndicator(strokeWidth: 2.2)
                : leading,
          ),
          const SizedBox(width: AppConstants.spaceS),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Material Icons ships no Google glyph (trademark reasons) — a plain "G"
/// in Google's blue stands in. Swap for the official multi-color asset if
/// this app's brand guidelines call for it.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'G',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF4285F4)),
      ),
    );
  }
}
