import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/auth_error_banner.dart';
import '../../core/widgets/auth_header.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/social_auth_buttons.dart';
import '../../providers/auth_provider.dart';

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
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isMobile ? 480 : 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppConstants.spaceM),
                    const AuthHeader(
                      icon: Icons.person_add_alt_1_rounded,
                      title: 'Create your account',
                      subtitle: 'Join ${AppConstants.appName} in a few seconds',
                    ),
                    const SizedBox(height: AppConstants.spaceXL),
                    if (_error != null) ...[
                      AuthErrorBanner(message: _error!),
                      const SizedBox(height: AppConstants.spaceM),
                    ],
                    CustomTextField(
                      label: 'Full name',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: AppConstants.spaceM),
                    CustomTextField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: AppConstants.spaceM),
                    CustomTextField(
                      label: 'Password',
                      controller: _passwordController,
                      obscureText: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                    ),
                    const SizedBox(height: AppConstants.spaceM),
                    CustomTextField(
                      label: 'Confirm password',
                      controller: _confirmController,
                      obscureText: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: AppConstants.spaceL),
                    PrimaryButton(label: 'Create Account', loading: _loading, onPressed: _submit),
                    const SizedBox(height: AppConstants.spaceL),
                    SocialAuthButtons(
                      dividerLabel: 'or sign up with',
                      loadingProvider: _socialLoading,
                      onPressed: _continueWith,
                    ),
                    const SizedBox(height: AppConstants.spaceL),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account?'),
                        TextButton(onPressed: () => context.pop(), child: const Text('Sign in')),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spaceL),
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
