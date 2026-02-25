import 'package:flutter/material.dart' hide SearchController;
import 'package:get/get.dart';
import '../../../core/constants/color_constants.dart';
import '../controller/search_controller.dart';
import 'package:shimmer/shimmer.dart';

import 'package:market_hub_new/shared/widgets/common/app_logo.dart';

class SearchPage extends GetView<SearchController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: ColorConstants.surfaceColor,
        elevation: 0,
        title: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: AppLogo(),
            ),
            Expanded(child: _buildSearchBar()),
          ],
        ),
        titleSpacing: 0,
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        if (controller.searchQuery.isEmpty) {
          return _buildRecentSearches();
        }

        if (controller.isSearching) {
          return _buildLoadingState();
        }

        if (controller.searchResults.isEmpty) {
          return _buildEmptyState();
        }

        return _buildSearchResults();
      }),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: TextField(
        controller: controller.searchTextController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search metals, news, alerts...',
          hintStyle: const TextStyle(
            color: ColorConstants.textHint,
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: ColorConstants.textSecondary,
          ),
          suffixIcon: Obx(() => controller.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: controller.clearSearch,
                  color: ColorConstants.textSecondary,
                )
              : const SizedBox()),
          filled: true,
          fillColor: ColorConstants.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onSubmitted: controller.onSearchSubmit,
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Obx(() {
      if (controller.recentSearches.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 80,
                color: ColorConstants.textHint.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Start searching',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Search for metals, news, alerts and more',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorConstants.textHint,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.textPrimary,
                ),
              ),
              TextButton(
                onPressed: controller.clearRecentSearches,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...controller.recentSearches.map((search) => _buildRecentSearchItem(search)),
        ],
      );
    });
  }

  Widget _buildRecentSearchItem(String search) {
    return ListTile(
      leading: const Icon(
        Icons.history,
        color: ColorConstants.textSecondary,
      ),
      title: Text(
        search,
        style: const TextStyle(
          fontSize: 15,
          color: ColorConstants.textPrimary,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.clear, size: 20),
        onPressed: () => controller.removeRecentSearch(search),
        color: ColorConstants.textHint,
      ),
      onTap: () => controller.onRecentSearchTap(search),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              title: Container(
                height: 14,
                color: Colors.grey[300],
              ),
              subtitle: Container(
                height: 12,
                margin: const EdgeInsets.only(top: 8),
                color: Colors.grey[300],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: ColorConstants.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Try searching for different keywords',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: ColorConstants.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final categorized = controller.categorizedResults;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categorized.length,
      itemBuilder: (context, index) {
        final category = categorized.keys.elementAt(index);
        final results = categorized[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    controller.getCategoryName(category),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${results.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getCategoryColor(category),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...results.map((result) => _buildSearchResultItem(result, category)),
          ],
        );
      },
    );
  }

  Widget _buildSearchResultItem(SearchResult result, SearchCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ColorConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstants.borderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.onResultTap(result),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    result.icon,
                    color: _getCategoryColor(category),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: ColorConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: ColorConstants.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(SearchCategory category) {
    switch (category) {
      case SearchCategory.metals:
        return ColorConstants.primaryOrange;
      case SearchCategory.news:
        return ColorConstants.primaryBlue;
      case SearchCategory.alerts:
        return ColorConstants.infoColor;
    }
  }
}
