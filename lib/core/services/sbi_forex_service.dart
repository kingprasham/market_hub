import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/models/forex/sbi_forex_rate_model.dart';

/// Service to fetch SBI Forex/TT rates from GitHub repository
/// Data source: https://github.com/sahilgupta/sbi-fx-ratekeeper
class SbiForexService extends GetxService {
  final Dio _dio = Dio();

  // Base URL for CSV files
  static const String baseUrl =
      'https://raw.githubusercontent.com/sahilgupta/sbi-fx-ratekeeper/main/csv_files';

  // Cache for forex rates
  final _forexRatesCache = <String, List<SbiForexRateModel>>{}.obs;

  // Loading state per currency
  final _loadingStates = <String, bool>{}.obs;

  // Last update time per currency
  final _lastUpdateTimes = <String, DateTime>{};

  // Cache expiry duration (1 hour)
  static const Duration cacheExpiry = Duration(hours: 1);

  @override
  void onInit() {
    super.onInit();
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// Get forex rates for a specific currency
  Future<List<SbiForexRateModel>> getForexRates(String currencyCode) async {
    // Check cache first
    if (_isCacheValid(currencyCode)) {
      debugPrint('Using cached data for $currencyCode');
      return _forexRatesCache[currencyCode]!;
    }

    // Fetch from GitHub
    return await fetchForexRates(currencyCode);
  }

  /// Fetch forex rates from GitHub repository
  Future<List<SbiForexRateModel>> fetchForexRates(String currencyCode) async {
    try {
      _loadingStates[currencyCode] = true;

      final url = '$baseUrl/SBI_REFERENCE_RATES_$currencyCode.csv';
      debugPrint('Fetching forex rates from: $url');

      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'text/csv'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final csvData = response.data.toString();
        final rates = _parseCsvData(csvData, currencyCode);

        // Update cache
        _forexRatesCache[currencyCode] = rates;
        _lastUpdateTimes[currencyCode] = DateTime.now();

        debugPrint('Fetched ${rates.length} rates for $currencyCode');
        return rates;
      } else {
        throw Exception('Failed to fetch forex rates: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching forex rates for $currencyCode: $e');
      // Return cached data if available, otherwise empty list
      return _forexRatesCache[currencyCode] ?? [];
    } finally {
      _loadingStates[currencyCode] = false;
    }
  }

  /// Parse CSV data into SbiForexRateModel list
  List<SbiForexRateModel> _parseCsvData(String csvData, String currencyCode) {
    final lines = csvData.split('\n');
    final rates = <SbiForexRateModel>[];

    if (lines.isEmpty) return rates;

    // Skip header row (first line)
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final row = _parseCsvLine(line);
        if (row.length >= 10) {
          final rate = SbiForexRateModel.fromCsvRow(row, currencyCode);
          rates.add(rate);
        }
      } catch (e) {
        debugPrint('Error parsing CSV line $i: $e');
        // Continue parsing other lines
      }
    }

    // Sort by date descending (newest first)
    rates.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return rates;
  }

  /// Parse a single CSV line, handling quoted values
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = '';
    var inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }

    result.add(current.trim());
    return result;
  }

  /// Check if cache is valid for a currency
  bool _isCacheValid(String currencyCode) {
    if (!_forexRatesCache.containsKey(currencyCode)) return false;
    if (!_lastUpdateTimes.containsKey(currencyCode)) return false;

    final lastUpdate = _lastUpdateTimes[currencyCode]!;
    final now = DateTime.now();
    return now.difference(lastUpdate) < cacheExpiry;
  }

  /// Get latest rate for a currency
  SbiForexRateModel? getLatestRate(String currencyCode) {
    final rates = _forexRatesCache[currencyCode];
    if (rates == null || rates.isEmpty) return null;
    return rates.first; // Already sorted by date descending
  }

  /// Get rates for a specific date range
  List<SbiForexRateModel> getRatesForDateRange(
    String currencyCode,
    DateTime startDate,
    DateTime endDate,
  ) {
    final rates = _forexRatesCache[currencyCode];
    if (rates == null) return [];

    return rates.where((rate) {
      return rate.dateTime.isAfter(startDate) &&
          rate.dateTime.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get rates for last N days
  List<SbiForexRateModel> getRecentRates(String currencyCode, int days) {
    final rates = _forexRatesCache[currencyCode];
    if (rates == null) return [];

    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return rates.where((rate) => rate.dateTime.isAfter(cutoffDate)).toList();
  }

  /// Fetch multiple currencies at once
  Future<Map<String, List<SbiForexRateModel>>> fetchMultipleCurrencies(
    List<String> currencyCodes,
  ) async {
    final results = <String, List<SbiForexRateModel>>{};

    await Future.wait(
      currencyCodes.map((code) async {
        try {
          final rates = await getForexRates(code);
          results[code] = rates;
        } catch (e) {
          debugPrint('Error fetching $code: $e');
          results[code] = [];
        }
      }),
    );

    return results;
  }

  /// Clear cache for a specific currency
  void clearCache(String currencyCode) {
    _forexRatesCache.remove(currencyCode);
    _lastUpdateTimes.remove(currencyCode);
  }

  /// Clear all cache
  void clearAllCache() {
    _forexRatesCache.clear();
    _lastUpdateTimes.clear();
  }

  /// Check if loading for a currency
  bool isLoading(String currencyCode) {
    return _loadingStates[currencyCode] ?? false;
  }

  /// Get cached currencies
  List<String> get cachedCurrencies => _forexRatesCache.keys.toList();

  /// Get cache status
  Map<String, dynamic> getCacheStatus() {
    return {
      'cached_currencies': cachedCurrencies.length,
      'currencies': cachedCurrencies,
      'last_updates': _lastUpdateTimes.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
    };
  }

  @override
  void onClose() {
    _dio.close();
    super.onClose();
  }
}
