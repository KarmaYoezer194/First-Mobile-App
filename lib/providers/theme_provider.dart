import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  // Default to light regardless of the system setting — users can still
  // switch to dark/system from Settings, this just controls first-launch
  // behavior (and every launch, since theme mode isn't persisted yet).
  ThemeModeNotifier() : super(ThemeMode.light);

  void toggle(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void setMode(ThemeMode mode) => state = mode;
}

final themeModeNotifierProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

/// Kept for backward compatibility with the existing main.dart, which
/// watches `themeModeProvider` directly.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeModeNotifierProvider);
});
