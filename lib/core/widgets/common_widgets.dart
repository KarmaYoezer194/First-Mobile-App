import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Shared "Log out?" confirm dialog + sign-out flow — used from both the
/// Profile and Settings screens so there's exactly one place this can break,
/// not two. Unlike the version this replaced, a failed [AuthService.signOut]
/// call (e.g. dropping a cached Google/Facebook session hitting a network
/// error) is surfaced instead of silently leaving the button looking like it
/// did nothing.
Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('You will need to sign in again to continue.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out')),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    await ref.read(authNotifierProvider.notifier).signOut();
    if (context.mounted) context.go('/login');
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not log out: $e')));
    }
  }
}

/// Section title row (15 w700) with an optional gold action ("See more").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      height: AppConstants.minTapTarget,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Semantics(
              header: true,
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.sans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: palette.ink),
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: palette.gold,
                minimumSize: const Size(
                    AppConstants.minTapTarget, AppConstants.minTapTarget),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                textStyle:
                    AppFonts.sans(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// Full-screen empty/placeholder state: icon in a soft circle, serif
/// title, muted message, optional action.
class PlaceholderState extends StatelessWidget {
  const PlaceholderState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                  color: palette.surfaceSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: palette.ink),
            ),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: AppFonts.serif(fontSize: 22, color: palette.ink)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.sans(
                  fontSize: 13, color: palette.inkMuted, height: 1.45),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
