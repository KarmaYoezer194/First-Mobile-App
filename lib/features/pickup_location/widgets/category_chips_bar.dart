import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/selection_widgets.dart';
import '../constants/place_categories.dart';

/// Horizontal row of place-type chips over the map. Selected = ink.
class CategoryChipsBar extends StatelessWidget {
  final PlaceCategory? selectedCategory;
  final ValueChanged<PlaceCategory> onCategorySelected;

  const CategoryChipsBar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppConstants.minTapTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: PlaceCategories.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = PlaceCategories.all[index];
          return AppChip(
            label: category.label,
            icon: category.icon,
            selected: category == selectedCategory,
            onTap: () => onCategorySelected(category),
          );
        },
      ),
    );
  }
}
