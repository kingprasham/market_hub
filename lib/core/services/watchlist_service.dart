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
  /// Add item to watchlist
  Future<bool> addToWatchlist(WatchlistItemModel item, {bool overwritePrice = true}) async {
    // Check if already exists (Match by ID first, then by Symbol + Type)
    final index = watchlistItems.indexWhere((i) {
      if (i.id == item.id) return true;
      return i.symbol == item.symbol && i.itemType.toLowerCase() == item.itemType.toLowerCase();
    });

    if (index != -1) {
      debugPrint('WatchlistService: Item ${item.symbol} (${item.itemType}) already in watchlist');
      if (overwritePrice) {
        final old = watchlistItems[index];
        // Update price and metadata if requested
        watchlistItems[index] = old.copyWith(
          price: item.price ?? old.price,
          change: item.change ?? old.change,
          changePercent: item.changePercent ?? old.changePercent,
          lastUpdated: DateTime.now(),
        );
        await _saveToLocalStorage();
      }
      return false;
    }

    watchlistItems.add(item);
    await _saveToLocalStorage();
    debugPrint('WatchlistService: Added ${item.symbol} to watchlist');
    return true;
  }

  /// Remove item from watchlist
  Future<void> removeFromWatchlist(String id) async {
    watchlistItems.removeWhere((item) => item.id == id);

    // Also remove from starred
    starredItemIds.remove(id);

    await Future.wait([
      _saveToLocalStorage(),
      _saveStarredItems(),
    ]);
    debugPrint('WatchlistService: Removed $id from watchlist');
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
  bool isInWatchlist(String id) {
    return watchlistItems.any((item) => item.id == id);
  }

  /// Get all starred watchlist items
  List<WatchlistItemModel> get starredItems {
    return watchlistItems
        .where((item) => starredItemIds.contains(item.id) || starredItemIds.contains(item.symbol))
        .toList();
  }

  /// Set price alert for an item
  Future<void> setAlert({
    required String id,
    required double alertPrice,
    required String alertType,
  }) async {
    final index = watchlistItems.indexWhere((item) => item.id == id);

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
  Future<void> removeAlert(String id) async {
    final index = watchlistItems.indexWhere((item) => item.id == id);

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
    String? itemType,
    double? price,
    double? change,
    double? changePercent,
    DateTime? timestamp,
  }) {
    bool hasChanges = false;
    final now = timestamp ?? DateTime.now();

    for (int i = 0; i < watchlistItems.length; i++) {
      final item = watchlistItems[i];
      final matchesSymbol = item.symbol.toUpperCase() == symbol.toUpperCase();
      if (!matchesSymbol) continue;

      bool matchesType = true;
      if (itemType != null) {
        final normalizedChannel = itemType.toLowerCase();
        final normalizedItemType = item.itemType.toLowerCase();
        
        matchesType = normalizedItemType == normalizedChannel;
        
        if (!matchesType) {
          // Handle "future" wildcard
          if (normalizedItemType == 'future' && 
              (normalizedChannel == 'lme' || normalizedChannel == 'shfe' || normalizedChannel == 'china' || normalizedChannel == 'london' || normalizedChannel == 'comex')) {
            matchesType = true;
          }
          // Handle exchange aliases
          else if (normalizedChannel == 'london' && normalizedItemType == 'lme') matchesType = true;
          else if (normalizedChannel == 'lme' && normalizedItemType == 'london') matchesType = true;
          else if (normalizedChannel == 'china' && normalizedItemType == 'shfe') matchesType = true;
          else if (normalizedChannel == 'shfe' && normalizedItemType == 'china') matchesType = true;
        }
      }

      if (matchesType) {
        watchlistItems[i] = item.copyWith(
          price: price ?? item.price,
          change: change ?? item.change,
          changePercent: changePercent ?? item.changePercent,
          lastUpdated: now,
        );
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _saveToLocalStorage();
    }
  }

  /// Update price for a specific watchlist item by its ID
  void updatePriceById({
    required String id,
    double? price,
    double? change,
    double? changePercent,
    DateTime? timestamp,
  }) {
    bool hasChanges = false;
    final now = timestamp ?? DateTime.now();

    for (int i = 0; i < watchlistItems.length; i++) {
      final item = watchlistItems[i];
      bool matches = item.id == id;
      
      if (!matches && id.contains('_')) {
        final parts = id.split('_');
        final exchange = parts[0].toLowerCase();
        final symbolPart = parts.length > 1 ? parts[1].toUpperCase() : '';
        
        final matchesSymbol = item.symbol.toUpperCase() == symbolPart;
        
        final normalizedItemType = item.itemType.toLowerCase();
        bool matchesType = normalizedItemType == exchange;
        
        if (!matchesType) {
          if (exchange == 'lme' && normalizedItemType == 'london') matchesType = true;
          if (exchange == 'london' && normalizedItemType == 'lme') matchesType = true;
          if (exchange == 'shfe' && normalizedItemType == 'china') matchesType = true;
          if (exchange == 'china' && normalizedItemType == 'shfe') matchesType = true;
          if (normalizedItemType == 'future' && (exchange == 'lme' || exchange == 'shfe' || exchange == 'comex')) matchesType = true;
        }
                             
        matches = matchesSymbol && matchesType;
      }

      if (matches) {
        if (item.price != price || item.change != change || item.changePercent != changePercent) {
          watchlistItems[i] = item.copyWith(
            price: price ?? item.price,
            change: change ?? item.change,
            changePercent: changePercent ?? item.changePercent,
            lastUpdated: now,
          );
          hasChanges = true;
        }
      }
    }

    if (hasChanges) {
      _saveToLocalStorage();
    }
  }

  /// Update multiple prices at once (for batch syncing from controllers)
  void batchUpdatePrices(List<WatchlistItemModel> updatedItems) {
    bool hasChanges = false;
    for (final updated in updatedItems) {
      final index = watchlistItems.indexWhere((item) {
        // Preference 1: ID Match (Safest)
        if (item.id == updated.id) return true;
        
        // Preference 2: Symbol + Exchange Type Match
        final matchesSymbol = item.symbol == updated.symbol;
        final matchesType = item.itemType.toLowerCase() == updated.itemType.toLowerCase();
        
        return matchesSymbol && matchesType;
      });
      
      if (index != -1) {
        final old = watchlistItems[index];
        // Only update if price actually changed
        if (old.price != updated.price || 
            old.change != updated.change || 
            old.changePercent != updated.changePercent) {
          watchlistItems[index] = old.copyWith(
            price: updated.price ?? old.price,
            change: updated.change ?? old.change,
            changePercent: updated.changePercent ?? old.changePercent,
            lastUpdated: updated.lastUpdated ?? DateTime.now(),
          );
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
