import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pressable.dart';
import '../pickup_location/pickup_location.dart';
import '../products/widgets/product_browser.dart';
import 'photo_search.dart';

/// Search tab: serif title above the product browser (search field, sort
/// tabs, category chips, product count + "Pickup near me", and the grid).
class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  Future<void> _choosePickup(BuildContext context) async {
    final pickupPoint = await context.push<PickupPoint>('/pickup-location');
    if (pickupPoint != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected: ${pickupPoint.placeName}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppConstants.pagePadding, 16, AppConstants.pagePadding, 14),
              child: Semantics(
                header: true,
                child: Text('Search',
                    style: AppFonts.serif(fontSize: 26, color: palette.ink)),
              ),
            ),
            Expanded(
              child: ProductBrowser(
                onCamera: () => searchByPhoto(context, ref),
                countRowTrailing:
                    _PickupNearMePill(onTap: () => _choosePickup(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White pill: ink circle with a gold pin, "Pickup near me", chevron.
class _PickupNearMePill extends StatelessWidget {
  const _PickupNearMePill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: 'Choose a pickup location near me',
      excludeSemantics: true,
      child: SizedBox(
        height: AppConstants.minTapTarget,
        child: Center(
          child: Pressable(
            child: Material(
              color: palette.surface,
              shape: StadiumBorder(side: BorderSide(color: palette.border)),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                            color: AppColors.ink, shape: BoxShape.circle),
                        child: Icon(Icons.location_on_rounded,
                            size: 13, color: palette.gold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pickup near me',
                        style: AppFonts.sans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: palette.ink),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded,
                          size: 16, color: palette.hint),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
