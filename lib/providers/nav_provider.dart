import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks which bottom navigation tab is active. Used by [AppShell] so
/// the selected tab index survives navigation and rebuilds.
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
