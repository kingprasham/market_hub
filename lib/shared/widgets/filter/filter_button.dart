import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';
import 'filter_bottom_sheet.dart';

class FilterButton extends StatelessWidget {
  final FilterOptions currentFilters;
  final void Function(FilterOptions) onFilterChanged;
  final bool showDateRange;
  final bool showLocations;
  final bool showExchanges;
  final bool showMetals;

  const FilterButton({
    super.key,
    required this.currentFilters,
    required this.onFilterChanged,
    this.showDateRange = true,
    this.showLocations = true,
    this.showExchanges = true,
    this.showMetals = true,
  });

  @override
  Widget build(BuildContext context) {
    final filterCount = currentFilters.activeFilterCount;

    return Stack(
      children: [
        OutlinedButton.icon(
          onPressed: () {
            FilterBottomSheet.show(
              context: context,
              initialFilters: currentFilters,
              onApply: onFilterChanged,
              showDateRange: showDateRange,
              showLocations: showLocations,
              showExchanges: showExchanges,
              showMetals: showMetals,
            );
          },
          icon: const Icon(Icons.filter_list, size: 18),
          label: const Text('Filter'),
          style: OutlinedButton.styleFrom(
            foregroundColor: filterCount > 0
                ? ColorConstants.primaryOrange
                : ColorConstants.textPrimary,
            side: BorderSide(
              color: filterCount > 0
                  ? ColorConstants.primaryOrange
                  : ColorConstants.borderColor,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (filterCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: ColorConstants.primaryOrange,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                '$filterCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
