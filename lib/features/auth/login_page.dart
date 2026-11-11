import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/auth_error_banner.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/go_buy_logo.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/social_auth_buttons.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/auth_layout.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  // Left empty so a real email/password can be typed straight away without
  // clearing pre-filled demo text first. The demo creds are one tap away
  // via the "Use demo account" hint below (debug builds only).
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  SocialProvider? _socialLoading;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
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
      // Logged instead of shown, since its message is rarely fit for
      // end users, but you need it to diagnose which step is missing.
      debugPrint('[$provider sign-in] $e\n$st');
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _socialLoading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AuthLayout(
      topBar: const GoBuyLogo(size: 24),
      title: 'Welcome back',
      subtitle: 'Sign in to continue to ${AppConstants.appName}',
      footer: AuthFooterLink(
        question: "Don't have an account?",
        action: 'Sign up',
        onTap: () => context.push('/register'),
      ),
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
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.mail_outline_rounded,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: true,
                  icon: Icons.lock_outline_rounded,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.gold,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(
                          AppConstants.minTapTarget, AppConstants.minTapTarget),
                      textStyle: AppFonts.sans(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 4),
                PrimaryButton(
                    label: 'Sign In', loading: _loading, onPressed: _submit),
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
