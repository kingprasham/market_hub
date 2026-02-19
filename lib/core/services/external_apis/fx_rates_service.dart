import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../../../data/models/market/fx_model.dart';

/// Service to fetch real-time forex rates
/// 
/// Uses Frankfurter.app - a free, open-source API (no key required)
/// API Docs: https://www.frankfurter.app/docs/
class FxRatesService extends GetxService {
  static const String _baseUrl = 'https://api.frankfurter.app';
  
  late Dio _dio;
  
  // Cache
  Map<String, dynamic>? _cachedRates;
  DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  Future<FxRatesService> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    return this;
  }
  
  /// Fetch live exchange rates from Frankfurter API
  Future<Map<String, dynamic>?> getLiveRates({
    String base = 'USD',
    List<String> symbols = const ['INR', 'EUR', 'GBP', 'JPY', 'CNY'],
  }) async {
    // Return cached data if still valid
    if (_cachedRates != null && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheExpiry) {
      return _cachedRates;
    }
    
    try {
      final response = await _dio.get(
        '/latest',
        queryParameters: {
          'from': base,
          'to': symbols.join(','),
        },
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _cachedRates = {
          'quotes': (data['rates'] as Map<String, dynamic>).map(
            (key, value) => MapEntry('$base$key', value),
          ),
          'source': base,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        _lastFetchTime = DateTime.now();
        debugPrint('✅ FX Rates: Fetched from Frankfurter API - ${data['rates']}');
        return _cachedRates;
      }
    } catch (e) {
      debugPrint('❌ Frankfurter API error: $e');
    }
    
    return null;
  }
  
  /// Get formatted FX rate models
  Future<List<FxModel>> getFxRates() async {
    final data = await getLiveRates();
    
    if (data == null) {
      debugPrint('❌ FX Rates: No data available from API');
      return [];
    }
    
    final quotes = data['quotes'] as Map<String, dynamic>?;
    if (quotes == null || quotes.isEmpty) return [];
    
    final now = DateTime.now();
    final List<FxModel> rates = [];
    
    quotes.forEach((pair, rate) {
      final baseCurrency = pair.substring(0, 3);
      final targetCurrency = pair.substring(3);
      final rateValue = (rate as num).toDouble();
      
      rates.add(FxModel(
        pair: '$baseCurrency/$targetCurrency',
        rate: rateValue,
        change: 0,
        changePercent: 0,
        bid: rateValue * 0.9999,
        ask: rateValue * 1.0001,
        high: rateValue * 1.005,
        low: rateValue * 0.995,
        lastUpdated: now,
        source: 'Live (Frankfurter)',
      ));
    });
    
    return rates;
  }
}
