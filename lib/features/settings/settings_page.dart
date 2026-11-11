import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
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
    _Session(
        device: 'Chrome on Windows',
        location: 'Bangkok, TH • 2 hours ago',
        current: false),
    _Session(
        device: 'Safari on iPad',
        location: 'Chiang Mai, TH • 3 days ago',
        current: false),
  ];

  Future<void> _pickLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 0,
              AppConstants.pagePadding, AppConstants.spaceM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Choose language',
                  style: AppFonts.serif(fontSize: 22, color: ctx.palette.ink)),
              const SizedBox(height: 14),
              ListRowCard(children: [
                for (final lang in const [
                  'English',
                  'Spanish',
                  'French',
                  'Arabic',
                  'Thai'
                ])
                  ListRow(
                    icon: Icons.language_rounded,
                    title: lang,
                    trailing: lang == _language
                        ? Icon(Icons.check_rounded,
                            size: 20, color: ctx.palette.ink)
                        : const SizedBox.shrink(),
                    onTap: () => Navigator.pop(ctx, lang),
                  ),
              ]),
            ],
          ),
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
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 0,
                AppConstants.pagePadding, AppConstants.pagePadding),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Change password',
                      style:
                          AppFonts.serif(fontSize: 22, color: ctx.palette.ink)),
                  const SizedBox(height: 18),
                  AppTextField(
                    label: 'Current password',
                    controller: currentController,
                    obscureText: true,
                    icon: Icons.lock_outline_rounded,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'New password',
                    controller: nextController,
                    obscureText: true,
                    icon: Icons.lock_outline_rounded,
                    validator: (v) => (v == null || v.length < 6)
                        ? 'At least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Confirm new password',
                    controller: confirmController,
                    obscureText: true,
                    icon: Icons.lock_outline_rounded,
                    validator: (v) => v != nextController.text
                        ? "Passwords don't match"
                        : null,
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Update password',
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        Navigator.pop(ctx, true);
                      }
                    },
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
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 0,
                AppConstants.pagePadding, AppConstants.spaceM),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Active sessions',
                    style:
                        AppFonts.serif(fontSize: 22, color: ctx.palette.ink)),
                const SizedBox(height: 14),
                ListRowCard(children: [
                  for (final session in _sessions)
                    ListRow(
                      icon: Icons.devices_other_rounded,
                      title: session.device,
                      subtitle: session.location,
                      trailing: session.current
                          ? Text('This device',
                              style: AppFonts.sans(
                                  fontSize: 11, color: ctx.palette.hint))
                          : TextButton(
                              style: TextButton.styleFrom(
                                  foregroundColor: ctx.palette.danger),
                              onPressed: () {
                                setState(() => _sessions.remove(session));
                                setSheetState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Signed out on ${session.device}')),
                                );
                              },
                              child: const Text('Sign out'),
                            ),
                    ),
                ]),
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
        content: Text(message,
            style: AppFonts.sans(
                fontSize: 13, color: ctx.palette.inkMuted, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final themeMode = ref.watch(themeModeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;
    final user = ref.watch(authNotifierProvider);
    final name = (user?.displayName.isNotEmpty ?? false)
        ? user!.displayName
        : 'Guest User';
    final email = user?.email ?? '—';
    final sessionCount = _sessions.length;

    Widget group(String label, List<Widget> rows) => Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionLabel(label),
              const SizedBox(height: 10),
              ListRowCard(children: rows),
            ],
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Back button + centred title.
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: SizedBox(
                height: AppConstants.minTapTarget,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CircleIconButton(
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    Semantics(
                      header: true,
                      child: Text('Settings',
                          style: AppFonts.sans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: palette.ink)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 12,
                    AppConstants.pagePadding, AppConstants.spaceL),
                children: [
                  _ProfileSummaryCard(
                    name: name,
                    email: email,
                    // Settings is opened from Profile, so going "to the
                    // profile" just means going back to it.
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.push('/profile'),
                  ),
                  group('Preferences', [
                    ListRow(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark mode',
                      subtitle: isDark ? 'Enabled' : 'Disabled',
                      trailing: GoldSwitch(
                        value: isDark,
                        semanticLabel: 'Dark mode',
                        onChanged: (v) => ref
                            .read(themeModeNotifierProvider.notifier)
                            .toggle(v),
                      ),
                    ),
                    ListRow(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: _notificationsEnabled ? 'On' : 'Off',
                      trailing: GoldSwitch(
                        value: _notificationsEnabled,
                        semanticLabel: 'Notifications',
                        onChanged: (v) =>
                            setState(() => _notificationsEnabled = v),
                      ),
                    ),
                    ListRow(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      subtitle: _language,
                      onTap: _pickLanguage,
                    ),
                  ]),
                  group('Security', [
                    ListRow(
                      icon: Icons.key_outlined,
                      title: 'Change password',
                      onTap: _changePassword,
                    ),
                    ListRow(
                      icon: Icons.fingerprint_rounded,
                      title: 'Biometric login',
                      subtitle: _biometricEnabled ? 'Enabled' : 'Disabled',
                      trailing: GoldSwitch(
                        value: _biometricEnabled,
                        semanticLabel: 'Biometric login',
                        onChanged: (v) => setState(() => _biometricEnabled = v),
                      ),
                    ),
                    ListRow(
                      icon: Icons.devices_other_rounded,
                      title: 'Active sessions',
                      subtitle:
                          '$sessionCount ${sessionCount == 1 ? 'device' : 'devices'}',
                      onTap: _showActiveSessions,
                    ),
                  ]),
                  group('Privacy', [
                    ListRow(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy policy',
                      onTap: () => _showInfo(
                        'Privacy policy',
                        'We only use your data to run your account and orders — never sold, never shared with advertisers.',
                      ),
                    ),
                    ListRow(
                      icon: Icons.data_usage_rounded,
                      title: 'Data & permissions',
                      onTap: () => _showInfo(
                        'Data & permissions',
                        'Camera and photo access are used only when you choose to add a profile photo. Location is used only to find pickup points near you.',
                      ),
                    ),
                  ]),
                  group('Support', [
                    ListRow(
                      icon: Icons.info_outline_rounded,
                      title: 'About app',
                      onTap: () => _showInfo(
                        'About ${AppConstants.appName}',
                        'Version ${AppConstants.appVersion}. Built with Flutter.',
                      ),
                    ),
                    ListRow(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & support',
                      onTap: () => _showInfo(
                        'Help & support',
                        'Need a hand? Reach us at support@example.com and we\'ll get back to you within a day.',
                      ),
                    ),
                    ListRow(
                      icon: Icons.description_outlined,
                      title: 'Terms & conditions',
                      onTap: () => _showInfo(
                        'Terms & conditions',
                        'By using this app you agree to our standard terms of service.',
                      ),
                    ),
                  ]),
                  group('Account', [
                    ListRow(
                      icon: Icons.logout_rounded,
                      title: 'Log out',
                      destructive: true,
                      onTap: () => confirmLogout(context, ref),
                    ),
                  ]),
                  const SizedBox(height: 22),
                  Center(
                    child: Text(
                      '${AppConstants.appName} · Version ${AppConstants.appVersion}',
                      style: AppFonts.sans(fontSize: 11, color: palette.hint),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White card at the top: gold initial avatar, name, email, chevron.
class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.name,
    required this.email,
    required this.onTap,
  });

  final String name;
  final String email;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(AppConstants.radiusM);
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
          borderRadius: radius, side: BorderSide(color: palette.border)),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                    BoxDecoration(color: palette.gold, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppFonts.serif(fontSize: 20, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.sans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: palette.ink)),
                    const SizedBox(height: 2),
                    Text(email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.sans(
                            fontSize: 12, color: palette.inkMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.hint),
            ],
          ),
        ),
      ),
    );
  }
}

class _Session {
  _Session(
      {required this.device, required this.location, required this.current});

  final String device;
  final String location;
  final bool current;
}
