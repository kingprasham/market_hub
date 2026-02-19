/// Model for SBI Forex/TT rates from sbi-fx-ratekeeper repository
/// Data source: https://github.com/sahilgupta/sbi-fx-ratekeeper
class SbiForexRateModel {
  final DateTime dateTime;
  final String pdfFile;
  final double? ttBuy;
  final double? ttSell;
  final double? billBuy;
  final double? billSell;
  final double? forexTravelCardBuy;
  final double? forexTravelCardSell;
  final double? cnBuy;
  final double? cnSell;
  final String currencyCode;
  final double? change;
  final double? percentChange;

  SbiForexRateModel({
    required this.dateTime,
    required this.pdfFile,
    this.ttBuy,
    this.ttSell,
    this.billBuy,
    this.billSell,
    this.forexTravelCardBuy,
    this.forexTravelCardSell,
    this.cnBuy,
    this.cnSell,
    required this.currencyCode,
    this.change,
    this.percentChange,
  });

  /// Parse from CSV row
  /// Expected format: DATE,PDF FILE,TT BUY,TT SELL,BILL BUY,BILL SELL,FOREX TRAVEL CARD BUY,FOREX TRAVEL CARD SELL,CN BUY,CN SELL
  factory SbiForexRateModel.fromCsvRow(List<String> row, String currencyCode) {
    if (row.length < 10) {
      throw FormatException('Invalid CSV row: expected 10 columns, got ${row.length}');
    }

    return SbiForexRateModel(
      dateTime: _parseDateTime(row[0]),
      pdfFile: row[1],
      ttBuy: _parseDouble(row[2]),
      ttSell: _parseDouble(row[3]),
      billBuy: _parseDouble(row[4]),
      billSell: _parseDouble(row[5]),
      forexTravelCardBuy: _parseDouble(row[6]),
      forexTravelCardSell: _parseDouble(row[7]),
      cnBuy: _parseDouble(row[8]),
      cnSell: _parseDouble(row[9]),
      currencyCode: currencyCode,
    );
  }

  /// Create a copy with updated fields
  SbiForexRateModel copyWith({
    DateTime? dateTime,
    String? pdfFile,
    double? ttBuy,
    double? ttSell,
    double? billBuy,
    double? billSell,
    double? forexTravelCardBuy,
    double? forexTravelCardSell,
    double? cnBuy,
    double? cnSell,
    String? currencyCode,
    double? change,
    double? percentChange,
  }) {
    return SbiForexRateModel(
      dateTime: dateTime ?? this.dateTime,
      pdfFile: pdfFile ?? this.pdfFile,
      ttBuy: ttBuy ?? this.ttBuy,
      ttSell: ttSell ?? this.ttSell,
      billBuy: billBuy ?? this.billBuy,
      billSell: billSell ?? this.billSell,
      forexTravelCardBuy: forexTravelCardBuy ?? this.forexTravelCardBuy,
      forexTravelCardSell: forexTravelCardSell ?? this.forexTravelCardSell,
      cnBuy: cnBuy ?? this.cnBuy,
      cnSell: cnSell ?? this.cnSell,
      currencyCode: currencyCode ?? this.currencyCode,
      change: change ?? this.change,
      percentChange: percentChange ?? this.percentChange,
    );
  }

  /// Parse date string in various formats
  static DateTime _parseDateTime(String value) {
    // Try ISO 8601 format first
    final isoResult = DateTime.tryParse(value.trim());
    if (isoResult != null) return isoResult;

    // Try MM-DD-YYYY or DD-MM-YYYY format
    final parts = value.trim().split(RegExp(r'[/\-\.]'));
    if (parts.length == 3) {
      final first = int.tryParse(parts[0]) ?? 1;
      final second = int.tryParse(parts[1]) ?? 1;
      var year = int.tryParse(parts[2]) ?? DateTime.now().year;
      if (year < 100) year += 2000;

      int month, day;
      if (parts[0].length == 4) {
        // YYYY-MM-DD format
        return DateTime(first, second, int.tryParse(parts[2]) ?? 1);
      } else if (second > 12) {
        // second is day (>12), so first is month: MM-DD-YYYY
        month = first;
        day = second;
      } else if (first > 12) {
        // first is day (>12), so second is month: DD-MM-YYYY
        day = first;
        month = second;
      } else {
        // Ambiguous - default to MM-DD-YYYY (American format)
        month = first;
        day = second;
      }
      return DateTime(year, month, day);
    }

    return DateTime.now();
  }

  static double? _parseDouble(String value) {
    if (value.isEmpty || value.trim().isEmpty) return null;
    try {
      return double.parse(value);
    } catch (e) {
      return null;
    }
  }

  /// Get the average TT rate
  double? get averageTTRate {
    if (ttBuy != null && ttSell != null) {
      return (ttBuy! + ttSell!) / 2;
    }
    return ttBuy ?? ttSell;
  }

  /// Get the spread between buy and sell
  double? get ttSpread {
    if (ttBuy != null && ttSell != null) {
      return ttSell! - ttBuy!;
    }
    return null;
  }

  /// Format date for display
  String get formattedDate {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  /// Format time for display
  String get formattedTime {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format datetime for display
  String get formattedDateTime {
    return '$formattedDate $formattedTime';
  }

  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'pdfFile': pdfFile,
      'ttBuy': ttBuy,
      'ttSell': ttSell,
      'billBuy': billBuy,
      'billSell': billSell,
      'forexTravelCardBuy': forexTravelCardBuy,
      'forexTravelCardSell': forexTravelCardSell,
      'cnBuy': cnBuy,
      'cnSell': cnSell,
      'currencyCode': currencyCode,
      'change': change,
      'percentChange': percentChange,
    };
  }

  factory SbiForexRateModel.fromJson(Map<String, dynamic> json) {
    return SbiForexRateModel(
      dateTime: DateTime.parse(json['dateTime']),
      pdfFile: json['pdfFile'],
      ttBuy: json['ttBuy']?.toDouble(),
      ttSell: json['ttSell']?.toDouble(),
      billBuy: json['billBuy']?.toDouble(),
      billSell: json['billSell']?.toDouble(),
      forexTravelCardBuy: json['forexTravelCardBuy']?.toDouble(),
      forexTravelCardSell: json['forexTravelCardSell']?.toDouble(),
      cnBuy: json['cnBuy']?.toDouble(),
      cnSell: json['cnSell']?.toDouble(),
      currencyCode: json['currencyCode'],
      change: json['change']?.toDouble(),
      percentChange: json['percentChange']?.toDouble(),
    );
  }
}

/// Supported currencies in the SBI FX repository
class SupportedCurrencies {
  static const Map<String, String> currencies = {
    'AED': 'UAE Dirham',
    'AUD': 'Australian Dollar',
    'BDT': 'Bangladeshi Taka',
    'BHD': 'Bahraini Dinar',
    'CAD': 'Canadian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
    'DKK': 'Danish Krone',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'HKD': 'Hong Kong Dollar',
    'IDR': 'Indonesian Rupiah',
    'JPY': 'Japanese Yen',
    'KES': 'Kenyan Shilling',
    'KRW': 'South Korean Won',
    'KWD': 'Kuwaiti Dinar',
    'LKR': 'Sri Lankan Rupee',
    'MYR': 'Malaysian Ringgit',
    'NOK': 'Norwegian Krone',
    'NZD': 'New Zealand Dollar',
    'OMR': 'Omani Rial',
    'PKR': 'Pakistani Rupee',
    'QAR': 'Qatari Riyal',
    'RUB': 'Russian Ruble',
    'SAR': 'Saudi Riyal',
    'SEK': 'Swedish Krona',
    'SGD': 'Singapore Dollar',
    'THB': 'Thai Baht',
    'TRY': 'Turkish Lira',
    'USD': 'US Dollar',
    'ZAR': 'South African Rand',
  };

  static List<String> get currencyCodes => currencies.keys.toList()..sort();

  static String getCurrencyName(String code) => currencies[code] ?? code;

  static List<MapEntry<String, String>> get sortedCurrencies {
    final entries = currencies.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  /// Popular currencies for quick access
  static const List<String> popularCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'AED',
    'SGD',
    'AUD',
    'CAD',
    'JPY',
  ];
}
