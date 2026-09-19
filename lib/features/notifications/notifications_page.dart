import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/common_widgets.dart';

class _NotificationItem {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final String group;
  bool read;

  _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    required this.group,
    required this.read,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _items = [
    _NotificationItem(
      id: 'welcome',
      title: 'Welcome aboard!',
      message: 'Thanks for joining. Explore the app to get started.',
      icon: Icons.celebration_rounded,
      group: 'Today',
      read: false,
    ),
    _NotificationItem(
      id: 'security',
      title: 'Security alert',
      message: 'Your password was changed successfully.',
      icon: Icons.shield_rounded,
      group: 'Today',
      read: false,
    ),
    _NotificationItem(
      id: 'weekly',
      title: 'Weekly summary',
      message: 'Here is what happened this week.',
      icon: Icons.insights_rounded,
      group: 'Earlier',
      read: true,
    ),
  ];

  bool get _hasUnread => _items.any((i) => !i.read);

  void _markAllRead() {
    setState(() {
      for (final item in _items) {
        item.read = true;
      }
    });
  }

  void _markRead(_NotificationItem item) {
    if (item.read) return;
    setState(() => item.read = true);
  }

  void _dismiss(_NotificationItem item) {
    setState(() => _items.remove(item));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = <String, List<_NotificationItem>>{};
    for (final item in _items) {
      groups.putIfAbsent(item.group, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _hasUnread ? _markAllRead : null,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: _items.isEmpty
          ? const PlaceholderState(
              icon: Icons.notifications_off_outlined,
              title: "You're all caught up",
              message: 'New alerts will show up here.',
            )
          : ListView(
              padding: const EdgeInsets.all(AppConstants.spaceM),
              children: [
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                    child: Text(
                      entry.key,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final (index, item) in entry.value.indexed) ...[
                    _NotificationTile(
                      item: item,
                      index: index,
                      onTap: () => _markRead(item),
                      onDismissed: () => _dismiss(item),
                    ),
                    const SizedBox(height: AppConstants.spaceSM),
                  ],
                  const SizedBox(height: AppConstants.spaceS),
                ],
              ],
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final _NotificationItem item;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDismissed;
  const _NotificationTile({
    required this.item,
    required this.index,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = !item.read;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          // Matches AppTheme's cardTheme radius (AppConstants.radiusM) so
          // the swipe reveal lines up with the card's own corners.
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Card(
        color: unread ? theme.colorScheme.primary.withValues(alpha: 0.05) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          side: unread
              ? BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.25))
              : BorderSide(color: theme.dividerColor),
        ),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Icon(item.icon, color: theme.colorScheme.primary, size: 20),
          ),
          title: Text(
            item.title,
            style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600),
          ),
          subtitle: Text(item.message),
          trailing: unread
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
      ),
    )
        // Same staggered fade+slide-in convention as the product grid, so
        // this list doesn't just pop onto the screen fully-formed.
        .animate(delay: (index % 8 * 45).ms)
        .fadeIn(duration: AppConstants.animMedium, curve: Curves.easeOut)
        .slideY(begin: 0.08, end: 0, duration: AppConstants.animMedium, curve: Curves.easeOut);
  }
}
