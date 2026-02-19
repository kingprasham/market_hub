import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

enum SearchCategory {
  metals,
  news,
  alerts,
}

class SearchResult {
  final String id;
  final SearchCategory category;
  final String title;
  final String subtitle;
  final String? route;
  final Map<String, dynamic>? arguments;
  final IconData icon;

  SearchResult({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    this.route,
    this.arguments,
    required this.icon,
  });
}

class SearchController extends GetxController {
  final searchTextController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final RxList<String> _recentSearches = <String>[].obs;
  final RxList<SearchResult> _searchResults = <SearchResult>[].obs;
  final RxBool _isSearching = false.obs;
  final RxBool _showSuggestions = false.obs;

  Timer? _debounceTimer;

  String get searchQuery => _searchQuery.value;
  List<String> get recentSearches => _recentSearches;
  List<SearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching.value;
  bool get showSuggestions => _showSuggestions.value;

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();

    // Listen to search text changes
    searchTextController.addListener(_onSearchTextChanged);
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    searchTextController.dispose();
    super.onClose();
  }

  void _onSearchTextChanged() {
    _searchQuery.value = searchTextController.text;

    if (_searchQuery.value.isEmpty) {
      _showSuggestions.value = false;
      _searchResults.clear();
      return;
    }

    _showSuggestions.value = true;

    // Debounce search - wait 300ms before searching
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(_searchQuery.value);
    });
  }

  void _loadRecentSearches() {
    // Load from local storage - currently empty until user performs searches
    _recentSearches.value = [];
  }

  void _performSearch(String query) {
    _isSearching.value = true;

    // TODO: Implement actual search API call
    // For now, return empty results
    Future.delayed(const Duration(milliseconds: 300), () {
      _searchResults.value = [];
      _isSearching.value = false;
    });
  }

  Map<SearchCategory, List<SearchResult>> get categorizedResults {
    final Map<SearchCategory, List<SearchResult>> categorized = {
      SearchCategory.metals: [],
      SearchCategory.news: [],
      SearchCategory.alerts: [],
    };

    for (var result in _searchResults) {
      categorized[result.category]!.add(result);
    }

    // Remove empty categories
    categorized.removeWhere((key, value) => value.isEmpty);

    return categorized;
  }

  void onSearchSubmit(String query) {
    if (query.trim().isEmpty) return;

    // Add to recent searches if not already present
    if (!_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
      // Save to local storage
      _saveRecentSearches();
    }

    _performSearch(query.toLowerCase());
  }

  void onRecentSearchTap(String query) {
    searchTextController.text = query;
    _searchQuery.value = query;
    _performSearch(query.toLowerCase());
  }

  void clearRecentSearches() {
    Get.defaultDialog(
      title: 'Clear Recent Searches',
      middleText: 'Are you sure you want to clear all recent searches?',
      textConfirm: 'Clear',
      textCancel: 'Cancel',
      confirmTextColor: Get.theme.colorScheme.onPrimary,
      onConfirm: () {
        _recentSearches.clear();
        _saveRecentSearches();
        Get.back();
      },
    );
  }

  void removeRecentSearch(String query) {
    _recentSearches.remove(query);
    _saveRecentSearches();
  }

  void clearSearch() {
    searchTextController.clear();
    _searchQuery.value = '';
    _searchResults.clear();
    _showSuggestions.value = false;
  }

  void onResultTap(SearchResult result) {
    // Add to recent searches
    if (!_recentSearches.contains(result.title)) {
      _recentSearches.insert(0, result.title);
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
      _saveRecentSearches();
    }

    // Navigate to result
    if (result.route != null) {
      Get.toNamed(result.route!, arguments: result.arguments);
    }
  }

  void _saveRecentSearches() {
    // Save to local storage - implement with SharedPreferences or GetStorage
    // For now, this is just a placeholder
  }

  String getCategoryName(SearchCategory category) {
    switch (category) {
      case SearchCategory.metals:
        return 'Metals';
      case SearchCategory.news:
        return 'News';
      case SearchCategory.alerts:
        return 'Alerts';
    }
  }
}
