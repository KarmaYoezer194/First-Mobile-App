import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/auth_error_banner.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/auth_layout.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .sendPasswordReset(_emailController.text.trim());
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _emailController.text.trim();
    final backToSignIn =
        _BackToSignIn(onTap: () => goBackOr(context, '/login'));

    if (_sent) {
      return AuthLayout(
        topBar: const AuthBackButton(),
        headerIcon: Icons.mark_email_read_outlined,
        title: 'Check your inbox',
        subtitle: 'We sent a password reset link to $email',
        footer: backToSignIn,
        children: const [],
      );
    }

    return AuthLayout(
      topBar: const AuthBackButton(),
      headerIcon: Icons.key_outlined,
      title: 'Forgot password?',
      subtitle: "Enter the email you signed up with and we'll send you a "
          'link to reset your password.',
      footer: backToSignIn,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                AuthErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              AppTextField(
                label: 'Email',
                hint: 'you@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                icon: Icons.mail_outline_rounded,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                onSubmitted: (_) => _submit(),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                  label: 'Send reset link',
                  loading: _loading,
                  onPressed: _submit),
            ],
          ),
        ),
      ],
    );
  }
}

/// "‹ Back to sign in" link at the bottom of the screen.
class _BackToSignIn extends StatelessWidget {
  const _BackToSignIn({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: palette.inkMuted,
        minimumSize:
            const Size(AppConstants.minTapTarget, AppConstants.minTapTarget),
        textStyle: AppFonts.sans(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      icon: const Icon(Icons.chevron_left_rounded, size: 18),
      label: const Text('Back to sign in'),
    );
  }
}
