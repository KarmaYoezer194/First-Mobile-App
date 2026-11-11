import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../providers/notifications_provider.dart';

/// Alerts (opened from Home's bell): "Mark all read", alerts grouped under
/// Today / Earlier. Unread alerts are white cards with a gold dot; read
/// ones sit flat on the page. Tap to mark read, swipe to dismiss.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final items = ref.watch(notificationsProvider);
    final hasUnread = ref.watch(hasUnreadNotificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final groups = <String, List<AppNotification>>{};
    for (final item in items) {
      groups.putIfAbsent(item.group, () => []).add(item);
    }

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
                      child: Text('Alerts',
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
              child: items.isEmpty
                  ? const PlaceholderState(
                      icon: Icons.notifications_off_outlined,
                      title: "You're all caught up",
                      message: 'New alerts will show up here.',
                    ).entrance()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppConstants.pagePadding,
                          4,
                          AppConstants.pagePadding,
                          AppConstants.spaceL),
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: hasUnread ? notifier.markAllRead : null,
                            style: TextButton.styleFrom(
                              foregroundColor: palette.gold,
                              textStyle: AppFonts.sans(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            child: const Text('Mark all read'),
                          ),
                        ),
                        for (final entry in groups.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
                            child: SectionLabel(entry.key),
                          ),
                          for (final item in entry.value)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AlertTile(
                                key: ValueKey(item.id),
                                item: item,
                                onTap: () => notifier.markRead(item.id),
                                onDismissed: () => notifier.dismiss(item.id),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      ],
                      // Fade the list in once, as a whole: animating each
                      // alert by position could leave one stuck invisible
                      // after another is dismissed.
                    ).entrance(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDismissed,
  });

  final AppNotification item;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final unread = !item.read;
    final radius = BorderRadius.circular(AppConstants.radiusM);

    return Dismissible(
      key: ValueKey('dismiss-${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
        decoration:
            BoxDecoration(color: palette.dangerBg, borderRadius: radius),
        child: Icon(Icons.delete_outline_rounded, color: palette.danger),
      ),
      child: Semantics(
        label: unread ? 'Unread' : null,
        child: Material(
          color: unread ? palette.surface : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side:
                BorderSide(color: unread ? palette.border : Colors.transparent),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: palette.surfaceSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, size: 19, color: palette.ink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            style: AppFonts.sans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: palette.ink)),
                        const SizedBox(height: 3),
                        Text(item.message,
                            style: AppFonts.sans(
                                fontSize: 12.5,
                                color: palette.inkMuted,
                                height: 1.45)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedOpacity(
                    duration: AppConstants.animToggle,
                    opacity: unread ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: palette.gold, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
