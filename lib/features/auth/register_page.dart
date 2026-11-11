import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/auth_error_banner.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/social_auth_buttons.dart';
import '../../providers/auth_provider.dart';
import 'widgets/auth_layout.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  SocialProvider? _socialLoading;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          );
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Social sign-up shares the exact same call as social sign-in — Firebase
  // creates the account on first use, there's no separate "register" step.
  Future<void> _continueWith(SocialProvider provider) async {
    setState(() {
      _socialLoading = provider;
      _error = null;
    });

    try {
      final notifier = ref.read(authNotifierProvider.notifier);
      switch (provider) {
        case SocialProvider.google:
          await notifier.signInWithGoogle();
        case SocialProvider.apple:
          await notifier.signInWithApple();
        case SocialProvider.facebook:
          await notifier.signInWithFacebook();
      }
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e, st) {
      // Not an AuthException => it came straight from the provider SDK
      // (Google/Apple/Facebook), usually a config problem (see SETUP.md).
      debugPrint('[$provider sign-in] $e\n$st');
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _socialLoading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      topBar: const AuthBackButton(),
      title: 'Create account',
      subtitle: 'Join ${AppConstants.appName} and start saving today',
      footer: AuthFooterLink(
        question: 'Already have an account?',
        action: 'Sign in',
        // Register can be opened from onboarding with nothing behind it.
        onTap: () => goBackOr(context, '/login'),
      ),
      pinFooter: false,
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  AuthErrorBanner(message: _error!),
                  const SizedBox(height: 16),
                ],
                AppTextField(
                  label: 'Full name',
                  hint: 'Your name',
                  controller: _nameController,
                  icon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.mail_outline_rounded,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Password',
                  hint: 'At least 6 characters',
                  controller: _passwordController,
                  obscureText: true,
                  icon: Icons.lock_outline_rounded,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) => (v == null || v.length < 6)
                      ? 'At least 6 characters'
                      : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Confirm password',
                  hint: 'Re-enter password',
                  controller: _confirmController,
                  obscureText: true,
                  icon: Icons.lock_outline_rounded,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => _submit(),
                  validator: (v) => v != _passwordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                    label: 'Create Account',
                    loading: _loading,
                    onPressed: _submit),
                const SizedBox(height: 26),
                SocialAuthButtons(
                  loadingProvider: _socialLoading,
                  onPressed: _continueWith,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
