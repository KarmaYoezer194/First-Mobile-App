import 'package:flutter/material.dart';

/// Centralized color palette. Keep all raw color values here so the rest
/// of the app only ever references semantic names.
///
/// Identity: a warm coral-red accent on a clean white/near-black ground —
/// the "modern storefront" pairing (bold CTA color, generous white space)
/// rather than the app's previous antique-gold "boutique" look. Coral is
/// the one accent — primary actions, active nav states, and discount
/// badges all share it, plus a deep indigo/violet reserved for the promo
/// banner so that one section reads as a distinct highlight without
/// introducing a second color competing for attention everywhere else.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFFF5A5F); // Coral red
  static const Color primaryDark = Color(0xFFFF8A8D); // Coral, lifted for dark surfaces
  static const Color danger = Color(0xFFE0453F);
  static const Color warning = Color(0xFFB8792A);
  static const Color success = Color(0xFF3F7D4C);

  static const Color lightBackground = Color(0xFFF7F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFEBEBF2);
  static const Color lightTextPrimary = Color(0xFF15141F);
  static const Color lightTextSecondary = Color(0xFF6F6E7C);

  static const Color darkBackground = Color(0xFF121118);
  static const Color darkSurface = Color(0xFF1C1B24);
  static const Color darkBorder = Color(0xFF322F3D);
  static const Color darkTextPrimary = Color(0xFFF3F2F8);
  static const Color darkTextSecondary = Color(0xFFA4A2B3);

  /// Small accent-badge gradient (e.g. [AuthHeader]'s icon badge) — not
  /// meant for large background blocks.
  static const List<Color> primaryGradient = [
    Color(0xFFFF7A7E),
    Color(0xFFE0453F),
  ];

  /// The promo-banner gradient (Home's "special offer" card) — the same
  /// coral family as [primary]/[primaryGradient], just deeper, so the
  /// storefront's hero banner reads as one confident brand color instead of
  /// introducing a second accent hue.
  static const List<Color> bannerGradient = [
    Color(0xFFFF6B6F),
    Color(0xFFE0453F),
  ];

  /// A small rotation of jewel-toned gradients for content that needs to
  /// read as distinct at a glance (e.g. Featured cards) without each tile
  /// competing with the one accent color reserved for actions/nav.
  static const List<List<Color>> featuredGradients = [
    [Color(0xFF1F3B57), Color(0xFF3572A6)], // steel blue
    [Color(0xFF6B4A2A), Color(0xFFC79A3D)], // bronze/gold
    [Color(0xFF2B2B2E), Color(0xFF54545C)], // charcoal
    [Color(0xFF7A2E3A), Color(0xFFC05770)], // berry
  ];
}
