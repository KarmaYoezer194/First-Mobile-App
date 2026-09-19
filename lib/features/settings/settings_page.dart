import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _language = 'English';

  final List<_Session> _sessions = [
    _Session(device: 'This device', location: 'Current session', current: true),
    _Session(device: 'Chrome on Windows', location: 'Bangkok, TH • 2 hours ago', current: false),
    _Session(device: 'Safari on iPad', location: 'Chiang Mai, TH • 3 days ago', current: false),
  ];

  Future<void> _pickLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusL)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppConstants.spaceM),
              child: Text('Choose language',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final lang in const ['English', 'Spanish', 'French', 'Arabic', 'Thai'])
              ListTile(
                title: Text(lang),
                trailing: lang == _language ? const Icon(Icons.check_rounded) : null,
                onTap: () => Navigator.pop(ctx, lang),
              ),
            const SizedBox(height: AppConstants.spaceS),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _language = selected);
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final nextController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusL)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spaceL),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Change password', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: AppConstants.spaceL),
                  TextFormField(
                    controller: currentController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Current password'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppConstants.spaceM),
                  TextFormField(
                    controller: nextController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New password'),
                    validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                  ),
                  const SizedBox(height: AppConstants.spaceM),
                  TextFormField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm new password'),
                    validator: (v) =>
                        v != nextController.text ? "Passwords don't match" : null,
                  ),
                  const SizedBox(height: AppConstants.spaceL),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) {
                          Navigator.pop(ctx, true);
                        }
                      },
                      child: const Text('Update password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Password updated')));
    }
  }

  void _showActiveSessions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusL)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spaceL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active sessions', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: AppConstants.spaceM),
                for (final session in _sessions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.devices_other_rounded),
                    title: Text(session.device),
                    subtitle: Text(session.location),
                    trailing: session.current
                        ? null
                        : TextButton(
                            onPressed: () {
                              setState(() => _sessions.remove(session));
                              setSheetState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Signed out on ${session.device}')),
                              );
                            },
                            child: const Text('Sign out'),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInfo(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;
    final user = ref.watch(authNotifierProvider);
    final name = (user?.displayName.isNotEmpty ?? false) ? user!.displayName : 'Guest User';
    final email = user?.email ?? '—';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spaceL).copyWith(bottom: AppConstants.listBottomInset),
        children: [
          Material(
            color: theme.colorScheme.primaryContainer
                .withValues(alpha: theme.brightness == Brightness.dark ? 0.4 : 0.55),
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              onTap: () => context.push('/profile'),
              child: Container(
                padding: const EdgeInsets.all(AppConstants.spaceM),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  border: Border.all(
                    color: theme.colorScheme.primary
                        .withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.surface,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spaceM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style:
                                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          Text(email,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spaceXL),
          const SectionHeader(title: 'Preferences'),
          const SizedBox(height: AppConstants.spaceM),
          Card(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark mode',
                  subtitle: isDark ? 'Enabled' : 'Disabled',
                  trailing: Switch(
                    value: isDark,
                    onChanged: (v) =>
                        ref.read(themeModeNotifierProvider.notifier).toggle(v),
                  ),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: _notificationsEnabled ? 'On' : 'Off',
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: _language,
                  onTap: _pickLanguage,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceXL),

          const SectionHeader(title: 'Security'),
          const SizedBox(height: AppConstants.spaceM),
          Card(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.password_rounded,
                  title: 'Change password',
                  onTap: _changePassword,
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometric login',
                  subtitle: _biometricEnabled ? 'Enabled' : 'Disabled',
                  trailing: Switch(
                    value: _biometricEnabled,
                    onChanged: (v) => setState(() => _biometricEnabled = v),
                  ),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.devices_other_rounded,
                  title: 'Active sessions',
                  subtitle: '${_sessions.length} signed in',
                  onTap: _showActiveSessions,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceXL),

          const SectionHeader(title: 'Privacy'),
          const SizedBox(height: AppConstants.spaceM),
          Card(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy policy',
                  onTap: () => _showInfo(
                    'Privacy policy',
                    'We only use your data to run your account and orders — never sold, never shared with advertisers.',
                  ),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.data_usage_rounded,
                  title: 'Data & permissions',
                  onTap: () => _showInfo(
                    'Data & permissions',
                    'Camera and photo access are used only when you choose to add a profile photo. Location is used only to find pickup points near you.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceXL),

          const SectionHeader(title: 'Support'),
          const SizedBox(height: AppConstants.spaceM),
          Card(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About app',
                  onTap: () => _showInfo(
                    'About ${AppConstants.appName}',
                    'Version ${AppConstants.appVersion}. Built with Flutter.',
                  ),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & support',
                  onTap: () => _showInfo(
                    'Help & support',
                    'Need a hand? Reach us at support@example.com and we\'ll get back to you within a day.',
                  ),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Terms & conditions',
                  onTap: () => _showInfo(
                    'Terms & conditions',
                    'By using this app you agree to our standard terms of service.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceXL),

          const SectionHeader(title: 'Account'),
          const SizedBox(height: AppConstants.spaceM),
          Card(
            child: SettingsTile(
              icon: Icons.logout_rounded,
              iconColor: theme.colorScheme.error,
              title: 'Log out',
              trailing: const SizedBox.shrink(),
              onTap: () => confirmLogout(context, ref),
            ),
          ),
          const SizedBox(height: AppConstants.spaceXL),

          Center(
            child: Text(
              'Version ${AppConstants.appVersion}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _Session {
  _Session({required this.device, required this.location, required this.current});

  final String device;
  final String location;
  final bool current;
}
