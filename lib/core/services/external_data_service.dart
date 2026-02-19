import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../network/api_client.dart';
import '../../data/models/forex/forex_sheet_data.dart';

/// Service for fetching external data from various sources
/// - SBI TT Rates
/// - RBI Reference Rates
/// - Economic Calendar
/// - Trading Economics News
/// - Google Sheets Data
class ExternalDataService extends GetxService {
  final Dio _dio = Dio();

  // Cache for data
  final _sbiTTRatesCache = Rx<SbiTTRates?>(null);
  final _rbiRatesCache = Rx<List<RbiReferenceRate>>([]);
  final _economicEventsCache = Rx<List<EconomicEvent>>([]);
  final _liveNewsCache = Rx<List<LiveNewsItem>>([]);
  final _sheetsDataCache = Rx<Map<String, List<Map<String, dynamic>>>>({});
  final _forexSheetCache = Rxn<ForexSheetData>();

  // Loading states
  final isLoadingSbiRates = false.obs;
  final isLoadingRbiRates = false.obs;
  final isLoadingEconomicCalendar = false.obs;
  final isLoadingNews = false.obs;
  final isLoadingSheetsData = false.obs;

  // Last update times


  // Refresh intervals (in seconds)
  static const int sbiRefreshInterval = 300; // 5 minutes
  static const int rbiRefreshInterval = 300; // 5 minutes
  static const int economicRefreshInterval = 30; // 30 seconds
  static const int newsRefreshInterval = 60; // 1 minute

  // Timers for auto-refresh
  Timer? _sbiTimer;
  Timer? _rbiTimer;
  Timer? _economicTimer;
  Timer? _newsTimer;

  // Getters for Rx values (for use with ever/obs)
  Rx<SbiTTRates?> get sbiTTRates => _sbiTTRatesCache;
  Rx<List<RbiReferenceRate>> get rbiReferenceRatesRx => _rbiRatesCache;
  Rx<List<EconomicEvent>> get economicEventsRx => _economicEventsCache;
  Rx<List<LiveNewsItem>> get liveNewsRx => _liveNewsCache;

  // Getters for direct values
  SbiTTRates? get sbiTTRatesValue => _sbiTTRatesCache.value;
  List<RbiReferenceRate> get rbiRates => _rbiRatesCache.value;
  List<RbiReferenceRate> get rbiReferenceRates => _rbiRatesCache.value;
  List<EconomicEvent> get economicEvents => _economicEventsCache.value;
  List<LiveNewsItem> get liveNews => _liveNewsCache.value;
  Map<String, List<Map<String, dynamic>>> get sheetsData => _sheetsDataCache.value;
  ForexSheetData? get forexSheetData => _forexSheetCache.value;
  Rxn<ForexSheetData> get forexSheetDataRx => _forexSheetCache;

  @override
  void onInit() {
    super.onInit();
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'User-Agent': 'MarketHub/1.0',
    };
  }

  /// Initialize and start auto-refresh for all data sources
  Future<void> initialize() async {
    await Future.wait([
      fetchSbiTTRates(),
      fetchRbiReferenceRates(),
      fetchEconomicCalendar(),
      fetchLiveNews(),
    ]);

    _startAutoRefresh();
  }

  /// Alias for initialize - called from NavigationController
  Future<void> initializeAllServices() async {
    await initialize();
  }

  void _startAutoRefresh() {
    _sbiTimer?.cancel();
    _rbiTimer?.cancel();
    _economicTimer?.cancel();
    _newsTimer?.cancel();

    _sbiTimer = Timer.periodic(
      Duration(seconds: sbiRefreshInterval),
      (_) => fetchSbiTTRates(),
    );

    _rbiTimer = Timer.periodic(
      Duration(seconds: rbiRefreshInterval),
      (_) => fetchRbiReferenceRates(),
    );

    _economicTimer = Timer.periodic(
      Duration(seconds: economicRefreshInterval),
      (_) => fetchEconomicCalendar(),
    );

    _newsTimer = Timer.periodic(
      Duration(seconds: newsRefreshInterval),
      (_) => fetchLiveNews(),
    );
  }

  /// Fetch SBI TT Rates
  /// Source: https://github.com/sahilgupta/sbi-fx-ratekeeper
  /// Fetches latest CSV data for major currencies
  Future<SbiTTRates?> fetchSbiTTRates() async {
    if (isLoadingSbiRates.value) return _sbiTTRatesCache.value;

    try {
      isLoadingSbiRates.value = true;
      final rates = <SbiTTRate>[];
      DateTime? latestDate;
      
      final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'SGD', 'CHF'];
      
      // Fetch all currencies in parallel
      await Future.wait(currencies.map((currency) async {
        try {
          final url = 'https://raw.githubusercontent.com/sahilgupta/sbi-fx-ratekeeper/main/csv_files/SBI_REFERENCE_RATES_$currency.csv';
          final response = await _dio.get(url);
          
          if (response.statusCode == 200 && response.data != null) {
            final csvContent = response.data.toString();
            final lines = csvContent.split('\n');
            
            // Need at least header + 1 data line
            if (lines.length > 1) {
              // Get the last non-empty line
              String lastLine = '';
              for (int i = lines.length - 1; i >= 0; i--) {
                if (lines[i].trim().isNotEmpty) {
                  lastLine = lines[i];
                  break;
                }
              }
              
              if (lastLine.isNotEmpty) {
                final parts = lastLine.split(',');
                // Expecting structure: DATE, PDF FILE, TT BUY, TT SELL, BILL BUY, BILL SELL, ...
                if (parts.length >= 6) {
                  final dateStr = parts[0].trim();
                  // Date format example: 2024-01-03 09:00
                  final date = DateTime.tryParse(dateStr);
                  if (date != null && (latestDate == null || date.isAfter(latestDate!))) {
                    latestDate = date;
                  }
                  
                  rates.add(SbiTTRate(
                    currency: currency,
                    currencyName: _getCurrencyName(currency),
                    ttBuyingRate: _parseDouble(parts[2]),
                    ttSellingRate: _parseDouble(parts[3]),
                    billBuyingRate: _parseDouble(parts[4]),
                    billSellingRate: _parseDouble(parts[5]),
                    previousTtBuy: 0, 
                    previousTtSell: 0,
                  ));
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Failed to fetch $currency: $e');
        }
      }));

      if (rates.isNotEmpty) {
        // Sort by currency priority (USD, EUR, GBP first)
        final priority = {'USD': 1, 'EUR': 2, 'GBP': 3, 'JPY': 4, 'AUD': 5, 'CAD': 6, 'SGD': 7, 'CHF': 8};
        rates.sort((a, b) => (priority[a.currency] ?? 99).compareTo(priority[b.currency] ?? 99));

        _sbiTTRatesCache.value = SbiTTRates(
          effectiveDate: latestDate ?? DateTime.now(),
          lastUpdated: DateTime.now(),
          rates: rates,
        );
        debugPrint('✅ Loaded ${rates.length} SBI TT rates from sahilgupta/sbi-fx-ratekeeper');
        return _sbiTTRatesCache.value;
      }

      debugPrint('⚠️ No SBI TT rates data found from RateKeeper repo');
      return null;
    } catch (e) {
      debugPrint('Error fetching SBI TT rates: $e');
      return _sbiTTRatesCache.value;
    } finally {
      isLoadingSbiRates.value = false;
    }
  }

  /// Fetch RBI Reference Rates
  /// Source: https://www.rbi.org.in/scripts/ReferenceRateArchive.aspx
  Future<List<RbiReferenceRate>> fetchRbiReferenceRates() async {
    if (isLoadingRbiRates.value) return _rbiRatesCache.value;

    try {
      isLoadingRbiRates.value = true;

      // Try to fetch from our backend first
      try {
        final response = await ApiClient().get('/api/market/rbi-reference-rates');
        if (response.data != null && response.data['success'] == true) {
          final List<dynamic> data = response.data['data'];
          _rbiRatesCache.value = data
              .map((json) => RbiReferenceRate.fromJson(json))
              .toList();

          return _rbiRatesCache.value;
        }
      } catch (e) {
        debugPrint('Backend RBI rates fetch failed: $e');
      }

      return _rbiRatesCache.value;
    } catch (e) {
      debugPrint('Error fetching RBI rates: $e');
      return _rbiRatesCache.value;
    } finally {
      isLoadingRbiRates.value = false;
    }
  }

  /// Fetch Economic Calendar Events
  /// Source: Investing.com or backend scraper
  Future<List<EconomicEvent>> fetchEconomicCalendar() async {
    if (isLoadingEconomicCalendar.value) return _economicEventsCache.value;

    try {
      isLoadingEconomicCalendar.value = true;

      // Try to fetch from our backend
      try {
        final response = await ApiClient().get('/api/content/economic-calendar');
        if (response.data != null && response.data['success'] == true) {
          final List<dynamic> data = response.data['data'];
          _economicEventsCache.value = data
              .map((json) => EconomicEvent.fromJson(json))
              .toList();

          return _economicEventsCache.value;
        }
      } catch (e) {
        debugPrint('Backend economic calendar fetch failed: $e');
      }

      return _economicEventsCache.value;
    } catch (e) {
      debugPrint('Error fetching economic calendar: $e');
      return _economicEventsCache.value;
    } finally {
      isLoadingEconomicCalendar.value = false;
    }
  }

  /// Fetch Live News
  /// Source: Trading Economics or backend scraper
  Future<List<LiveNewsItem>> fetchLiveNews() async {
    if (isLoadingNews.value) return _liveNewsCache.value;

    try {
      isLoadingNews.value = true;

      // Try to fetch from our backend
      try {
        final response = await ApiClient().get('/api/content/live-feed');
        if (response.data != null && response.data['success'] == true) {
          final List<dynamic> data = response.data['data'];
          _liveNewsCache.value = data
              .map((json) => LiveNewsItem.fromJson(json))
              .toList();

          return _liveNewsCache.value;
        }
      } catch (e) {
        debugPrint('Backend news fetch failed: $e');
      }

      return _liveNewsCache.value;
    } catch (e) {
      debugPrint('Error fetching live news: $e');
      return _liveNewsCache.value;
    } finally {
      isLoadingNews.value = false;
    }
  }

  /// Fetch Google Sheets Data
  /// Sheet ID: 1BClDDU2oqGyhHyiDw0Kh1GZo8vcdKqNE2zq1gLkS0mw
  Future<Map<String, List<Map<String, dynamic>>>> fetchGoogleSheetsData({
    String sheetId = '1BClDDU2oqGyhHyiDw0Kh1GZo8vcdKqNE2zq1gLkS0mw',
    List<String>? sheetNames,
  }) async {
    if (isLoadingSheetsData.value) return _sheetsDataCache.value;

    try {
      isLoadingSheetsData.value = true;

      // Try to fetch from our backend (recommended approach)
      try {
        final response = await ApiClient().get(
          '/api/data/google-sheets',
          queryParameters: {
            'sheetId': sheetId,
            if (sheetNames != null) 'sheets': sheetNames.join(','),
          },
        );
        if (response.data != null && response.data['success'] == true) {
          final Map<String, dynamic> data = response.data['data'];
          _sheetsDataCache.value = data.map((key, value) {
            return MapEntry(key, List<Map<String, dynamic>>.from(value));
          });
          return _sheetsDataCache.value;
        }
      } catch (e) {
        debugPrint('Backend sheets fetch failed: $e');
      }

      // Alternative: Direct CSV export (public sheets only)
      // Each sheet can be exported as CSV via:
      // https://docs.google.com/spreadsheets/d/{SHEET_ID}/gviz/tq?tqx=out:csv&sheet={SHEET_NAME}

      return _sheetsDataCache.value;
    } catch (e) {
      debugPrint('Error fetching Google Sheets: $e');
      return _sheetsDataCache.value;
    } finally {
      isLoadingSheetsData.value = false;
    }
  }

  /// Fetch Forex Data from Google Sheet
  /// Sheet ID: 1sOs1Hp8aPf6VjpAg9vhpY_kjxgOAgtx0ue9HbDgmvmM
  Future<ForexSheetData?> fetchForexFromSheet({
    String sheetId = '1sOs1Hp8aPf6VjpAg9vhpY_kjxgOAgtx0ue9HbDgmvmM',
  }) async {
    try {
      // Use the CSV export URL
      final csvUrl = 'https://docs.google.com/spreadsheets/d/$sheetId/gviz/tq?tqx=out:csv&gid=0';
      
      final response = await _dio.get(
        csvUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'text/csv'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final csvData = response.data.toString();
        final List<List<dynamic>> rows = _parseFullCsv(csvData);
        final forexData = ForexSheetData.fromCsv(rows);
        _forexSheetCache.value = forexData;
        return forexData;
      }
    } catch (e) {
      debugPrint('Error fetching forex from sheet: $e');
    }
    return _forexSheetCache.value;
  }

  /// Simple CSV parser for the entire content
  List<List<dynamic>> _parseFullCsv(String csvData) {
    final lines = csvData.split('\n');
    final result = <List<dynamic>>[];
    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        result.add(_parseCsvLine(line));
      }
    }
    return result;
  }

  /// Parse a single CSV line, handling quoted values
  List<dynamic> _parseCsvLine(String line) {
    final result = <dynamic>[];
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

  // Helpers
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    return 0.0;
  }
  
  String _getCurrencyName(String code) {
    final names = {
      'USD': 'US Dollar',
      'EUR': 'Euro',
      'GBP': 'British Pound',
      'JPY': 'Japanese Yen',
      'AUD': 'Australian Dollar',
      'CAD': 'Canadian Dollar',
      'SGD': 'Singapore Dollar',
      'CHF': 'Swiss Franc',
      'AED': 'UAE Dirham',
      'SAR': 'Saudi Riyal',
    };
    return names[code] ?? code;
  }

  @override
  void onClose() {
    _sbiTimer?.cancel();
    _rbiTimer?.cancel();
    _economicTimer?.cancel();
    _newsTimer?.cancel();
    super.onClose();
  }
}

// Data Models

class SbiTTRates {
  final DateTime effectiveDate;
  final DateTime lastUpdated;
  final List<SbiTTRate> rates;

  SbiTTRates({
    required this.effectiveDate,
    required this.lastUpdated,
    required this.rates,
  });

  factory SbiTTRates.fromJson(Map<String, dynamic> json) {
    return SbiTTRates(
      effectiveDate: DateTime.parse(json['effectiveDate']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      rates: (json['rates'] as List)
          .map((e) => SbiTTRate.fromJson(e))
          .toList(),
    );
  }
}

class SbiTTRate {
  final String currency;
  final String currencyName;
  final double ttBuyingRate;
  final double ttSellingRate;
  final double billBuyingRate;
  final double billSellingRate;
  final double previousTtBuy;
  final double previousTtSell;

  SbiTTRate({
    required this.currency,
    required this.currencyName,
    required this.ttBuyingRate,
    required this.ttSellingRate,
    required this.billBuyingRate,
    required this.billSellingRate,
    required this.previousTtBuy,
    required this.previousTtSell,
  });

  double get ttBuyChange => ttBuyingRate - previousTtBuy;
  double get ttSellChange => ttSellingRate - previousTtSell;
  double get ttBuyChangePercent => previousTtBuy != 0
      ? (ttBuyChange / previousTtBuy) * 100
      : 0;
  double get ttSellChangePercent => previousTtSell != 0
      ? (ttSellChange / previousTtSell) * 100
      : 0;

  factory SbiTTRate.fromJson(Map<String, dynamic> json) {
    return SbiTTRate(
      currency: json['currency'] ?? '',
      currencyName: json['currencyName'] ?? '',
      ttBuyingRate: (json['ttBuyingRate'] ?? 0).toDouble(),
      ttSellingRate: (json['ttSellingRate'] ?? 0).toDouble(),
      billBuyingRate: (json['billBuyingRate'] ?? 0).toDouble(),
      billSellingRate: (json['billSellingRate'] ?? 0).toDouble(),
      previousTtBuy: (json['previousTtBuy'] ?? 0).toDouble(),
      previousTtSell: (json['previousTtSell'] ?? 0).toDouble(),
    );
  }
}

class RbiReferenceRate {
  final String currency;
  final String currencyName;
  final double rate;
  final double previousRate;
  final DateTime effectiveDate;
  final DateTime lastUpdated;

  RbiReferenceRate({
    required this.currency,
    required this.currencyName,
    required this.rate,
    required this.previousRate,
    required this.effectiveDate,
    required this.lastUpdated,
  });

  double get change => rate - previousRate;
  double get changePercent => previousRate != 0
      ? (change / previousRate) * 100
      : 0;

  factory RbiReferenceRate.fromJson(Map<String, dynamic> json) {
    return RbiReferenceRate(
      currency: json['currency'] ?? '',
      currencyName: json['currencyName'] ?? '',
      rate: (json['rate'] ?? 0).toDouble(),
      previousRate: (json['previousRate'] ?? 0).toDouble(),
      effectiveDate: DateTime.tryParse(json['effectiveDate'] ?? '') ?? DateTime.now(),
      lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
    );
  }
}

enum ImpactLevel { low, medium, high }

class EconomicEvent {
  final String id;
  final String eventName;
  final String country;
  final String countryCode;
  final String currency;
  final DateTime time;
  final ImpactLevel impact;
  final String? actual;
  final String? forecast;
  final String? previous;

  EconomicEvent({
    required this.id,
    required this.eventName,
    required this.country,
    required this.countryCode,
    required this.currency,
    required this.time,
    required this.impact,
    this.actual,
    this.forecast,
    this.previous,
  });

  bool get isUpcoming => time.isAfter(DateTime.now());
  bool get hasActual => actual != null && actual!.isNotEmpty;

  factory EconomicEvent.fromJson(Map<String, dynamic> json) {
    return EconomicEvent(
      id: json['id']?.toString() ?? '',
      eventName: json['eventName'] ?? json['title'] ?? '',
      country: json['country'] ?? '',
      countryCode: json['countryCode'] ?? '',
      currency: json['currency'] ?? '',
      time: DateTime.tryParse(json['time'] ?? json['publishedAt'] ?? '') ?? DateTime.now(),
      impact: _parseImpact(json['impact']),
      actual: json['actual']?.toString(),
      forecast: json['forecast']?.toString(),
      previous: json['previous']?.toString(),
    );
  }

  static ImpactLevel _parseImpact(dynamic value) {
    if (value == null) return ImpactLevel.medium;
    final str = value.toString().toLowerCase();
    if (str.contains('high') || str == '3') return ImpactLevel.high;
    if (str.contains('low') || str == '1') return ImpactLevel.low;
    return ImpactLevel.medium;
  }
}

class LiveNewsItem {
  final String id;
  final String title;
  final String summary;
  final String source;
  final DateTime timestamp;
  final String? url;
  final String? imageUrl;
  final bool isUrgent;

  LiveNewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.timestamp,
    this.url,
    this.imageUrl,
    this.isUrgent = false,
  });

  factory LiveNewsItem.fromJson(Map<String, dynamic> json) {
    return LiveNewsItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? json['description'] ?? '',
      source: json['source'] ?? 'Market Hub',
      timestamp: DateTime.tryParse(json['timestamp'] ?? json['publishedAt'] ?? '') ?? DateTime.now(),
      url: json['url'],
      imageUrl: json['imageUrl'],
      isUrgent: json['isUrgent'] ?? false,
    );
  }
}
