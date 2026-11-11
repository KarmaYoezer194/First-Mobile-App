import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart' show AuthException;
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
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
      final image = await _imagePicker.pickImage(
          source: ImageSource.gallery, imageQuality: 85);
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
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  /// The avatar: the uploading preview, the saved photo, or a gold circle
  /// with the name's initial.
  Widget _buildProfileImage(String name, String? photoUrl) {
    final palette = context.palette;
    final fallback = ColoredBox(
      color: palette.gold,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: AppFonts.serif(fontSize: 28, color: AppColors.ink),
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
      // the photo instantly instead of re-downloading it every time.
      return CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: 200,
        fadeInDuration: AppConstants.animPress,
        errorWidget: (_, __, ___) => fallback,
        placeholder: (_, __) => fallback,
      );
    }

    return fallback;
  }

  /// Camera button: pick a photo, or (when there is one) choose between
  /// changing and removing it.
  Future<void> _onPhotoButton(bool hasPhoto) async {
    if (!hasPhoto) return _pickImage();
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 0,
              AppConstants.pagePadding, AppConstants.spaceM),
          child: ListRowCard(children: [
            ListRow(
              icon: Icons.photo_library_outlined,
              title: 'Change photo',
              onTap: () => Navigator.pop(ctx, 'change'),
            ),
            ListRow(
              icon: Icons.delete_outline_rounded,
              title: 'Remove photo',
              destructive: true,
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
          ]),
        ),
      ),
    );
    if (action == 'change') await _pickImage();
    if (action == 'remove') await _removeImage();
  }

  Future<void> _editProfile(
      BuildContext context, WidgetRef ref, String name, String email) async {
    final nameController =
        TextEditingController(text: name == 'Guest User' ? '' : name);
    final emailController =
        TextEditingController(text: email == '—' ? '' : email);
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
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
                  Text('Edit profile',
                      style:
                          AppFonts.serif(fontSize: 22, color: ctx.palette.ink)),
                  const SizedBox(height: 18),
                  AppTextField(
                    label: 'Name',
                    controller: nameController,
                    icon: Icons.person_outline_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter your name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Email',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    icon: Icons.mail_outline_rounded,
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Cancel',
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Save',
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            try {
                              final notice = await ref
                                  .read(authNotifierProvider.notifier)
                                  .updateProfile(
                                    displayName: nameController.text.trim(),
                                    email: emailController.text.trim(),
                                  );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text(notice ?? 'Profile updated')),
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
    final palette = context.palette;
    final user = ref.watch(authNotifierProvider);
    final name = (user?.displayName.isNotEmpty ?? false)
        ? user!.displayName
        : 'Guest User';
    final email = user?.email ?? '—';
    final hasPhoto = user?.photoUrl?.isNotEmpty ?? false;

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
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 12,
              AppConstants.pagePadding, AppConstants.spaceL),
          children: [
            Row(
              children: [
                Semantics(
                  header: true,
                  child: Text('Profile',
                      style: AppFonts.serif(fontSize: 26, color: palette.ink)),
                ),
                const Spacer(),
                // Settings moved out of the bottom nav into Profile.
                CircleIconButton(
                  icon: Icons.settings_outlined,
                  tooltip: 'Settings',
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileHeaderCard(
              name: name,
              email: email,
              avatar: _buildProfileImage(name, user?.photoUrl),
              uploading: _uploadingPhoto,
              hasPhoto: hasPhoto,
              onPhoto: _uploadingPhoto ? null : () => _onPhotoButton(hasPhoto),
              onEdit: () => _editProfile(context, ref, name, email),
            ),
            group('Account information', [
              ListRow(
                icon: Icons.mail_outline_rounded,
                title: 'Email',
                subtitle: email,
                showChevron: false,
              ),
              ListRow(
                icon: Icons.badge_outlined,
                title: 'Account ID',
                subtitle: user?.uid ?? '—',
                showChevron: false,
              ),
            ]),
            group('My activity', [
              ListRow(
                icon: Icons.receipt_long_outlined,
                title: 'Order history',
                onTap: () => _comingSoon(context, 'Order history'),
              ),
              ListRow(
                icon: Icons.favorite_border_rounded,
                title: 'Saved items',
                onTap: () => _comingSoon(context, 'Saved items'),
              ),
              ListRow(
                icon: Icons.star_outline_rounded,
                title: 'My reviews',
                onTap: () => _comingSoon(context, 'Reviews'),
              ),
            ]),
            group('More', [
              ListRow(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () => context.push('/settings'),
              ),
              ListRow(
                icon: Icons.logout_rounded,
                title: 'Log out',
                destructive: true,
                onTap: () => confirmLogout(context, ref),
              ),
            ]),
          ].entranceAll(),
        ),
      ),
    );
  }
}

extension on List<Widget> {
  /// Fades the page sections in one after another.
  List<Widget> entranceAll() =>
      [for (final (i, w) in indexed) w.entrance(index: i)];
}

/// Ink card: avatar with a small camera button, name, email, edit button,
/// and a faint gold ring in the top-right corner.
class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.name,
    required this.email,
    required this.avatar,
    required this.uploading,
    required this.hasPhoto,
    required this.onPhoto,
    required this.onEdit,
  });

  final String name;
  final String email;
  final Widget avatar;
  final bool uploading;
  final bool hasPhoto;
  final VoidCallback? onPhoto;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.heroCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusProductCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -110,
            top: -40,
            child: ExcludeSemantics(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: palette.gold.withValues(alpha: 0.3), width: 1),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 68,
                          height: 68,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              avatar,
                              if (uploading)
                                const ColoredBox(
                                  color: Color(0x592B2420),
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Tooltip(
                          message: hasPhoto ? 'Change photo' : 'Add photo',
                          child: Semantics(
                            button: true,
                            label: hasPhoto ? 'Change photo' : 'Add photo',
                            excludeSemantics: true,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onPhoto,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: palette.heroCard, width: 2),
                                ),
                                child: const Icon(Icons.photo_camera_outlined,
                                    size: 13, color: AppColors.ink),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.sans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: palette.onHeroCard)),
                      const SizedBox(height: 3),
                      Text(email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.sans(
                              fontSize: 13, color: AppColors.profileEmail)),
                    ],
                  ),
                ),
                CircleIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit profile',
                  bordered: false,
                  background: palette.onHeroCard.withValues(alpha: 0.12),
                  iconColor: palette.onHeroCard,
                  size: 36,
                  onPressed: onEdit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
