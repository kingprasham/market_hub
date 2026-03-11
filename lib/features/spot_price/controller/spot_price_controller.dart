import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/google_sheets_service.dart';
import '../../../core/services/watchlist_service.dart';
import '../../../core/services/external_apis/metals_dev_service.dart';
import '../../../data/models/watchlist/watchlist_item_model.dart';
import '../../../data/models/market/spot_price_model.dart';
import '../../../data/models/market/spot_bulletin_model.dart';
import '../../../data/models/market/ferrous_price_model.dart';
import '../../../data/models/market/minor_price_model.dart';
import '../../../data/models/market/non_ferrous_sheet_data.dart';

class SpotPriceController extends GetxController {
  final selectedTabIndex = 0.obs;

  void _handleArguments() {
    final args = Get.arguments;
    if (args is Map && args['sub_tab'] != null) {
      selectedTabIndex.value = args['sub_tab'];
    }
  }
  final isLoading = true.obs;
  final isRefreshing = false.obs;

  // Dynamic data from Google Sheets
  final spotBulletin = Rxn<SpotBulletinModel>();
  final availableMetals = <String>[].obs;
  final availableCities = <String>[].obs;
  // Deprecated: selectedCity is now part of the legacy Non-Ferrous view
  final selectedCity = 'All'.obs; 

  // New Categories
  final spotCategories = ['Non-Ferrous', 'Minor and Ferro', 'Steel'];
  final selectedCategory = 'Non-Ferrous'.obs;

  // Ferrous Data
  final ferrousSubCategories = <String>[].obs;
  final selectedFerrousSubCategory = ''.obs;
  final ferrousPrices = <FerrousPriceModel>[].obs;

  // Minor Data
  final minorSubCategories = <String>[].obs;
  final selectedMinorSubCategory = ''.obs;
  final minorPrices = <MinorPriceModel>[].obs; // Current selected list

  // Non-Ferrous Data (from FOR APP sheet)
  final nonFerrousData = Rxn<NonFerrousSheetData>();
  final nonFerrousCities = <String>[].obs;
  final selectedNonFerrousCity = 'DELHI'.obs;

  final baseMetalPrices = <SpotPriceModel>[].obs;
  final bmePrices = <SpotPriceModel>[].obs;

  // City-wise prices from Google Sheets
  final delhiPrices = <SpotPriceModel>[].obs;
  final mumbaiPrices = <SpotPriceModel>[].obs;
  final jamnagarPrices = <SpotPriceModel>[].obs;

  // All metal entries from bulletin
  final allMetalEntries = <MetalPriceEntry>[].obs;

  StreamSubscription? _dataSubscription;
  WebSocketService? _wsService;
  GoogleSheetsService? _sheetsService;
  MetalsDevService? _metalsDevService;
  WatchlistService? _watchlistService;
  Timer? _autoRefreshTimer;
  // Last update time
  final lastUpdated = Rxn<DateTime>();
  
  // Watchlist trigger
  final watchlistUpdateTrigger = 0.obs;

  // Track last changed timestamp for each item
  final itemLastUpdated = <String, DateTime>{}.obs;
  final _priceSnapshot = <String, String>{};

  final tabs = ['Base Metal', 'BME'];

  // Auto-refresh intervals (in seconds)
  static const int refreshIntervalSeconds = 15;

  @override
  void onInit() {
    super.onInit();
    _handleArguments();
    _initServices();
    fetchAllData();
    _subscribeToRealTimeUpdates();
    _loadGoogleSheetsData();
    _startAutoRefresh();
    
    // Bind ferrous data
    if (_sheetsService != null) {
      ferrousSubCategories.bindStream(_sheetsService!.ferrousHeaders.stream);
      
      // Auto-select first sub-category
      ever(ferrousSubCategories, (List<String> categories) {
        if (categories.isNotEmpty && selectedFerrousSubCategory.isEmpty) {
          selectedFerrousSubCategory.value = categories.first;
        }
      });

      // Update prices when selection changes or data updates
      ever(selectedFerrousSubCategory, _updateFerrousPrices);
      ever(_sheetsService!.ferrousPrices, (_) => _updateFerrousPrices(selectedFerrousSubCategory.value));
    }

    // Bind Minor data
    if (_sheetsService != null) {
      minorSubCategories.bindStream(_sheetsService!.minorSubCategories.stream);

      // Auto-select first sub-category
      ever(minorSubCategories, (List<String> categories) {
        if (categories.isNotEmpty && selectedMinorSubCategory.isEmpty) {
          selectedMinorSubCategory.value = categories.first;
        }
      });

      // Update prices when selection changes or data updates
      ever(selectedMinorSubCategory, _updateMinorPrices);
      ever(_sheetsService!.minorPrices, (_) => _updateMinorPrices(selectedMinorSubCategory.value));
    }
  }

  void _updateFerrousPrices(String category) {
    if (_sheetsService != null && category.isNotEmpty) {
      final prices = _sheetsService!.ferrousPrices[category] ?? [];
      ferrousPrices.assignAll(prices);
      
      // Track changes using true server timestamps where available
      final now = DateTime.now();
      final serverTime = _sheetsService!.sheetTimestamps['Iron & Steel'] ?? 
                         _sheetsService!.globalLastUpdated ?? now;
                         
      for (final p in prices) {
        final key = 'Ferrous|${p.category}|${p.city}';
        final priceStr = p.price.toString();
        if (_priceSnapshot[key] != priceStr) {
          _priceSnapshot[key] = priceStr;
          itemLastUpdated[key] = serverTime;
        } else if (!itemLastUpdated.containsKey(key)) {
          // If no change detected but we don't have a time, use server time
          itemLastUpdated[key] = serverTime;
        }
      }
    }
  }

  void _updateMinorPrices(String category) {
    if (_sheetsService != null && category.isNotEmpty) {
      final prices = _sheetsService!.minorPrices[category] ?? [];
      minorPrices.assignAll(prices);
      
      // Track changes using true server timestamps where available
      final now = DateTime.now();
      final serverTime = _sheetsService!.sheetTimestamps['Minor and Ferro'] ?? 
                         _sheetsService!.globalLastUpdated ?? now;
                         
      for (final p in prices) {
        final key = 'Minor|${p.category}|${p.item}|${p.quality}';
        final priceStr = p.price;
        if (_priceSnapshot[key] != priceStr) {
          _priceSnapshot[key] = priceStr;
          itemLastUpdated[key] = serverTime;
        } else if (!itemLastUpdated.containsKey(key)) {
          itemLastUpdated[key] = serverTime;
        }
      }
    }
  }

  /// Start auto-refresh timer for real-time updates
  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: refreshIntervalSeconds), (timer) {
      if (!isLoading.value && !isRefreshing.value) {
        debugPrint('Auto-refreshing spot prices...');
        refreshData();
      }
    });
  }

  void _initServices() {
    try {
      _sheetsService = Get.find<GoogleSheetsService>();
    } catch (e) {
      debugPrint('GoogleSheetsService not registered yet');
    }
    
    try {
      _metalsDevService = Get.find<MetalsDevService>();
    } catch (e) {
      debugPrint('MetalsDevService not registered yet');
    }
    
    try {
      _watchlistService = Get.find<WatchlistService>();
      if (_watchlistService != null) {
        ever(_watchlistService!.watchlistItems, (_) => watchlistUpdateTrigger.value++);
        ever(_watchlistService!.starredItemIds, (_) => watchlistUpdateTrigger.value++);
      }
    } catch (e) {
      debugPrint('WatchlistService not registered yet');
    }
  }

  void _subscribeToRealTimeUpdates() {
    try {
      _wsService = Get.find<WebSocketService>();
      _wsService!.subscribe('spot');

      _dataSubscription = _wsService!.dataStream.listen((update) {
        if (update.channel == 'spot' && update.payload is Map<String, dynamic>) {
          _handleRealTimeUpdate(update.payload as Map<String, dynamic>);
        }
      });
    } catch (e) {
      debugPrint('WebSocket not initialized: $e');
    }
  }

  void _handleRealTimeUpdate(Map<String, dynamic> data) {
    final category = data['category'] ?? data['type'];
    final updateData = data['data'] ?? data;

    if (updateData is Map<String, dynamic>) {
      if (category == 'baseMetal' || category == 'base_metal') {
        _updateBaseMetalData(updateData);
      } else if (category == 'bme' || category == 'bullion') {
        _updateBmeData(updateData);
      }
    }
  }

  Future<void> _loadGoogleSheetsData() async {
    try {
      if (_sheetsService == null) {
        _sheetsService = Get.find<GoogleSheetsService>();
      }

      // Wait for sheets to be loaded
      await _sheetsService!.initialize();

      // Parse the spot bulletin from DELHI sheet
      final bulletin = await _sheetsService!.parseSpotBulletin(sheetName: 'DELHI');

      if (bulletin != null) {
        spotBulletin.value = bulletin;

        // Update available metals and cities
        availableMetals.assignAll(bulletin.metalCategories);
        // Only add cities from base metals initially, BME cities added later
        // availableCities.assignAll(['All', ...bulletin.cities]);

        // Collect all entries
        final entries = <MetalPriceEntry>[];
        for (final section in bulletin.metalSections) {
          entries.addAll(section.entries);
        }
        allMetalEntries.assignAll(entries);

        debugPrint('Loaded bulletin with ${bulletin.metalSections.length} metal sections');
        for (final section in bulletin.metalSections) {
          debugPrint('  ${section.metalName}: ${section.entries.length} entries');
        }

        // Convert to SpotPriceModel for backward compatibility
        _convertBulletinToSpotPrices(bulletin);
      } else {
        debugPrint('Failed to parse bulletin, using defaults');
        _loadDefaultMetalConfig();
      }

    } catch (e) {
      debugPrint('Error loading Google Sheets data: $e');
      _loadDefaultMetalConfig();
    }

    // Fetch Non-Ferrous data from FOR APP sheet
    try {
      await _sheetsService!.fetchNonFerrousData();
      final nfData = _sheetsService!.nonFerrousData.value;
      if (nfData != null) {
        nonFerrousData.value = nfData;
        nonFerrousCities.assignAll(nfData.cityNames);
        debugPrint('Non-Ferrous cities: ${nonFerrousCities.join(', ')}');
      }
    } catch (e) {
      debugPrint('Error loading Non-Ferrous data: $e');
    }

    // Update Non-Ferrous timestamps
    final nfData = nonFerrousData.value;
    if (nfData != null) {
      final now = DateTime.now();
      final serverTime = _sheetsService!.sheetTimestamps['COPY'] ?? 
                         _sheetsService!.globalLastUpdated ?? now;
                         
      for (final city in nfData.cities) {
        for (final section in city.sections) {
          for (final item in section.items) {
            if (item.isSubHeader) continue;
            final key = 'NonFerrous|${section.sectionName}|${item.name}|${city.cityName}';
            final priceStr = item.displayPrice1 + (item.price2 != null ? item.displayPrice2 : '');
            if (_priceSnapshot[key] != priceStr) {
              _priceSnapshot[key] = priceStr;
              itemLastUpdated[key] = serverTime;
            } else if (!itemLastUpdated.containsKey(key)) {
              itemLastUpdated[key] = serverTime;
            }
          }
        }
      }
      
      // Also check delhi-only sections
      for (final section in nfData.delhiSections) {
        for (final item in section.items) {
          if (item.isSubHeader) continue;
          final key = 'NonFerrous|${section.sectionName}|${item.name}|DELHI';
          final priceStr = item.displayPrice1 + (item.price2 != null ? item.displayPrice2 : '');
          if (_priceSnapshot[key] != priceStr) {
            _priceSnapshot[key] = priceStr;
            itemLastUpdated[key] = serverTime;
          } else if (!itemLastUpdated.containsKey(key)) {
            itemLastUpdated[key] = serverTime;
          }
        }
      }
    }
  }
  
  // NOTE: BME data is now fetched from Metals.Dev API, skipping Google Sheets for BME

  void _convertBulletinToSpotPrices(SpotBulletinModel bulletin) {
    final basePrices = <SpotPriceModel>[];

    for (final section in bulletin.metalSections) {
      for (final entry in section.entries) {
        basePrices.add(SpotPriceModel(
          id: entry.id,
          metalId: section.metalName.toLowerCase(),
          metalName: '${section.metalName} ${entry.subtype}',
          location: entry.city,
          locationCode: entry.city.substring(0, 3).toUpperCase(),
          price: entry.cashPrice,
          previousPrice: entry.cashPrice - (entry.change ?? 0),
          change: entry.change ?? 0,
          changePercent: entry.changePercent ?? 0,
          unit: entry.unit,
          updatedAt: entry.lastUpdated,
          category: 'Base Metal',
        ));
      }
    }

    if (basePrices.isNotEmpty) {
      baseMetalPrices.assignAll(basePrices);
      debugPrint('Converted ${basePrices.length} prices from bulletin');
      
      // Update cities list
      _updateAvailableCities();
    }
  }

  void _loadDefaultMetalConfig() {
    availableMetals.assignAll(SpotMetalConfig.metals.map((m) => m.name).toList());
    _updateAvailableCities();
  }
  
  void _updateAvailableCities() {
    final baseCities = baseMetalPrices.map((p) => p.location).toSet();
    final bmeCities = bmePrices.map((p) => p.location).toSet();
    
    final allCities = {...baseCities, ...bmeCities}.toList();
    allCities.sort();
    
    if (allCities.isNotEmpty && !allCities.contains('All')) {
      allCities.insert(0, 'All');
    } else if (allCities.isEmpty) {
      allCities.add('All');
      allCities.addAll(SpotMetalConfig.defaultCities);
      allCities.sort();
    }
    
    availableCities.assignAll(allCities);
  }

  /// Get entries for a specific metal
  List<MetalPriceEntry> getEntriesForMetal(String metalName) {
    return allMetalEntries.where((e) =>
      e.metalName.toLowerCase() == metalName.toLowerCase()
    ).toList();
  }

  /// Get entries filtered by current city selection
  List<MetalPriceEntry> getFilteredEntries(String metalName) {
    var entries = getEntriesForMetal(metalName);
    if (selectedCity.value != 'All') {
      entries = entries.where((e) =>
        e.city.toLowerCase() == selectedCity.value.toLowerCase()
      ).toList();
    }
    return entries;
  }

  /// Get subtypes for a specific metal
  List<String> getSubtypesForMetal(String metalName) {
    final bulletin = spotBulletin.value;
    if (bulletin != null) {
      final section = bulletin.getMetalSection(metalName);
      return section?.subtypeNames ?? [];
    }
    final metalInfo = SpotMetalConfig.getMetalInfo(metalName);
    return metalInfo?.subtypes ?? [];
  }

  /// Get metal info for styling
  MetalInfo? getMetalInfo(String metalName) {
    return SpotMetalConfig.getMetalInfo(metalName);
  }

  Future<void> refreshData() async {
    isRefreshing.value = true;
    
    // Refresh sheets data first
    if (_sheetsService != null) {
      await _sheetsService!.fetchAllSheets();
    }
    
    await Future.wait([
      fetchAllData(),
      _loadGoogleSheetsData(),
    ]);
    isRefreshing.value = false;
  }

  void _updateBaseMetalData(Map<String, dynamic> update) {
    final index = baseMetalPrices.indexWhere((item) => item.symbol == update['symbol']);
    if (index != -1) {
      final old = baseMetalPrices[index];
      baseMetalPrices[index] = old.copyWith(
        price: update['price']?.toDouble(),
        change: update['change']?.toDouble(),
        changePercent: update['changePercent']?.toDouble(),
        lastUpdated: DateTime.now(),
      );
    }
  }

  void _updateBmeData(Map<String, dynamic> update) {
    final index = bmePrices.indexWhere((item) => item.symbol == update['symbol']);
    if (index != -1) {
      final old = bmePrices[index];
      bmePrices[index] = old.copyWith(
        price: update['price']?.toDouble(),
        change: update['change']?.toDouble(),
        changePercent: update['changePercent']?.toDouble(),
        lastUpdated: DateTime.now(),
      );
    }
  }

  Future<void> fetchAllData() async {
    // Only show loading shimmer if we have no data yet
    if (baseMetalPrices.isEmpty && bmePrices.isEmpty) {
      isLoading.value = true;
    }

    try {
      final futures = <Future>[
        fetchBaseMetalPrices(),
        fetchBmePrices(),
      ];
      if (_sheetsService != null) {
        futures.add(_sheetsService!.fetchFerrousData());
        futures.add(_sheetsService!.fetchMinorData());
      }
      await Future.wait(futures);
      
      // Ensure default selections are made if data is available but nothing selected
      if (ferrousSubCategories.isNotEmpty && selectedFerrousSubCategory.isEmpty) {
        selectedFerrousSubCategory.value = ferrousSubCategories.first;
      }
      
      if (minorSubCategories.isNotEmpty && selectedMinorSubCategory.isEmpty) {
        selectedMinorSubCategory.value = minorSubCategories.first;
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      lastUpdated.value = DateTime.now();
      isLoading.value = false;
      
      // Sync all spot data to Watchlist
      _syncAllToWatchlist();
    }
  }

  void _syncAllToWatchlist() {
    if (_watchlistService == null) return;

    // 1. Sync Base Metal Prices
    for (final p in baseMetalPrices) {
      _watchlistService!.updatePriceById(
        id: p.id,
        price: p.price,
        change: p.change,
        changePercent: p.changePercent,
      );
    }

    // 2. Sync BME Prices
    for (final p in bmePrices) {
      _watchlistService!.updatePriceById(
        id: p.id,
        price: p.price,
        change: p.change,
        changePercent: p.changePercent,
      );
    }

    // 3. Sync Non-Ferrous Prices
    final nfData = nonFerrousData.value;
    if (nfData != null) {
      for (final city in nfData.cities) {
        for (final section in city.sections) {
          for (final item in section.items) {
            if (item.isSubHeader) continue;
            final id = 'spot_nf_${city.cityName.toLowerCase()}_${section.sectionName.toLowerCase()}_${item.name.toLowerCase()}';
            _watchlistService!.updatePriceById(
              id: id,
              price: item.price1,
              // Change/Percent might need specific logic if not directly in item
            );
          }
        }
      }
    }

    // 4. Sync Ferrous Prices
    for (final category in ferrousPrices) {
      final id = 'spot_ferrous_${category.category.toLowerCase()}_${category.city.toLowerCase()}';
      _watchlistService!.updatePriceById(
        id: id,
        price: category.price,
      );
    }

    // 5. Sync Minor Prices
    for (final minor in minorPrices) {
      final id = 'spot_minor_${minor.category.toLowerCase()}_${minor.item.toLowerCase()}';
      // Minor price is String, needs parsing or WatchlistService update
      final price = double.tryParse(minor.price.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (price != null) {
        _watchlistService!.updatePriceById(
          id: id,
          price: price,
        );
      }
    }
  }

  Future<void> fetchBaseMetalPrices() async {
    try {
      // Base metals mostly come from Google Sheets now, but we check API too
      final response = await ApiClient().get(ApiConstants.spotBaseMetal);
      if (response.data != null && response.data['success'] == true) {
        // Only use API data if we don't have sheet data
        if (baseMetalPrices.isEmpty) {
          final data = (response.data['data'] as List)
              .map((json) => SpotPriceModel.fromJson(json))
              .toList();
          baseMetalPrices.assignAll(data);
          _updateAvailableCities();
        }
      }
    } catch (e) {
      // Silently fail for base metals API as we have Google Sheets
    }
  }

  Future<void> fetchBmePrices() async {
    try {
      // 1. Try Google Sheets first (User Preference)
      if (_sheetsService != null && _sheetsService!.bmeRates.isNotEmpty) {
        final sheetRates = _sheetsService!.bmeRates;
        final newBmePrices = <SpotPriceModel>[];
        
        for (final rate in sheetRates) {
          newBmePrices.add(SpotPriceModel(
            id: rate.id,
            metalId: rate.metalName.toLowerCase(),
            metalName: rate.metalName,
            location: rate.city,
            locationCode: rate.city.substring(0, 3).toUpperCase(),
            price: rate.price,
            change: rate.change,
            changePercent: rate.changePercent,
            unit: rate.unit,
            updatedAt: rate.lastUpdated,
            category: 'BME',
            purity: rate.purity,
            symbol: '${rate.metalName.toUpperCase()}-${rate.purity}',
          ));
        }
        
        if (newBmePrices.isNotEmpty) {
          bmePrices.assignAll(newBmePrices);
          _updateAvailableCities();
          debugPrint('✅ Loaded ${newBmePrices.length} BME prices from Google Sheets');
          return;
        }
      }

      // 2. Fallback to Metals.Dev API
      if (_metalsDevService == null) {
        try {
          _metalsDevService = Get.find<MetalsDevService>();
        } catch (_) {}
      }
      
      if (_metalsDevService != null) {
        final prices = await _metalsDevService!.getPreciousMetalPrices(currency: 'INR');
        
        if (prices.isNotEmpty) {
          final newBmePrices = <SpotPriceModel>[];
          final now = DateTime.now();
          
          // Helper to create models for multiple locations
          void addForLocations(String id, String name, double price, String unit, String purity) {
            // Adding for main markets
            final locations = ['All India', 'Mumbai', 'Delhi', 'Ahmedabad'];
            
            for (final loc in locations) {
              newBmePrices.add(SpotPriceModel(
                id: '${id}_${loc.toLowerCase()}',
                metalId: id,
                metalName: name,
                location: loc,
                locationCode: loc.substring(0, 3).toUpperCase(),
                price: price,
                change: 0, // Delta not available in simple fetch
                changePercent: 0,
                unit: unit,
                updatedAt: now,
                category: 'BME',
                purity: purity,
                symbol: '${name.toUpperCase()}-$purity',
              ));
            }
          }

          if (prices.containsKey('gold')) {
            // Gold conversion: toz -> 10g
            // 1 toz = 31.1035g
            // Price(10g) = Price(toz) / 3.11035
            final goldPriceToz = prices['gold']!;
            final goldPrice10g = goldPriceToz / 3.11035;
            
            addForLocations('gold', 'Gold', goldPrice10g, 'Rs/10g', '999');
            
            // Generate 995 prices (~0.995 * 999 price)
            addForLocations('gold_995', 'Gold', goldPrice10g * 0.995, 'Rs/10g', '995');
          }
          
          if (prices.containsKey('silver')) {
            // Silver conversion: toz -> Kg
            // 1 Kg = 32.1507 toz
            final silverPriceToz = prices['silver']!;
            final silverPriceKg = silverPriceToz * 32.1507;
            
            addForLocations('silver', 'Silver', silverPriceKg, 'Rs/Kg', '999');
          }
          
          bmePrices.assignAll(newBmePrices);
          _updateAvailableCities();
          debugPrint('✅ Loaded real-time BME prices from Metals.Dev API');
          return;
        }
      }
      
      // Fallback to backend API if service fails
      final response = await ApiClient().get(ApiConstants.spotBme);

      if (response.data != null && response.data['success'] == true) {
        final data = (response.data['data'] as List)
            .map((json) => SpotPriceModel.fromJson(json))
            .toList();
        bmePrices.assignAll(data);
        _updateAvailableCities();
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch BME prices: $e');
    }
  }

  // Watchlist methods
  List<String> get watchlistIds {
    if (_watchlistService == null) return [];
    return _watchlistService!.watchlistItems.map((item) => item.id).toList();
  }

  bool isInWatchlist(String id) {
    return _watchlistService?.isInWatchlist(id) ?? false;
  }

  void toggleWatchlist(dynamic item) {
    if (_watchlistService == null) return;
    
    // Handle both SpotPriceModel and MetalPriceEntry if needed
    // Assuming UI passes the model or ID
    String id;
    String symbol;
    String name;
    double price;
    double change;
    double changePercent;
    
    if (item is SpotPriceModel) {
      id = item.id;
      symbol = item.symbol;
      name = item.metalName;
      price = item.price;
      change = item.change;
      changePercent = item.changePercent;
    } else {
      // Fallback
      return;
    }

    if (_watchlistService!.isInWatchlist(id)) {
      _watchlistService!.removeFromWatchlist(id);
    } else {
      // Use WatchlistItemModel.fromSpot if available or generic
      _watchlistService!.addToWatchlist(
        WatchlistItemModel(
          id: id,
          symbol: symbol,
          name: name,
          exchange: 'Spot',
          price: price,
          change: change,
          changePercent: changePercent,
          currency: 'INR',
          type: 'SPOT',
          lastUpdated: DateTime.now(),
        ),
      );
    }
    // Update trigger handled by listener
  }

  @override
  void onClose() {
    _dataSubscription?.cancel();
    _autoRefreshTimer?.cancel();
    super.onClose();
  }
}
