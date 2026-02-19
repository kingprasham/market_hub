// INTEGRATION EXAMPLE
// This file demonstrates how to integrate Filter and Sort widgets into your screens

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import 'filter_bottom_sheet.dart';
import 'filter_button.dart';
import 'sort_bottom_sheet.dart';

// Example Controller
class ExampleController extends GetxController {
  final Rx<FilterOptions> filterOptions = FilterOptions().obs;
  final Rx<SortOption> sortOption = SortOption.latest.obs;
  final RxList<dynamic> items = <dynamic>[].obs;

  void applyFilters(FilterOptions filters) {
    filterOptions.value = filters;
    // Apply filters to your data
    _loadData();

    Get.snackbar(
      'Filters Applied',
      '${filters.activeFilterCount} filter(s) active',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void applySort(SortOption sort) {
    sortOption.value = sort;
    // Sort your data
    _sortData();

    Get.snackbar(
      'Sort Applied',
      'Sorted by ${sort.label}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _loadData() {
    // Implement your data loading logic with filters
  }

  void _sortData() {
    // Implement your sorting logic
  }
}

// Example Screen
class ExampleScreen extends GetView<ExampleController> {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example Screen'),
        backgroundColor: ColorConstants.surfaceColor,
      ),
      body: Column(
        children: [
          // Filter and Sort Bar
          _buildFilterSortBar(context),

          // Content List
          Expanded(
            child: Obx(() {
              // Your content here
              return ListView.builder(
                itemCount: controller.items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Item $index'),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSortBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: ColorConstants.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: ColorConstants.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Filter Button with Badge
          Obx(() => FilterButton(
            currentFilters: controller.filterOptions.value,
            onFilterChanged: controller.applyFilters,
            showDateRange: true,
            showLocations: true,
            showExchanges: true,
            showMetals: true,
          )),

          const SizedBox(width: 12),

          // Sort Button
          Obx(() => SortButton(
            currentSort: controller.sortOption.value,
            onSortChanged: controller.applySort,
            availableOptions: const [
              SortOption.priceLowToHigh,
              SortOption.priceHighToLow,
              SortOption.nameAZ,
              SortOption.nameZA,
              SortOption.latest,
              SortOption.oldest,
            ],
          )),

          const Spacer(),

          // Active Filters Display
          Obx(() {
            final filterCount = controller.filterOptions.value.activeFilterCount;
            if (filterCount > 0) {
              return Text(
                '$filterCount filter(s)',
                style: const TextStyle(
                  fontSize: 12,
                  color: ColorConstants.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
              );
            }
            return const SizedBox();
          }),
        ],
      ),
    );
  }
}

// ALTERNATIVE INTEGRATION METHODS

// Method 1: Direct Bottom Sheet Call
void showFilterDirectly(BuildContext context) {
  FilterBottomSheet.show(
    context: context,
    initialFilters: FilterOptions(),
    onApply: (filters) {
      // Handle filters
      print('Filters applied: ${filters.activeFilterCount}');
    },
    showDateRange: true,
    showLocations: true,
    showExchanges: true,
    showMetals: false, // Hide metals section
  );
}

// Method 2: Direct Sort Bottom Sheet Call
void showSortDirectly(BuildContext context) {
  SortBottomSheet.show(
    context: context,
    initialSort: SortOption.latest,
    onApply: (sort) {
      // Handle sort
      print('Sort applied: ${sort.label}');
    },
    availableOptions: const [
      SortOption.priceLowToHigh,
      SortOption.priceHighToLow,
      SortOption.latest,
      SortOption.oldest,
    ],
  );
}

// Method 3: Custom Filter Button
class CustomFilterButton extends StatelessWidget {
  final FilterOptions filters;
  final Function(FilterOptions) onApply;

  const CustomFilterButton({
    super.key,
    required this.filters,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        FilterBottomSheet.show(
          context: context,
          initialFilters: filters,
          onApply: onApply,
        );
      },
      icon: const Icon(Icons.filter_alt),
      label: Text(
        filters.hasFilters ? 'Filters (${filters.activeFilterCount})' : 'Filter',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: filters.hasFilters
            ? ColorConstants.primaryOrange
            : ColorConstants.surfaceColor,
        foregroundColor: filters.hasFilters
            ? Colors.white
            : ColorConstants.textPrimary,
      ),
    );
  }
}

// USAGE IN FUTURE PRICES SCREEN
/*
class FuturePricesScreen extends GetView<FuturePricesController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Future Prices'),
        actions: [
          // Add to app bar
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              FilterBottomSheet.show(
                context: context,
                initialFilters: controller.filterOptions.value,
                onApply: controller.applyFilters,
                showExchanges: true,
                showMetals: true,
                showLocations: false, // Don't show locations for futures
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter/Sort Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Obx(() => FilterButton(
                  currentFilters: controller.filterOptions.value,
                  onFilterChanged: controller.applyFilters,
                  showExchanges: true,
                  showMetals: true,
                  showDateRange: false,
                  showLocations: false,
                )),
                const SizedBox(width: 12),
                Obx(() => SortButton(
                  currentSort: controller.sortOption.value,
                  onSortChanged: controller.applySort,
                )),
              ],
            ),
          ),
          // Content...
        ],
      ),
    );
  }
}
*/

// USAGE IN SPOT PRICES SCREEN
/*
class SpotPricesScreen extends GetView<SpotPricesController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter/Sort Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: ColorConstants.surfaceColor,
            child: Row(
              children: [
                Obx(() => FilterButton(
                  currentFilters: controller.filterOptions.value,
                  onFilterChanged: controller.applyFilters,
                  showLocations: true,
                  showMetals: true,
                  showExchanges: false,
                  showDateRange: false,
                )),
                const SizedBox(width: 12),
                Obx(() => SortButton(
                  currentSort: controller.sortOption.value,
                  onSortChanged: controller.applySort,
                  availableOptions: const [
                    SortOption.priceLowToHigh,
                    SortOption.priceHighToLow,
                    SortOption.nameAZ,
                    SortOption.nameZA,
                  ],
                )),
              ],
            ),
          ),
          // Content...
        ],
      ),
    );
  }
}
*/
