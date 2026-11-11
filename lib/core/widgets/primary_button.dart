import 'package:flutter/material.dart';

import 'pressable.dart';

/// Full-width pill button: ink background, ivory label (inverted in dark
/// mode). Swaps its label for a spinner while [loading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  /// Fill the available width (default). Set false for an inline button.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final onButton = Theme.of(context).colorScheme.onPrimary;
    final enabled = onPressed != null && !loading;

    return Pressable(
      enabled: enabled,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: expand
            ? null
            : ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
        child: loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(onButton),
                ),
              )
            : _ButtonLabel(label: label, icon: icon),
      ),
    );
  }
}

/// Pill button with a white background and a hairline border, ink label.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Pressable(
      enabled: enabled,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: expand
            ? null
            : OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : _ButtonLabel(label: label, icon: icon),
      ),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
