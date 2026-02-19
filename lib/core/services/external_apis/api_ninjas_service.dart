import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../../config/api_keys.dart';

/// Service to fetch real-time commodity prices from API Ninjas
/// 
/// Provides:
/// - COMEX commodities (Gold, Silver, Platinum)
/// 
/// Free tier: 10,000 requests/month
/// API Docs: https://api-ninjas.com/api/commodityprice
class ApiNinjasService extends GetxService {
  static const String _baseUrl = 'https://api.api-ninjas.com/v1';
  
  late Dio _dio;
  
  // Cache to minimize API calls
  final Map<String, _CachedPrice> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  Future<ApiNinjasService> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'X-Api-Key': ApiKeys.apiNinjasApiKey,
      },
    ));
    return this;
  }
  
  /// Fetch price for a specific commodity
  /// 
  /// [name] - Commodity name (platinum, palladium, etc.)
  /// NOTE: API Ninjas uses specific commodity names
  Future<Map<String, dynamic>?> getCommodityPrice(String name) async {
    if (!ApiKeys.isApiNinjasConfigured) {
      debugPrint('⚠️ API Ninjas key not configured');
      return null;
    }
    
    // Check cache
    final cached = _cache[name];
    if (cached != null && DateTime.now().difference(cached.fetchTime) < _cacheExpiry) {
      return cached.data;
    }
    
    try {
      final response = await _dio.get(
        '/commodityprice',
        queryParameters: {'name': name},
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _cache[name] = _CachedPrice(data, DateTime.now());
        debugPrint('✅ API Ninjas: Fetched $name price - ${data['price']}');
        return data;
      }
    } on DioException catch (e) {
      debugPrint('❌ API Ninjas DioException for $name: ${e.response?.statusCode} - ${e.response?.data}');
    } catch (e) {
      debugPrint('❌ API Ninjas error for $name: $e');
    }
    
    return null;
  }
  
  /// Fetch COMEX prices
  /// API Ninjas only supports: platinum
  /// gold, silver, copper return 400 errors (not supported)
  Future<List<Map<String, dynamic>>> getComexPrices() async {
    // Only platinum works on API Ninjas for precious metals
    final commodities = ['platinum'];
    final List<Map<String, dynamic>> prices = [];
    
    for (final commodity in commodities) {
      final price = await getCommodityPrice(commodity);
      if (price != null) {
        prices.add({
          ...price,
          'commodity': commodity,
        });
      }
    }
    
    return prices;
  }
}

class _CachedPrice {
  final Map<String, dynamic> data;
  final DateTime fetchTime;
  
  _CachedPrice(this.data, this.fetchTime);
}
