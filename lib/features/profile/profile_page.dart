import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart' show AuthException;
import '../../core/widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';

/// Redesigned Profile screen. Reads the current [AppUser] from
/// [authNotifierProvider]. Swap in a real backend later by updating
/// [AuthService] — this widget won't need to change.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final ImagePicker _imagePicker = ImagePicker();
  // Holds the just-picked image only while it's uploading, so the preview
  // updates instantly instead of waiting on the network round-trip. Once
  // `updatePhoto` resolves, the real source of truth is `user.photoUrl`
  // (persisted, and what every other screen — Home's avatar included —
  // reads), so this is cleared again.
  Uint8List? _pendingImageBytes;
  bool _uploadingPhoto = false;

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image == null || !mounted) return;

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pendingImageBytes = bytes;
        _uploadingPhoto = true;
      });

      try {
        await ref.read(authNotifierProvider.notifier).updatePhoto(
              bytes: bytes,
              fileExtension: _extensionOf(image.name),
            );
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      } finally {
        if (mounted) {
          setState(() {
            _pendingImageBytes = null;
            _uploadingPhoto = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load that image.')),
        );
      }
    }
  }

  String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return 'jpg';
    return fileName.substring(dot + 1);
  }

  Future<void> _removeImage() async {
    try {
      await ref.read(authNotifierProvider.notifier).removePhoto();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Widget _buildProfileImage(String name, String? photoUrl) {
    final fallback = Image.asset(
      'assets/images/profile.jpg',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );

    if (_pendingImageBytes != null) {
      return Image.memory(
        _pendingImageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    if (photoUrl != null && photoUrl.isNotEmpty) {
      // Cached to disk+memory (keyed by URL) so reopening this screen shows
      // the photo instantly instead of re-downloading it from Firebase
      // Storage every time — Image.network had no cache, so it refetched
      // (and re-showed the spinner) on every visit.
      return CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // Decode at roughly the on-screen size instead of full resolution.
        memCacheWidth: 400,
        fadeInDuration: AppConstants.animMicro,
        errorWidget: (_, __, ___) => fallback,
        placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return fallback;
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref, String name, String email) async {
    final nameController = TextEditingController(text: name == 'Guest User' ? '' : name);
    final emailController = TextEditingController(text: email == '—' ? '' : email);
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusXL)),
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
                  Text('Edit profile', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: AppConstants.spaceL),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: AppConstants.spaceM),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: AppConstants.spaceL),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spaceSM),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false)) return;
                            try {
                              final notice =
                                  await ref.read(authNotifierProvider.notifier).updateProfile(
                                        displayName: nameController.text.trim(),
                                        email: emailController.text.trim(),
                                      );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(notice ?? 'Profile updated')),
                                );
                              }
                            } on AuthException catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.message)),
                                );
                              }
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authNotifierProvider);
    final name = (user?.displayName.isNotEmpty ?? false)
        ? user!.displayName
        : 'Guest User';
    final email = user?.email ?? '—';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding:
            const EdgeInsets.all(AppConstants.spaceL).copyWith(bottom: AppConstants.listBottomInset),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.spaceL,
              horizontal: AppConstants.spaceM,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer
                  .withValues(alpha: theme.brightness == Brightness.dark ? 0.4 : 0.55),
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              border: Border.all(
                color: theme.colorScheme.primary
                    .withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.18),
              ),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: ClipOval(
                      child: SizedBox(
                        width: 104,
                        height: 104,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildProfileImage(name, user?.photoUrl),
                            if (_uploadingPhoto)
                              ColoredBox(
                                color: Colors.black.withValues(alpha: 0.35),
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: _uploadingPhoto ? null : _pickImage,
                      tooltip: (user?.photoUrl?.isNotEmpty ?? false) ? 'Change image' : 'Add image',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        side: BorderSide(color: theme.scaffoldBackgroundColor, width: 2),
                      ),
                      icon: const Icon(Icons.camera_alt_rounded, size: 14),
                    ),
                  ),
                ],
              ),
              if (user?.photoUrl?.isNotEmpty ?? false)
                TextButton.icon(
                  onPressed: _uploadingPhoto ? null : _removeImage,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Remove image'),
                ),
              const SizedBox(height: AppConstants.spaceM),
              Text(name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(email,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppConstants.spaceM),
              TextButton.icon(
                onPressed: () => _editProfile(context, ref, name, email),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit profile'),
                style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spaceM,
                    vertical: AppConstants.spaceS,
                  ),
                ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceXL),
          const Row(
            children: [
              Expanded(
                  child: StatCard(
                      label: 'Orders',
                      value: '12',
                      icon: Icons.shopping_bag_rounded)),
              SizedBox(width: AppConstants.spaceSM),
              Expanded(
                  child: StatCard(
                      label: 'Reviews', value: '4', icon: Icons.star_rounded)),
              SizedBox(width: AppConstants.spaceSM),
              Expanded(
                  child: StatCard(
                      label: 'Points',
                      value: '860',
                      icon: Icons.workspace_premium_rounded)),
            ],
          ),
          const SizedBox(height: AppConstants.spaceXL),
          const SectionHeader(title: 'Account information'),
          const SizedBox(height: AppConstants.spaceM),
          Card(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: email,
                  trailing: const SizedBox.shrink(),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.badge_outlined,
                  title: 'Account ID',
                  subtitle: user?.uid ?? '—',
                  trailing: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceXL),
          const SectionHeader(title: 'My activity'),
          const SizedBox(height: AppConstants.spaceM),
          Card(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.history_rounded,
                  title: 'Order history',
                  onTap: () => _comingSoon(context, 'Order history'),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.favorite_border_rounded,
                  title: 'Saved items',
                  onTap: () => _comingSoon(context, 'Saved items'),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.rate_review_outlined,
                  title: 'My reviews',
                  onTap: () => _comingSoon(context, 'Reviews'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceXL),
          OutlinedButton.icon(
            onPressed: () => confirmLogout(context, ref),
            icon: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
            label: Text('Log out',
                style: TextStyle(color: theme.colorScheme.error)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: theme.colorScheme.error.withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }
}
