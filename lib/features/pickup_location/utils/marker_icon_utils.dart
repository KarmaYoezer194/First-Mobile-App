import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// flutter_map markers are plain widgets, so each marker style is a small
/// widget.

/// A nearby place: 28px white circle with an ink icon.
class CategoryMarkerPin extends StatelessWidget {
  const CategoryMarkerPin({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: AppShadows.floating,
        ),
        child: Icon(icon, color: AppColors.ink, size: 15),
      ),
    );
  }
}

/// The selected place: ink teardrop pin with a gold icon. Its tip sits at
/// the bottom centre, so place the marker with `Alignment.topCenter`.
class SelectedMarkerPin extends StatelessWidget {
  const SelectedMarkerPin({super.key, required this.icon});

  static const Size size = Size(38, 48);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: size,
      child: CustomPaint(
        painter: _TeardropPainter(),
        child: Align(
          alignment: const Alignment(0, -0.42),
          child: Icon(icon, color: AppColors.goldLight, size: 17),
        ),
      ),
    );
  }
}

class _TeardropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final path = Path()
      ..moveTo(r, size.height)
      ..cubicTo(r * 0.55, size.height * 0.8, 0, r * 1.45, 0, r)
      ..arcToPoint(Offset(size.width, r), radius: Radius.circular(r))
      ..cubicTo(
          size.width, r * 1.45, r * 1.45, size.height * 0.8, r, size.height)
      ..close();
    canvas.drawShadow(path, AppColors.ink, 3, false);
    canvas.drawPath(path, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(_TeardropPainter oldDelegate) => false;
}

/// The user's own location: gold dot with a white border and a soft gold
/// halo.
class UserLocationMarkerPin extends StatelessWidget {
  const UserLocationMarkerPin({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.22),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: AppShadows.floating,
          ),
        ),
      ),
    );
  }
}
