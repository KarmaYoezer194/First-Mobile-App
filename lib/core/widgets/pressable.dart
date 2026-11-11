import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/app_constants.dart';

/// Scales its child to [AppConstants.pressScale] while a pointer is down.
/// Uses a [Listener], so it never competes with the child's own tap
/// handling (buttons, InkWells).
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (!widget.enabled || _down == down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? AppConstants.pressScale : 1,
        duration: AppConstants.animPress,
        curve: AppConstants.animCurve,
        child: widget.child,
      ),
    );
  }
}

extension EntranceAnimation on Widget {
  /// The standard content entrance: fade in + slide up slightly.
  /// Pass [index] for grids/lists to stagger items; only the first
  /// [AppConstants.staggerMaxItems] items animate.
  Widget entrance({int index = 0}) {
    if (index >= AppConstants.staggerMaxItems) return this;
    return animate(
      delay: AppConstants.staggerStep * math.max(0, index),
    )
        .fadeIn(
          duration: AppConstants.animEntrance,
          curve: AppConstants.animCurve,
        )
        .slideY(
          begin: AppConstants.entranceSlideY,
          end: 0,
          duration: AppConstants.animEntrance,
          curve: AppConstants.animCurve,
        );
  }
}
