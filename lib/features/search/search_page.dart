import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../pickup_location/pickup_location.dart';
import '../products/widgets/product_browser.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spaceL,
                AppConstants.spaceM,
                AppConstants.spaceL,
                AppConstants.spaceM,
              ),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.location_on_rounded),
                  title: const Text('Choose Pickup Location'),
                  subtitle: const Text('Search or browse nearby places on the map'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final pickupPoint =
                        await context.push<PickupPoint>('/pickup-location');

                    if (pickupPoint != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Selected: ${pickupPoint.placeName}')),
                      );
                    }
                  },
                ),
              ),
            ),
            const Divider(height: 1),
            // DummyJSON product browser: its own search field, category
            // chips, and paginated grid — embedded directly in the tab.
            const Expanded(child: ProductBrowser()),
          ],
        ),
      ),
    );
  }
}
