import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../storage/local_storage.dart';

enum MarketType { lme, comex, china }

class MarketSessionService extends GetxService {
  // Closing times (IST)
  static const lmeClosingTime = TimeOfDay(hour: 1, minute: 30);
  static const comexClosingTime = TimeOfDay(hour: 2, minute: 30);
  static const chinaClosingTime = TimeOfDay(hour: 23, minute: 0);

  static const String _refPricePrefix = 'market_ref_price_';

  /// Calculate change and percentage based on a custom reference price, with fallback to scraper values
  Map<String, double> calculateChange(
      double defaultChange, double defaultPercent,
      MarketType type, String symbol, double currentPrice, double? scraperPrevClose) {
    final refPrice = _getReferencePrice(type, symbol) ?? scraperPrevClose ?? currentPrice;
    
    if (refPrice == 0 || refPrice == currentPrice) {
      return {'change': defaultChange, 'percent': defaultPercent};
    }
    
    final change = currentPrice - refPrice;
    final percent = (change / refPrice) * 100;
    
    return {
      'change': change,
      'percent': percent,
    };
  }

  /// Store the current price as the reference price if we are within the closing window
  void updateReferencePrice(MarketType type, String symbol, double currentPrice) {
    if (currentPrice <= 0) return;

    final now = DateTime.now();
    final closingTime = _getClosingTime(type);
    
    // Define a window (e.g., 5 minutes after closing) to capture the "Close"
    final closingToday = DateTime(now.year, now.month, now.day, closingTime.hour, closingTime.minute);
    
    // If it's early morning (before 3 AM) and we are looking at LME/Comex, 
    // the closing price might be from "today's" early hours.
    // Otherwise, it might be from yesterday.
    
    // For simplicity, if we are within 15 minutes of the closing time, capture it.
    final diff = now.difference(closingToday).inMinutes;
    
    if (diff >= 0 && diff <= 15) {
      debugPrint('🕒 [MarketSessionService] Capturing Close for $type $symbol: $currentPrice');
      _saveReferencePrice(type, symbol, currentPrice);
    }
  }

  TimeOfDay _getClosingTime(MarketType type) {
    switch (type) {
      case MarketType.lme: return lmeClosingTime;
      case MarketType.comex: return comexClosingTime;
      case MarketType.china: return chinaClosingTime;
    }
  }

  double? _getReferencePrice(MarketType type, String symbol) {
    final key = '$_refPricePrefix${type.name}_$symbol';
    return LocalStorage.getCachedData(key) as double?;
  }

  void _saveReferencePrice(MarketType type, String symbol, double price) {
    final key = '$_refPricePrefix${type.name}_$symbol';
    LocalStorage.cacheData(key, price);
  }
}
