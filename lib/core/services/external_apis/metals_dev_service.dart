import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../../config/api_keys.dart';

/// Service to fetch real-time metal prices from Metals.Dev API
/// 
/// Free tier: 100 requests/month, 60 second update frequency
/// API Docs: https://metals.dev/api
class MetalsDevService extends GetxService {
  static const String _baseUrl = 'https://api.metals.dev/v1';
  
  late Dio _dio;
  
  // Cache to minimize API calls
  Map<String, dynamic>? _cachedData;
  DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  Future<MetalsDevService> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    return this;
  }
  
  /// Fetch latest metal prices
  Future<Map<String, dynamic>?> getLatestPrices({String currency = 'USD'}) async {
    if (!ApiKeys.isMetalsDevConfigured) {
      debugPrint('⚠️ Metals.Dev API key not configured');
      return null;
    }
    
    // Return cached data if still valid
    if (_cachedData != null && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheExpiry) {
      debugPrint('📦 Metals.Dev: Using cached data');
      return _cachedData;
    }
    
    try {
      debugPrint('🔄 Metals.Dev: Fetching from API...');
      debugPrint('   URL: $_baseUrl/latest?api_key=${ApiKeys.metalsDevApiKey.substring(0, 8)}...&currency=$currency&unit=toz');
      
      final response = await _dio.get(
        '/latest',
        queryParameters: {
          'api_key': ApiKeys.metalsDevApiKey,
          'currency': currency,
          'unit': 'toz', // Troy ounce (default for precious metals)
        },
      );
      
      debugPrint('📡 Metals.Dev Response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data != null) {
        _cachedData = response.data;
        _lastFetchTime = DateTime.now();
        debugPrint('✅ Metals.Dev: Fetched latest prices - ${response.data}');
        return response.data;
      } else {
        debugPrint('❌ Metals.Dev: Bad response - ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ Metals.Dev DioException: ${e.type} - ${e.message}');
      if (e.response != null) {
        debugPrint('   Response: ${e.response?.statusCode} - ${e.response?.data}');
      }
    } catch (e) {
      debugPrint('❌ Metals.Dev error: $e');
    }
    
    return null;
  }
  
  /// Fetch precious metal prices
  Future<Map<String, double>> getPreciousMetalPrices({String currency = 'INR'}) async {
    final data = await getLatestPrices(currency: currency);
    if (data == null) return {};
    
    final metals = data['metals'] as Map<String, dynamic>?;
    if (metals == null) return {};
    
    final Map<String, double> prices = {};
    final preciousMetals = ['gold', 'silver', 'platinum', 'palladium'];
    
    for (final metal in preciousMetals) {
      if (metals.containsKey(metal)) {
        prices[metal] = (metals[metal] as num).toDouble();
      }
    }
    
    return prices;
  }
  
  /// Get base metal price in USD per metric ton
  Future<Map<String, double>> getBaseMetalPrices() async {
    final data = await getLatestPrices(currency: 'USD');
    if (data == null) return {};
    
    final metals = data['metals'] as Map<String, dynamic>?;
    if (metals == null) return {};
    
    final Map<String, double> prices = {};
    
    // For base metals, Metals.Dev returns price per troy oz
    // 1 metric ton = 32150.75 troy oz
    final basMetals = ['copper', 'aluminum', 'zinc', 'lead', 'nickel', 'tin'];
    
    for (final metal in basMetals) {
      if (metals.containsKey(metal)) {
        final pricePerOz = (metals[metal] as num).toDouble();
        // Convert to per metric ton
        prices[metal] = pricePerOz * 32150.75;
      }
    }
    
    return prices;
  }
}
