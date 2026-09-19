import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

/// Whether the user has already completed the onboarding flow, persisted
/// across app restarts. The splash screen awaits this once on cold start
/// to decide whether to route to `/onboarding`, `/login`, or `/home`.
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(AppConstants.prefOnboardingSeen) ?? false;
});

class OnboardingController {
  /// Marks onboarding as complete so it's never shown again on this
  /// device. Call once, when the user finishes or skips the flow.
  Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingSeen, true);
  }
}

final onboardingControllerProvider = Provider<OnboardingController>((ref) {
  return OnboardingController();
});
