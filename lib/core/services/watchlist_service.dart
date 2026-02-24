import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../storage/local_storage.dart';
import '../../data/models/watchlist/watchlist_item_model.dart';

/// Centralized WatchlistService for managing starred/favorite items
/// Provides local persistence using Hive and real-time sync across the app
class WatchlistService extends GetxService {
  static const String _watchlistCacheKey = 'watchlist_items';
  static const String _starredItemsKey = 'starred_items';

  final watchlistItems = <WatchlistItemModel>[].obs;
  final starredItemIds = <String>{}.obs;
  final isLoading = false.obs;

  /// Initialize the service and load persisted data
  Future<WatchlistService> init() async {
    await _loadFromLocalStorage();
    await _loadStarredItems();
    return this;
  }

  /// Load watchlist from local storage
  Future<void> _loadFromLocalStorage() async {
    try {
      final cachedData = LocalStorage.getCachedData(_watchlistCacheKey);
      if (cachedData != null && cachedData is List) {
        final items = cachedData.map((json) {
          if (json is Map) {
            return WatchlistItemModel.fromJson(Map<String, dynamic>.from(json));
          }
          return null;
        }).whereType<WatchlistItemModel>().toList();

        if (items.isNotEmpty) {
          watchlistItems.assignAll(items);
          debugPrint('WatchlistService: Loaded ${items.length} items from local storage');
        }
      }
    } catch (e) {
      debugPrint('WatchlistService: Error loading from local storage: $e');
    }
  }

  /// Load starred item IDs from local storage
  Future<void> _loadStarredItems() async {
    try {
      final cachedData = LocalStorage.getCachedData(_starredItemsKey);
      if (cachedData != null && cachedData is List) {
        starredItemIds.assignAll(cachedData.cast<String>().toSet());
        debugPrint('WatchlistService: Loaded ${starredItemIds.length} starred items');
      }
    } catch (e) {
      debugPrint('WatchlistService: Error loading starred items: $e');
    }
  }

  /// Save watchlist to local storage
  Future<void> _saveToLocalStorage() async {
    try {
      final data = watchlistItems.map((item) => item.toJson()).toList();
      await LocalStorage.cacheData(_watchlistCacheKey, data);
    } catch (e) {
      debugPrint('WatchlistService: Error saving to local storage: $e');
    }
  }

  /// Save starred items to local storage
  Future<void> _saveStarredItems() async {
    try {
      await LocalStorage.cacheData(_starredItemsKey, starredItemIds.toList());
    } catch (e) {
      debugPrint('WatchlistService: Error saving starred items: $e');
    }
  }

  /// Add item to watchlist
  Future<bool> addToWatchlist(WatchlistItemModel item) async {
    // Check if already exists
    if (watchlistItems.any((i) => i.id == item.id || i.symbol == item.symbol)) {
      debugPrint('WatchlistService: Item ${item.symbol} already in watchlist');
      return false;
    }

    watchlistItems.add(item);
    await _saveToLocalStorage();
    debugPrint('WatchlistService: Added ${item.symbol} to watchlist');
    return true;
  }

  /// Remove item from watchlist
  Future<void> removeFromWatchlist(String idOrSymbol) async {
    watchlistItems.removeWhere((item) =>
      item.id == idOrSymbol || item.symbol == idOrSymbol);

    // Also remove from starred
    starredItemIds.remove(idOrSymbol);

    await Future.wait([
      _saveToLocalStorage(),
      _saveStarredItems(),
    ]);
    debugPrint('WatchlistService: Removed $idOrSymbol from watchlist');
  }

  /// Update an existing watchlist item
  Future<void> updateWatchlistItem(WatchlistItemModel updatedItem) async {
    final index = watchlistItems.indexWhere((item) =>
      item.id == updatedItem.id || item.symbol == updatedItem.symbol);

    if (index != -1) {
      watchlistItems[index] = updatedItem;
      await _saveToLocalStorage();
      debugPrint('WatchlistService: Updated ${updatedItem.symbol}');
    }
  }

  /// Toggle star status for an item
  Future<void> toggleStar(String itemId) async {
    if (starredItemIds.contains(itemId)) {
      starredItemIds.remove(itemId);
      debugPrint('WatchlistService: Unstarred $itemId');
    } else {
      starredItemIds.add(itemId);
      debugPrint('WatchlistService: Starred $itemId');
    }
    await _saveStarredItems();
  }

  /// Check if an item is starred
  bool isStarred(String itemId) {
    return starredItemIds.contains(itemId);
  }

  /// Check if an item is in watchlist
  bool isInWatchlist(String idOrSymbol) {
    return watchlistItems.any((item) =>
      item.id == idOrSymbol || item.symbol == idOrSymbol);
  }

  /// Get all starred watchlist items
  List<WatchlistItemModel> get starredItems {
    return watchlistItems
        .where((item) => starredItemIds.contains(item.id) || starredItemIds.contains(item.symbol))
        .toList();
  }

  /// Set price alert for an item
  Future<void> setAlert({
    required String idOrSymbol,
    required double alertPrice,
    required String alertType,
  }) async {
    final index = watchlistItems.indexWhere((item) =>
      item.id == idOrSymbol || item.symbol == idOrSymbol);

    if (index != -1) {
      final old = watchlistItems[index];
      watchlistItems[index] = old.copyWith(
        alertEnabled: true,
        alertPrice: alertPrice,
        alertType: alertType,
      );
      await _saveToLocalStorage();
      debugPrint('WatchlistService: Set alert for ${old.symbol}');
    }
  }

  /// Remove alert from an item
  Future<void> removeAlert(String idOrSymbol) async {
    final index = watchlistItems.indexWhere((item) =>
      item.id == idOrSymbol || item.symbol == idOrSymbol);

    if (index != -1) {
      final old = watchlistItems[index];
      watchlistItems[index] = old.copyWith(
        alertEnabled: false,
        alertPrice: null,
        alertType: null,
      );
      await _saveToLocalStorage();
      debugPrint('WatchlistService: Removed alert for ${old.symbol}');
    }
  }

  /// Update price for a watchlist item (from WebSocket updates)
  void updatePrice({
    required String symbol,
    double? price,
    double? change,
    double? changePercent,
  }) {
    final index = watchlistItems.indexWhere((item) =>
      item.symbol == symbol || item.symbol.contains(symbol));

    if (index != -1) {
      final old = watchlistItems[index];
      watchlistItems[index] = old.copyWith(
        price: price ?? old.price,
        change: change ?? old.change,
        changePercent: changePercent ?? old.changePercent,
        lastUpdated: DateTime.now(),
      );
      // Don't await to avoid blocking WebSocket updates
      _saveToLocalStorage();
    }
  }

  /// Update multiple prices at once (for batch syncing from controllers)
  void batchUpdatePrices(List<WatchlistItemModel> updatedItems) {
    bool hasChanges = false;
    for (final updated in updatedItems) {
      final index = watchlistItems.indexWhere((item) => item.id == updated.id);
      if (index != -1) {
        final old = watchlistItems[index];
        // Only update if price actually changed or it's a forced sync
        if (old.price != updated.price || 
            old.change != updated.change || 
            old.changePercent != updated.changePercent) {
          watchlistItems[index] = updated.copyWith(lastUpdated: DateTime.now());
          hasChanges = true;
        }
      }
    }
    if (hasChanges) {
      _saveToLocalStorage();
    }
  }

  /// Reorder watchlist items
  void reorderItems(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = watchlistItems.removeAt(oldIndex);
    watchlistItems.insert(newIndex, item);
    _saveToLocalStorage();
  }

  /// Clear all watchlist items
  Future<void> clearAll() async {
    watchlistItems.clear();
    starredItemIds.clear();
    await Future.wait([
      _saveToLocalStorage(),
      _saveStarredItems(),
    ]);
    debugPrint('WatchlistService: Cleared all items');
  }

  /// Get items by type
  List<WatchlistItemModel> getItemsByType(String type) {
    return watchlistItems
        .where((item) => item.itemType.toLowerCase() == type.toLowerCase() ||
                         (item.type?.toLowerCase() ?? '') == type.toLowerCase())
        .toList();
  }

  /// Get watchlist items count
  int get itemCount => watchlistItems.length;

  /// Get starred items count
  int get starredCount => starredItemIds.length;
}
