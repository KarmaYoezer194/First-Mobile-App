import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/cards.dart';
import '../../providers/nav_provider.dart';

/// The search field's camera button: lets the user take or pick a photo,
/// then opens the Search tab.
///
/// There's no image-search backend, so the photo isn't sent anywhere; a
/// short message says so instead of pretending it searched.
Future<void> searchByPhoto(BuildContext context, WidgetRef ref) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppConstants.pagePadding, 0,
            AppConstants.pagePadding, AppConstants.spaceM),
        child: ListRowCard(children: [
          ListRow(
            icon: Icons.photo_camera_outlined,
            title: 'Take a photo',
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListRow(
            icon: Icons.photo_library_outlined,
            title: 'Choose from gallery',
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      ),
    ),
  );
  if (source == null) return;

  XFile? photo;
  try {
    photo = await ImagePicker().pickImage(source: source, imageQuality: 85);
  } catch (e) {
    debugPrint('[photo search] $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera or gallery.')),
      );
    }
    return;
  }
  if (photo == null || !context.mounted) return;

  ref.read(bottomNavIndexProvider.notifier).state = kSearchTabIndex;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Searching by photo isn't available yet. "
          'Browse or type to find it.'),
    ),
  );
}
