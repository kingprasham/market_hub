import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';

enum SearchCategory {
  market,
  metals,
  news,
  features,
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

  // The static database of all searchable items in the app
  final List<SearchResult> _searchIndex = [
    // Metals
    SearchResult(id: 'm_copper', category: SearchCategory.metals, title: 'Copper', subtitle: 'LME, SHFE, Comex Prices', route: AppRoutes.copperDetail, icon: Icons.architecture),
    SearchResult(id: 'm_brass', category: SearchCategory.metals, title: 'Brass', subtitle: 'Base Metal Prices', route: AppRoutes.brassDetail, icon: Icons.precision_manufacturing),
    SearchResult(id: 'm_gun_metal', category: SearchCategory.metals, title: 'Gun Metal', subtitle: 'Base Metal Prices', route: AppRoutes.gunMetalDetail, icon: Icons.hardware),
    SearchResult(id: 'm_lead', category: SearchCategory.metals, title: 'Lead', subtitle: 'Base Metal Prices', route: AppRoutes.leadDetail, icon: Icons.battery_charging_full),
    SearchResult(id: 'm_nickel', category: SearchCategory.metals, title: 'Nickel', subtitle: 'Base Metal Prices', route: AppRoutes.nickelDetail, icon: Icons.cable),
    SearchResult(id: 'm_tin', category: SearchCategory.metals, title: 'Tin', subtitle: 'Base Metal Prices', route: AppRoutes.tinDetail, icon: Icons.kitchen),
    SearchResult(id: 'm_zinc', category: SearchCategory.metals, title: 'Zinc', subtitle: 'Base Metal Prices', route: AppRoutes.zincDetail, icon: Icons.roofing),
    SearchResult(id: 'm_alu', category: SearchCategory.metals, title: 'Aluminium', subtitle: 'Base Metal Prices', route: AppRoutes.aluminiumDetail, icon: Icons.flight_takeoff),
    
    // Market Tabs
    SearchResult(id: 'mk_london', category: SearchCategory.market, title: 'London LME', subtitle: 'Global Futures Market', route: AppRoutes.main, arguments: {'tab': 1, 'sub_tab': 0}, icon: Icons.public),
    SearchResult(id: 'mk_china', category: SearchCategory.market, title: 'China SHFE', subtitle: 'Asian Futures Market', route: AppRoutes.main, arguments: {'tab': 1, 'sub_tab': 1}, icon: Icons.auto_graph),
    SearchResult(id: 'mk_us', category: SearchCategory.market, title: 'US Comex', subtitle: 'American Futures Market', route: AppRoutes.main, arguments: {'tab': 1, 'sub_tab': 2}, icon: Icons.trending_up),
    SearchResult(id: 'mk_fx', category: SearchCategory.market, title: 'FX Rates', subtitle: 'Currency Exchange', route: AppRoutes.main, arguments: {'tab': 1, 'sub_tab': 3}, icon: Icons.currency_exchange),
    SearchResult(id: 'mk_ref', category: SearchCategory.market, title: 'Reference Rate', subtitle: 'Benchmark RBI Rates', route: AppRoutes.main, arguments: {'tab': 1, 'sub_tab': 4}, icon: Icons.account_balance),
    SearchResult(id: 'mk_stock', category: SearchCategory.market, title: 'Warehouse Stock', subtitle: 'LME Inventory Levels', route: AppRoutes.main, arguments: {'tab': 1, 'sub_tab': 5}, icon: Icons.warehouse),
    SearchResult(id: 'mk_settle', category: SearchCategory.market, title: 'Settlement', subtitle: 'Daily Settlement Prices', route: AppRoutes.main, arguments: {'tab': 1, 'sub_tab': 6}, icon: Icons.fact_check),
    SearchResult(id: 'mk_spot', category: SearchCategory.market, title: 'Spot Prices', subtitle: 'Live Cash Market', route: AppRoutes.main, arguments: {'tab': 2, 'sub_tab': 0}, icon: Icons.attach_money),
    SearchResult(id: 'mk_bme', category: SearchCategory.market, title: 'BME Prices', subtitle: 'Bombay Metal Exchange', route: AppRoutes.main, arguments: {'tab': 2, 'sub_tab': 1}, icon: Icons.location_city),
    SearchResult(id: 'mk_sbi', category: SearchCategory.market, title: 'SBI Forex', subtitle: 'Card Rates', route: AppRoutes.sbiForex, icon: Icons.price_change),

    // News & Alerts
    SearchResult(id: 'n_live', category: SearchCategory.news, title: 'Live Feed', subtitle: 'Real-time Updates', route: AppRoutes.main, arguments: {'tab': 3, 'sub_tab': 0}, icon: Icons.feed),
    SearchResult(id: 'n_news', category: SearchCategory.news, title: 'News', subtitle: 'English Market News', route: AppRoutes.main, arguments: {'tab': 3, 'sub_tab': 1}, icon: Icons.article),
    SearchResult(id: 'n_hindi', category: SearchCategory.news, title: 'Hindi News (समाचार)', subtitle: 'Regional Market News', route: AppRoutes.main, arguments: {'tab': 3, 'sub_tab': 2}, icon: Icons.newspaper),
    SearchResult(id: 'n_circ', category: SearchCategory.news, title: 'Circulars', subtitle: 'Official Notifications', route: AppRoutes.main, arguments: {'tab': 3, 'sub_tab': 3}, icon: Icons.gavel),
    SearchResult(id: 'n_cal', category: SearchCategory.news, title: 'Economic Calendar', subtitle: 'Upcoming Global Events', route: AppRoutes.main, arguments: {'tab': 3, 'sub_tab': 4}, icon: Icons.calendar_month),

    // Features
    SearchResult(id: 'f_watch', category: SearchCategory.features, title: 'Watchlist', subtitle: 'Your Saved Metals', route: AppRoutes.watchlist, icon: Icons.bookmark),
    SearchResult(id: 'f_prof', category: SearchCategory.features, title: 'Profile', subtitle: 'Your Account Details', route: AppRoutes.profile, icon: Icons.person),
    SearchResult(id: 'f_edit', category: SearchCategory.features, title: 'Edit Profile', subtitle: 'Update Personal Info', route: AppRoutes.editProfile, icon: Icons.edit),
    SearchResult(id: 'f_set', category: SearchCategory.features, title: 'Settings', subtitle: 'App Preferences', route: AppRoutes.settings, icon: Icons.settings),
    SearchResult(id: 'f_pin', category: SearchCategory.features, title: 'Change PIN', subtitle: 'Security & Auth', route: AppRoutes.changePin, icon: Icons.lock),
    SearchResult(id: 'f_sub', category: SearchCategory.features, title: 'Subscription', subtitle: 'Billing & Plans', route: AppRoutes.subscription, icon: Icons.star),
    SearchResult(id: 'f_help', category: SearchCategory.features, title: 'Help & FAQ', subtitle: 'Support Center', route: AppRoutes.helpFaq, icon: Icons.help),
    SearchResult(id: 'f_feed', category: SearchCategory.features, title: 'Feedback', subtitle: 'Tell Us Your Thoughts', route: AppRoutes.feedback, icon: Icons.feedback),
  ];

  void _performSearch(String query) {
    _isSearching.value = true;

    if (query.trim().isEmpty) {
      _searchResults.clear();
      _isSearching.value = false;
      return;
    }

    final lowercaseQuery = query.toLowerCase().trim();

    // Perform partial string matching across titles, sub-titles, and IDs
    final results = _searchIndex.where((item) {
      return item.title.toLowerCase().contains(lowercaseQuery) ||
             item.subtitle.toLowerCase().contains(lowercaseQuery) ||
             item.id.toLowerCase().contains(lowercaseQuery);
    }).toList();

    // Optional: Sort so exact title matches appear first
    results.sort((a, b) {
      final aExact = a.title.toLowerCase().startsWith(lowercaseQuery) ? 0 : 1;
      final bExact = b.title.toLowerCase().startsWith(lowercaseQuery) ? 0 : 1;
      if (aExact != bExact) return aExact.compareTo(bExact);
      return a.title.compareTo(b.title);
    });

    _searchResults.assignAll(results);
    _isSearching.value = false;
  }

  Map<SearchCategory, List<SearchResult>> get categorizedResults {
    final Map<SearchCategory, List<SearchResult>> categorized = {
      SearchCategory.market: [],
      SearchCategory.metals: [],
      SearchCategory.news: [],
      SearchCategory.features: [],
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
    debugPrint('Searching navigation to: ${result.route} with args: ${result.arguments}');
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
      // Use Get.offAllNamed for main to skip backstack bloat when jumping tabs
      if (result.route == AppRoutes.main) {
        Get.offAllNamed(result.route!, arguments: result.arguments);
      } else {
        Get.toNamed(result.route!, arguments: result.arguments);
      }
    }
  }

  void _saveRecentSearches() {
    // Save to local storage - implement with SharedPreferences or GetStorage
    // For now, this is just a placeholder
  }

  String getCategoryName(SearchCategory category) {
    switch (category) {
      case SearchCategory.market:
        return 'Market';
      case SearchCategory.metals:
        return 'Metals';
      case SearchCategory.news:
        return 'News & Alerts';
      case SearchCategory.features:
        return 'App Features';
    }
  }
}
