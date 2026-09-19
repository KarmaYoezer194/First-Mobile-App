import 'package:flutter/material.dart';

import '../constants/place_categories.dart';

/// Horizontal row of category filter chips, positioned above the map.
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
    final theme = Theme.of(context);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: PlaceCategories.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = PlaceCategories.all[index];
          final isSelected = category == selectedCategory;

          return ChoiceChip(
            selected: isSelected,
            showCheckmark: false,
            avatar: Icon(
              category.icon,
              size: 18,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
            label: Text(category.label),
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: theme.colorScheme.surface,
            selectedColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            elevation: isSelected ? 2 : 0,
            onSelected: (_) => onCategorySelected(category),
          );
        },
      ),
    );
  }
}
