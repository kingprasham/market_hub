import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/google_sheets_service.dart';
import '../../../core/services/watchlist_service.dart';
import '../../../data/models/market/spot_bulletin_model.dart';
import '../../../data/models/watchlist/watchlist_item_model.dart';
import '../../../core/utils/helpers.dart';

/// Generic controller for metal detail pages
/// Dynamically loads data from Google Sheets for any metal
class GenericMetalController extends GetxController {
  final String metalName;

  GenericMetalController({required this.metalName});

  final isLoading = false.obs;
  final prices = <MetalPrice>[].obs;
  final selectedLocation = 'All'.obs;
  final selectedType = 'All'.obs;
  final watchlistUpdateTrigger = 0.obs; // Trigger to force UI updates

  // Dynamic data from sheets
  final locations = <String>[].obs;
  final types = <String>[].obs;

  // Price history for charts
  final priceHistory = <PriceHistoryEntry>[].obs;
  final availableHistoryProducts = <String>[].obs;
  final selectedHistoryProduct = Rxn<String>();

  GoogleSheetsService? _sheetsService;
  WatchlistService? _watchlistService;

  @override
  void onInit() {
    super.onInit();
    _initServices();
    loadData();
  }

  void _initServices() {
    try {
      _sheetsService = Get.find<GoogleSheetsService>();
    } catch (e) {
      debugPrint('GoogleSheetsService not found: $e');
    }

    try {
      _watchlistService = Get.find<WatchlistService>();
      // Listen to watchlist changes and trigger UI updates
      if (_watchlistService != null) {
        ever(_watchlistService!.watchlistItems, (_) => watchlistUpdateTrigger.value++);
        ever(_watchlistService!.starredItemIds, (_) => watchlistUpdateTrigger.value++);
      }
    } catch (e) {
      debugPrint('WatchlistService not found: $e');
    }
  }

  /// Get watchlist IDs from the service
  List<String> get watchlistIds {
    if (_watchlistService == null) return [];
    return _watchlistService!.watchlistItems.map((item) => item.id).toList();
  }

  /// Check if an item is in watchlist
  bool isInWatchlist(String id) {
    return _watchlistService?.isInWatchlist(id) ?? false;
  }

  /// Check if an item is starred
  bool isStarred(String id) {
    return _watchlistService?.isStarred(id) ?? false;
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;

      // Try to load from Google Sheets first
      if (_sheetsService != null) {
        await _loadFromSheets();
        _loadPriceHistory();
      }

      // If no data from sheets, load demo data
      if (prices.isEmpty) {
        _loadDemoData();
      }

      // Update locations and types from loaded prices
      _updateFilters();
    } catch (e) {
      debugPrint('Error loading data for $metalName: $e');
      _loadDemoData();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadFromSheets() async {
    // Make sure bulletin is parsed
    final bulletin = _sheetsService!.spotBulletin;
    if (bulletin == null) {
      await _sheetsService!.parseSpotBulletin();
    }

    final entries = _sheetsService!.getMetalEntries(metalName);
    debugPrint('Loaded ${entries.length} entries for $metalName from Google Sheets');

    if (entries.isNotEmpty) {
      prices.value = entries.map((entry) => MetalPrice(
        id: entry.id,
        location: entry.city,
        type: entry.subtype,
        currentPrice: entry.cashPrice,
        previousPrice: entry.cashPrice - (entry.change ?? 0),
        change: entry.change ?? 0,
        changePercent: entry.changePercent ?? 0,
        unit: entry.unit,
        lastUpdated: entry.lastUpdated,
        creditPrice: entry.creditPrice,
      )).toList();

      for (final p in prices.take(5)) {
        debugPrint('  ${p.location} - ${p.type}: ${p.priceDisplay}');
      }
    }

    // Also load city-wise data from All India rates
    final allIndia = _sheetsService!.getAllIndiaRatesForMetal(metalName);
    debugPrint('All India rates for $metalName: ${allIndia.length}');

    for (final rate in allIndia) {
      // Check if we already have this city/type combination
      final exists = prices.any((p) =>
        p.location.toLowerCase() == rate.city.toLowerCase() &&
        p.type.toLowerCase() == rate.metalName.toLowerCase()
      );
      if (!exists) {
        prices.add(MetalPrice(
          id: '${metalName}_${rate.city}_${rate.metalName}'.toLowerCase().replaceAll(' ', '_'),
          location: rate.city,
          type: rate.metalName,
          currentPrice: rate.price,
          previousPrice: rate.price,
          change: 0,
          changePercent: 0,
          unit: rate.unit,
          lastUpdated: rate.lastUpdated,
          creditPrice: rate.creditPrice,
        ));
      }
    }
  }

  void _loadPriceHistory() {
    if (_sheetsService == null) return;

    // Use the new metal-specific method for better matching
    final matching = _sheetsService!.getProductsWithHistoryForMetal(metalName);

    debugPrint('Found ${matching.length} history products for $metalName');

    // If no matches, try fallback keyword matching
    if (matching.isEmpty) {
      final allProducts = _sheetsService!.getProductsWithHistory();
      final metalLower = metalName.toLowerCase();

      for (final product in allProducts) {
        if (_productMatchesMetal(product.toLowerCase(), metalLower)) {
          matching.add(product);
        }
      }
      debugPrint('Fallback matching: ${matching.length} products for $metalName');
    }

    availableHistoryProducts.assignAll(matching);

    // Load first matching product's history
    if (matching.isNotEmpty) {
      selectedHistoryProduct.value = _getBestMatchingProduct(matching, metalName.toLowerCase());
      final history = _sheetsService!.getPriceHistory(selectedHistoryProduct.value!);
      priceHistory.assignAll(history);
      debugPrint('Loaded ${history.length} history entries for ${selectedHistoryProduct.value}');
    }
  }

  /// Get the best matching product for default selection
  String _getBestMatchingProduct(List<String> products, String metal) {
    final priorityPatterns = {
      'copper': ['Scrap (Cash)', 'Scrap+', 'SCRAP+', 'CC Rod', 'CCROD'],
      'brass': ['Purja', 'PURJA', 'Honey', 'HONEY'],
      'aluminium': ['Bartan', 'BARTAN', 'Ingot', 'INGOT'],
      'zinc': ['HZL', 'Imported', 'IMP'],
      'lead': ['PP', 'Hard', 'HARD'],
      'gun metal': ['Local', 'LOCAL', 'Mix'],
      'nickel': ['Russia', 'RUSSIA', 'Norway'],
      'tin': ['Indonesia', 'INDONESIA', 'Indo'],
    };

    final patterns = priorityPatterns[metal] ?? [];
    for (final pattern in patterns) {
      for (final product in products) {
        if (product.toLowerCase().contains(pattern.toLowerCase())) {
          return product;
        }
      }
    }
    return products.first;
  }

  /// Check if a product matches a metal based on keywords
  bool _productMatchesMetal(String product, String metal) {
    final p = product.toLowerCase();
    switch (metal) {
      case 'copper':
        return p.contains('copper') || p.contains('scrap') || p.contains('ccr') ||
               p.contains('super') || p.contains('zero') || p.contains('cc rod') ||
               p.contains('bhatthi') || p.contains('bhatti') || p.contains('plant');
      case 'brass':
        return p.contains('brass') || p.contains('purja') || p.contains('honey') ||
               p.contains('chadri') || p.contains('bharat');
      case 'aluminium':
        return p.contains('aluminium') || p.contains('bartan') || p.contains('wire') ||
               p.contains('ingot') || (p.contains('rod') && !p.contains('cc'));
      case 'zinc':
        return p.contains('zinc') || p.contains('hzl') || p.contains('imp') ||
               p.contains('az') || p.contains('zamak') || p.contains('pmi') ||
               p.contains('dross') || p.contains('tukadi') || p.contains('die');
      case 'lead':
        return p.contains('lead') || p.contains('pp') || p.contains('batt') ||
               p.contains('hard') || p.contains('soft') || p.contains('black') ||
               p.contains('white');
      case 'nickel':
        return p.contains('nickel') || p.contains('russia') || p.contains('norway') ||
               p.contains('jinchuan');
      case 'tin':
        return p.contains('tin') || p.contains('indo') || p.contains('indonesia');
      case 'gun metal':
        return p.contains('gun metal') || p.contains('local') || p.contains('mix') ||
               p.contains('jalandhar');
      default:
        return p.contains(metal);
    }
  }

  void _updateFilters() {
    // Extract unique locations
    final uniqueLocations = <String>{'All'};
    for (final price in prices) {
      uniqueLocations.add(price.location);
    }
    locations.assignAll(uniqueLocations.toList()..sort());

    // Extract unique types
    final uniqueTypes = <String>{'All'};
    for (final price in prices) {
      uniqueTypes.add(price.type);
    }
    types.assignAll(uniqueTypes.toList()..sort());

    debugPrint('Filters for $metalName: ${locations.length} locations, ${types.length} types');
  }

  void _loadDemoData() {
    // Get default configuration for this metal
    final metalInfo = SpotMetalConfig.getMetalInfo(metalName);
    if (metalInfo == null) {
      debugPrint('No metal info found for $metalName');
      return;
    }

    debugPrint('Loading demo data for $metalName');

    final demoPrices = <MetalPrice>[];
    final basePrice = _getBasePrice(metalName);

    for (final city in SpotMetalConfig.defaultCities.take(6)) {
      for (final subtype in metalInfo.subtypes.take(3)) {
        final variance = (city.hashCode % 10) - 5;
        final price = basePrice + variance;
        final change = (subtype.hashCode % 7) - 3.5;

        demoPrices.add(MetalPrice(
          id: '${metalName}_${subtype}_$city'.replaceAll(' ', '_').toLowerCase(),
          location: city,
          type: subtype,
          currentPrice: price,
          previousPrice: price - change,
          change: change,
          changePercent: (change / price) * 100,
          unit: 'Rs/Kg',
          lastUpdated: DateTime.now(),
        ));
      }
    }

    prices.assignAll(demoPrices);
  }

  double _getBasePrice(String metal) {
    final basePrices = {
      'Copper': 745.0,
      'Brass': 485.0,
      'Aluminium': 198.0,
      'Lead': 178.0,
      'Gun Metal': 520.0,
      'Zinc': 248.0,
      'Nickel': 1425.0,
      'Tin': 2145.0,
      'Stainless Steel': 185.0,
    };
    return basePrices[metal] ?? 500.0;
  }

  Future<void> refreshData() async {
    debugPrint('Refreshing data for $metalName...');
    if (_sheetsService != null) {
      await _sheetsService!.fetchAllSheets();
    }
    await loadData();
  }

  /// Toggle watchlist for a price item - adds/removes from watchlist AND toggles star
  void toggleWatchlist(String id) {
    if (_watchlistService == null) {
      Helpers.showError('Watchlist service not available');
      return;
    }

    final price = prices.firstWhereOrNull((p) => p.id == id);
    if (price == null) return;

    if (_watchlistService!.isInWatchlist(id)) {
      // Remove from watchlist
      _watchlistService!.removeFromWatchlist(id);
      Helpers.showSuccess('Removed from watchlist');
    } else {
      // Add to watchlist
      final item = WatchlistItemModel.fromSpotPrice(
        id: id,
        symbol: '${metalName.toUpperCase()}-${price.type}',
        name: '$metalName ${price.type}',
        location: price.location,
        price: price.currentPrice,
        previousPrice: price.previousPrice,
        change: price.change,
        changePercent: price.changePercent,
        unit: price.unit,
        category: 'Base Metal',
      );
      _watchlistService!.addToWatchlist(item);
      // Also star the item
      _watchlistService!.toggleStar(id);
      Helpers.showSuccess('Added to watchlist & starred');
    }
    // UI will auto-update via watchlistUpdateTrigger
  }

  /// Toggle star only (for items already in watchlist)
  void toggleStar(String id) {
    if (_watchlistService == null) return;
    _watchlistService!.toggleStar(id);
    // UI will auto-update via watchlistUpdateTrigger
  }

  List<MetalPrice> get filteredPrices {
    var result = prices.toList();

    if (selectedLocation.value != 'All') {
      result = result.where((p) => p.location == selectedLocation.value).toList();
    }

    if (selectedType.value != 'All') {
      result = result.where((p) => p.type == selectedType.value).toList();
    }

    return result;
  }

  /// Get gradient colors for this metal
  List<Color> get gradientColors {
    final metalInfo = SpotMetalConfig.getMetalInfo(metalName);
    if (metalInfo != null) {
      return metalInfo.gradientColors.map((c) => Color(c)).toList();
    }
    return [Colors.blue, Colors.blueAccent];
  }

  /// Get accent color for this metal
  Color get accentColor {
    final metalInfo = SpotMetalConfig.getMetalInfo(metalName);
    if (metalInfo != null) {
      return Color(metalInfo.accentColor);
    }
    return Colors.blue;
  }

  /// Get symbol for this metal
  String get metalSymbol {
    final metalInfo = SpotMetalConfig.getMetalInfo(metalName);
    return metalInfo?.symbol ?? metalName.substring(0, 2).toUpperCase();
  }

  /// Load history for a specific product
  void loadHistoryForProduct(String productName) {
    if (_sheetsService == null) return;
    selectedHistoryProduct.value = productName;
    final history = _sheetsService!.getPriceHistory(productName);
    priceHistory.assignAll(history);
    debugPrint('Loaded ${history.length} history entries for $productName');
  }
}

/// Price model for metal detail pages
class MetalPrice {
  final String id;
  final String location;
  final String type;
  final double currentPrice;
  final double previousPrice;
  final double change;
  final double changePercent;
  final String unit;
  final DateTime lastUpdated;
  final double? creditPrice;

  MetalPrice({
    required this.id,
    required this.location,
    required this.type,
    required this.currentPrice,
    required this.previousPrice,
    required this.change,
    required this.changePercent,
    required this.unit,
    required this.lastUpdated,
    this.creditPrice,
  });

  bool get isPositive => change >= 0;

  String get priceDisplay {
    if (creditPrice != null && creditPrice! > 0) {
      return '\u20B9${currentPrice.toStringAsFixed(0)}/${creditPrice!.toStringAsFixed(0)}';
    }
    return '\u20B9${currentPrice.toStringAsFixed(0)}';
  }
}
