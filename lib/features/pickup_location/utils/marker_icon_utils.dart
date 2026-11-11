import 'package:flutter/material.dart';

/// flutter_map markers render as arbitrary widgets (not bitmap images
/// like Google Maps), so this builds a small pin-style widget per
/// category instead of returning an icon descriptor.
class CategoryMarkerPin extends StatelessWidget {
  final IconData icon;
  final Color color;

  const CategoryMarkerPin({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

/// Marker pin used for the single search-bar result.
class SearchResultMarkerPin extends StatelessWidget {
  const SearchResultMarkerPin({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.place, color: Colors.white, size: 18),
    );
  }
}

/// Marker pin used for the user's own current location.
class UserLocationMarkerPin extends StatelessWidget {
  const UserLocationMarkerPin({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
