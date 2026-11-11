import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks which bottom navigation tab is active. Used by [AppShell] so
/// the selected tab index survives navigation and rebuilds.
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// Index of the Search tab in the bottom nav.
const int kSearchTabIndex = 1;

/// A one-off request for the Search tab to show a category (e.g. from
/// Home's category circles). The Search tab's product browser applies it
/// and clears it back to null.
final searchCategoryRequestProvider = StateProvider<String?>((ref) => null);
