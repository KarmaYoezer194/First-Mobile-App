import 'package:flutter/material.dart';

/// Floating action button that recenters the map on the user's current
/// location. Shows a spinner while a fresh GPS fix is being fetched.
class RecenterFab extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const RecenterFab({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'recenter_fab',
      tooltip: 'Recenter on my location',
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : const Icon(Icons.my_location),
    );
  }
}
