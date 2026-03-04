import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' as parser;
import 'fx678_scraper_service.dart';

class TradingEconomicsScraperService extends GetxService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    },
  ));

  /// Map of allowed TradingEconomics names mapped back to standard symbols.
  /// Trading Economics table rows have titles like "EURUSD", "GBPUSD", "USDJPY", "USDCNY", "USDINR", "DXY".
  static const _allowedSymbols = {
    'EURUSD': 'eur_usd',
    'GBPUSD': 'gbp_usd',
    'USDJPY': 'usd_jpy',
    'USDCNY': 'usd_cny',
    'USDINR': 'usd_inr',
    'DXY': 'dxy',
  };

  /// Fetches real-time FX data from tradingeconomics.com/currencies
  Future<List<ScrapedMetal>> fetchFX() async {
    final results = <ScrapedMetal>[];
    try {
      final response = await _dio.get('https://tradingeconomics.com/currencies');

      if (response.statusCode == 200) {
        final document = parser.parse(response.data);
        final tables = document.querySelectorAll('table');
        
        for (final table in tables) {
          final rows = table.querySelectorAll('tr');
          for (final row in rows) {
            final cells = row.querySelectorAll('td, th');
            if (cells.length >= 5) {
              // The first cell might be empty (flag), the second cell contains the name
              final rawName = cells[1].text.trim().toUpperCase();
              
              if (_allowedSymbols.containsKey(rawName)) {
                final symbol = _allowedSymbols[rawName]!;
                
                // Index 1: Name, Index 2: Price, Index 3: Change, Index 4: Change%
                final priceText = cells[2].text.trim().replaceAll(',', '');
                final price = double.tryParse(priceText) ?? 0.0;

                final changeText = cells[3].text.trim().replaceAll(',', '');
                final change = double.tryParse(changeText) ?? 0.0;

                final changePctText = cells[4].text.trim().replaceAll('%', '').replaceAll(',', '');
                final changePercent = double.tryParse(changePctText) ?? 0.0;

                results.add(ScrapedMetal(
                  name: rawName,
                  symbol: symbol,
                  price: price,
                  change: change,
                  changePercent: changePercent,
                  exchange: 'TradingEconomics',
                ));
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('TradingEconomicsScraperService FX error: $e');
    }
    return results;
  }
}
