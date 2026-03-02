import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/watchlist_service.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/watchlist/watchlist_item_model.dart';
import '../../future/controller/future_controller.dart';
import '../../spot_price/controller/spot_price_controller.dart';

class WatchlistController extends GetxController {
  late WatchlistService _watchlistService;

  final isLoading = true.obs;
  final isEditing = false.obs;
  final isRefreshing = false.obs;
  final searchQuery = ''.obs;
  final selectedFilter = 'All'.obs;
  final watchlistUpdateTrigger = 0.obs; // Trigger to force UI updates

  StreamSubscription? _dataSubscription;
  WebSocketService? _wsService;

  final filters = ['All', 'Future', 'Spot'];

  @override
  void onInit() {
    super.onInit();
    _initService();
    _subscribeToRealTimeUpdates();
  }

  Future<void> _initService() async {
    try {
      _watchlistService = Get.find<WatchlistService>();
    } catch (e) {
      // Initialize if not registered
      _watchlistService = await Get.putAsync(() => WatchlistService().init());
    }
    // Listen to watchlist changes and trigger UI updates
    ever(_watchlistService.watchlistItems, (_) => watchlistUpdateTrigger.value++);
    ever(_watchlistService.starredItemIds, (_) => watchlistUpdateTrigger.value++);
    await fetchWatchlist();
    _startAutoRefresh();
  }

  /// Start auto-refresh timer (15 seconds) to sync with other controllers
  void _startAutoRefresh() {
    Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!isLoading.value && !isRefreshing.value) {
        _syncWithMainControllers();
      }
    });
  }

  /// Sync watchlist items with latest data from Future and Spot controllers
  void _syncWithMainControllers() {
    try {
      final updatedItems = <WatchlistItemModel>[];
      
      // Sync with FutureController
      if (Get.isRegistered<FutureController>()) {
        final futureController = Get.find<FutureController>();
        _syncFutures(futureController, updatedItems);
      }
      
      // Sync with SpotPriceController
      if (Get.isRegistered<SpotPriceController>()) {
        final spotController = Get.find<SpotPriceController>();
        _syncSpots(spotController, updatedItems);
      }
      
      if (updatedItems.isNotEmpty) {
        _watchlistService.batchUpdatePrices(updatedItems);
      }
    } catch (e) {
      debugPrint('WatchlistController: Error syncing with controllers: $e');
    }
  }

  void _syncFutures(FutureController controller, List<WatchlistItemModel> updated) {
    // Controller is actually FutureController - using dynamic to avoid strict import if needed but I'll use imports
    for (final item in watchlistItems) {
      if (!item.isFuture) continue;
      
      // Look for symbol in LME, SHFE, COMEX, FX
      dynamic found;
      
      // Search LME
      found = controller.lmeData.firstWhereOrNull((d) => d.symbol == item.symbol);
      if (found != null) {
        updated.add(item.copyWith(
          price: found.price,
          change: found.change,
          changePercent: found.changePercent,
        ));
        continue;
      }
      
      // Search SHFE
      found = controller.shfeData.firstWhereOrNull((d) => d.symbol == item.symbol);
      if (found != null) {
        updated.add(item.copyWith(
          price: found.price,
          change: found.change,
          changePercent: found.changePercent,
        ));
        continue;
      }
      
      // Search COMEX
      found = controller.comexData.firstWhereOrNull((d) => d.symbol == item.symbol);
      if (found != null) {
        updated.add(item.copyWith(
          price: found.price,
          change: found.change,
          changePercent: found.changePercent,
        ));
        continue;
      }
      
      // Search FX
      found = controller.fxData.firstWhereOrNull((d) => d.pair == item.symbol);
      if (found != null) {
        updated.add(item.copyWith(
          price: found.rate,
          change: found.change,
          changePercent: found.changePercent,
        ));
      }
    }
  }

  void _syncSpots(SpotPriceController controller, List<WatchlistItemModel> updated) {
    for (final item in watchlistItems) {
      if (!item.isSpot) continue;
      
      // Search in baseMetalPrices and bmePrices
      final found = [...controller.baseMetalPrices, ...controller.bmePrices]
          .firstWhereOrNull((p) => p.symbol == item.symbol || p.id == item.id);
          
      if (found != null) {
        updated.add(item.copyWith(
          price: found.price,
          change: found.change,
          changePercent: found.changePercent,
        ));
      }
    }
  }

  /// Get watchlist items from service
  List<WatchlistItemModel> get watchlistItems => _watchlistService.watchlistItems;

  /// Get starred item IDs from service
  Set<String> get starredItemIds => _watchlistService.starredItemIds;

  /// Get filtered watchlist items (Strictly starred items only)
  List<WatchlistItemModel> get filteredItems {
    // Only show starred items as requested
    var items = watchlistItems.where((item) => isStarred(item.id) || isStarred(item.symbol)).toList();

    // Apply filter
    if (selectedFilter.value != 'All') {
      final filterType = selectedFilter.value.toUpperCase();
      
      items = items.where((item) {
        final itemType = (item.type ?? item.itemType).toUpperCase();
        
        if (filterType == 'FUTURE') {
          return itemType == 'LME' || 
                 itemType == 'LONDON' || 
                 itemType == 'SHFE' || 
                 itemType == 'CHINA' || 
                 itemType == 'COMEX' ||
                 itemType == 'FUTURE';
        } else if (filterType == 'SPOT') {
          return itemType == 'SPOT';
        }
        
        return false;
      }).toList();
    }

    // Apply search
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      items = items.where((item) =>
        item.name.toLowerCase().contains(query) ||
        item.symbol.toLowerCase().contains(query)
      ).toList();
    }

    return items;
  }

  /// Get starred items only
  List<WatchlistItemModel> get starredItems => _watchlistService.starredItems;

  void _subscribeToRealTimeUpdates() {
    try {
      _wsService = Get.find<WebSocketService>();
      _subscribeToWatchlistChannels();

      _dataSubscription = _wsService!.dataStream.listen((update) {
        _handleChannelUpdate(update);
      });
    } catch (e) {
      // WebSocket not initialized
    }
  }

  void _subscribeToWatchlistChannels() {
    if (_wsService == null) return;

    final channels = <String>{};
    for (final item in watchlistItems) {
      final itemType = (item.type ?? item.itemType).toLowerCase();
      switch (itemType) {
        case 'lme':
        case 'london':
          channels.add('lme');
          break;
        case 'shfe':
        case 'china':
          channels.add('shfe');
          break;
        case 'comex':
          channels.add('comex');
          break;
        case 'fx':
          channels.add('fx');
          break;
        case 'spot':
          channels.add('spot');
          break;
        case 'future':
          channels.add('lme');
          channels.add('shfe');
          channels.add('comex');
          break;
      }
    }

    for (final channel in channels) {
      _wsService!.subscribe(channel);
    }
  }

  void _handleChannelUpdate(MarketUpdate update) {
    if (update.payload is! Map<String, dynamic>) return;
    final data = update.payload as Map<String, dynamic>;

    final symbol = data['symbol'] ?? data['pair'];
    if (symbol == null) return;

    _watchlistService.updatePrice(
      symbol: symbol.toString(),
      price: data['price']?.toDouble() ?? data['rate']?.toDouble(),
      change: data['change']?.toDouble(),
      changePercent: data['changePercent']?.toDouble(),
    );
  }

  Future<void> fetchWatchlist() async {
    isLoading.value = true;

    try {
      final response = await ApiClient().get(ApiConstants.watchlist);

      if (response.data != null && response.data['success'] == true) {
        final data = (response.data['data'] as List)
            .map((json) => WatchlistItemModel.fromJson(json))
            .toList();

        // Add items to service and sync starred status
        for (final item in data) {
          await _watchlistService.addToWatchlist(item);
          // Sync starred status from API
          if (item.isStarred && !isStarred(item.id)) {
            await _watchlistService.toggleStar(item.id);
          }
        }
      }
    } catch (e) {
      // API failed - use local persisted data only (no demo data)
      debugPrint('API fetch failed, using locally persisted watchlist data');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshWatchlist() async {
    isRefreshing.value = true;
    await fetchWatchlist();
    _subscribeToWatchlistChannels();
    isRefreshing.value = false;
  }

  /// Add item to watchlist
  Future<bool> addToWatchlist(WatchlistItemModel item) async {
    final success = await _watchlistService.addToWatchlist(item);

    if (success) {
      try {
        await ApiClient().post(
          ApiConstants.addWatchlist,
          data: item.toJson(),
        );
      } catch (e) {
        // API failed but item is saved locally
      }
      
      // Auto-star when adding as requested by user
      if (!isStarred(item.id)) {
        await toggleStar(item.id);
      }
      
      _subscribeToWatchlistChannels();
      Helpers.showSuccess('Added to watchlist');
      return true;
    } else {
      // If already in list but not starred, find the existing one and star it
      final existing = watchlistItems.firstWhereOrNull(
        (i) => i.id == item.id || i.symbol == item.symbol
      );
      final idToStar = existing?.id ?? item.id;

      if (!isStarred(idToStar)) {
        await toggleStar(idToStar);
        Helpers.showSuccess('Added to watchlist');
        return true;
      }
      
      Helpers.showError('Already in watchlist');
      return false;
    }
  }

  /// Remove item from watchlist
  Future<void> removeFromWatchlist(String idOrSymbol) async {
    try {
      await ApiClient().delete('${ApiConstants.removeWatchlist}/$idOrSymbol');
    } catch (e) {
      // Continue with local removal even if API fails
    }

    await _watchlistService.removeFromWatchlist(idOrSymbol);
    Helpers.showSuccess('Removed from watchlist');
  }

  /// Toggle star for an item
  Future<void> toggleStar(String itemId) async {
    await _watchlistService.toggleStar(itemId);
    if (_watchlistService.isStarred(itemId)) {
      Helpers.showSuccess('Added to starred');
    } else {
      Helpers.showSuccess('Removed from starred');
    }
  }

  /// Check if item is starred
  bool isStarred(String itemId) {
    return _watchlistService.isStarred(itemId);
  }

  /// Check if item is in watchlist
  bool isInWatchlist(String idOrSymbol) {
    return _watchlistService.isInWatchlist(idOrSymbol);
  }

  /// Reorder watchlist items
  void reorderWatchlist(int oldIndex, int newIndex) {
    _watchlistService.reorderItems(oldIndex, newIndex);
  }

  /// Toggle edit mode
  void toggleEditMode() {
    isEditing.value = !isEditing.value;
  }

  /// Set alert for a watchlist item
  Future<void> setAlert({
    required String idOrSymbol,
    required double alertPrice,
    required String alertType,
  }) async {
    await _watchlistService.setAlert(
      idOrSymbol: idOrSymbol,
      alertPrice: alertPrice,
      alertType: alertType,
    );
    Helpers.showSuccess('Alert set successfully');
  }

  /// Remove alert from a watchlist item
  Future<void> removeAlert(String idOrSymbol) async {
    await _watchlistService.removeAlert(idOrSymbol);
    Helpers.showSuccess('Alert removed');
  }

  /// Update filter
  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  /// Update search query
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Get watchlist item count
  int get itemCount => watchlistItems.length;

  /// Get starred item count
  int get starredCount => _watchlistService.starredCount;

  @override
  void onClose() {
    _dataSubscription?.cancel();
    super.onClose();
  }
}
