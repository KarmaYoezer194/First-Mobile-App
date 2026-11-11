import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Inline error banner shown under an auth form's header. Shared across
/// Login/Register/Forgot-password so all three fail the same way visually.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spaceSM),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border:
            Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: theme.colorScheme.error, size: 20),
          const SizedBox(width: AppConstants.spaceS),
          Expanded(
              child: Text(message,
                  style: TextStyle(color: theme.colorScheme.error))),
        ],
      ),
    );
  }
}
