import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'fx678_scraper_service.dart';

class JijinhaoScraperService extends GetxService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Referer': 'https://www.quheqihuo.com/',
    },
  ));

  /// Fetches real-time COMEX data from api.jijinhao.com
  Future<List<ScrapedMetal>> fetchCOMEX() async {
    try {
      const codes = 'JO_12553,JO_108893,JO_108878,JO_12552,JO_50814';
      final response = await _dio.get(
        'https://api.jijinhao.com/quoteCenter/realTime.htm',
        queryParameters: {'codes': codes},
      );

      if (response.statusCode == 200) {
        return _parseQuoteJson(response.data);
      }
    } catch (e) {
      debugPrint('JijinhaoScraperService COMEX error: $e');
    }
    return [];
  }

  List<ScrapedMetal> _parseQuoteJson(String rawData) {
    final results = <ScrapedMetal>[];
    try {
      String jsonStr = rawData.trim();
      if (jsonStr.startsWith('var quote_json = ')) {
        jsonStr = jsonStr.replaceFirst('var quote_json = ', '');
      }
      if (jsonStr.endsWith(';')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 1);
      }

      final Map<String, dynamic> data = _tryParseJson(jsonStr);

      // Code → (English name, symbol, exchange)
      const codeMap = {
        'JO_12552': ('Gold', 'GC', 'COMEX'),
        'JO_12553': ('Silver', 'SI', 'COMEX'),
        'JO_50814': ('Copper', 'HG', 'COMEX'),
        'JO_108878': ('WTI Crude Oil', 'CL', 'NYMEX'),
        'JO_108893': ('Brent Crude Oil', 'OIL', 'ICE'),
      };

      for (final entry in codeMap.entries) {
        final key = entry.key;
        final info = entry.value;
        if (data.containsKey(key)) {
          final item = data[key];
          
          results.add(ScrapedMetal(
            exchange: info.$3,
            symbol: info.$2,
            name: info.$1,
            price: _parseDouble(item['q63']),
            change: _parseDouble(item['q70']),
            changePercent: _parseDouble(item['q80']),
            open: _parseDouble(item['q1']),
            high: _parseDouble(item['q3']),
            low: _parseDouble(item['q4']),
            prev: _parseDouble(item['q64']), 
          ));
        }
      }
    } catch (e) {
      debugPrint('Jijinhao parsing error: $e');
    }
    return results;
  }

  Map<String, dynamic> _tryParseJson(String source) {
    try {
      return jsonDecode(source) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JSON Decode failed: $e');
      return {};
    }
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) {
      return double.tryParse(val) ?? 0.0;
    }
    return 0.0;
  }
}
