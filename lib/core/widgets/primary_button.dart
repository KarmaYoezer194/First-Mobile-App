import 'package:flutter/material.dart';

/// Elevated button that swaps its label for a spinner while [loading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Match whatever color the button's own label uses (its theme's
    // `onPrimary`, i.e. `onDark`) rather than a hardcoded white, which
    // could be wrong depending on brightness/theme.
    final onButtonColor =
        Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({}) ??
            Theme.of(context).colorScheme.onPrimary;

    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(onButtonColor),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );
  }
}
