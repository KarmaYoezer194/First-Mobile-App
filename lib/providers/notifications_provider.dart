import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One in-app alert. The app has no notifications backend yet, so the list
/// is the same sample data the Alerts screen always showed. It lives in a
/// provider (in memory only) so the Home bell can show an unread dot.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    required this.group,
    required this.read,
  });

  final String id;
  final String title;
  final String message;
  final IconData icon;

  /// "Today" / "Earlier".
  final String group;
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        message: message,
        icon: icon,
        group: group,
        read: read ?? this.read,
      );
}

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super(_sample);

  static const _sample = [
    AppNotification(
      id: 'welcome',
      title: 'Welcome aboard!',
      message: 'Thanks for joining. Explore the app to get started.',
      icon: Icons.celebration_rounded,
      group: 'Today',
      read: false,
    ),
    AppNotification(
      id: 'security',
      title: 'Security alert',
      message: 'Your password was changed successfully.',
      icon: Icons.shield_rounded,
      group: 'Today',
      read: false,
    ),
    AppNotification(
      id: 'weekly',
      title: 'Weekly summary',
      message: 'Here is what happened this week.',
      icon: Icons.insights_rounded,
      group: 'Earlier',
      read: true,
    ),
  ];

  void markAllRead() =>
      state = [for (final n in state) n.read ? n : n.copyWith(read: true)];

  void markRead(String id) => state = [
        for (final n in state)
          n.id == id && !n.read ? n.copyWith(read: true) : n
      ];

  void dismiss(String id) => state = [
        for (final n in state)
          if (n.id != id) n
      ];
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  (ref) => NotificationsNotifier(),
);

final hasUnreadNotificationsProvider = Provider<bool>(
  (ref) => ref.watch(notificationsProvider).any((n) => !n.read),
);
