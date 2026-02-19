class FXModel {
  final String id;
  final String currencyPair;
  final String baseCurrency;
  final String quoteCurrency;
  final double rate;
  final double previousRate;
  final double change;
  final double changePercent;
  final double high;
  final double low;
  final DateTime updatedAt;

  FXModel({
    required this.id,
    required this.currencyPair,
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.rate,
    required this.previousRate,
    required this.change,
    required this.changePercent,
    required this.high,
    required this.low,
    required this.updatedAt,
  });

  factory FXModel.fromJson(Map<String, dynamic> json) {
    return FXModel(
      id: json['_id'] ?? json['id'] ?? '',
      currencyPair: json['currencyPair'] ?? '',
      baseCurrency: json['baseCurrency'] ?? '',
      quoteCurrency: json['quoteCurrency'] ?? '',
      rate: (json['rate'] ?? 0).toDouble(),
      previousRate: (json['previousRate'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['changePercent'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'currencyPair': currencyPair,
      'baseCurrency': baseCurrency,
      'quoteCurrency': quoteCurrency,
      'rate': rate,
      'previousRate': previousRate,
      'change': change,
      'changePercent': changePercent,
      'high': high,
      'low': low,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isPositive => change >= 0;

  String get rateDisplay => rate.toStringAsFixed(4);

  String get changeDisplay =>
      isPositive ? '+${change.toStringAsFixed(4)}' : change.toStringAsFixed(4);

  String get changePercentDisplay => isPositive
      ? '+${changePercent.toStringAsFixed(2)}%'
      : '${changePercent.toStringAsFixed(2)}%';
}

class ReferenceRateModel {
  final String id;
  final String type;
  final String currency;
  final double buyRate;
  final double sellRate;
  final DateTime effectiveDate;
  final DateTime updatedAt;

  ReferenceRateModel({
    required this.id,
    required this.type,
    required this.currency,
    required this.buyRate,
    required this.sellRate,
    required this.effectiveDate,
    required this.updatedAt,
  });

  factory ReferenceRateModel.fromJson(Map<String, dynamic> json) {
    return ReferenceRateModel(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      currency: json['currency'] ?? 'USD',
      buyRate: (json['buyRate'] ?? 0).toDouble(),
      sellRate: (json['sellRate'] ?? 0).toDouble(),
      effectiveDate: json['effectiveDate'] != null
          ? DateTime.parse(json['effectiveDate'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'currency': currency,
      'buyRate': buyRate,
      'sellRate': sellRate,
      'effectiveDate': effectiveDate.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get typeLabel {
    switch (type) {
      case 'SBI_TT':
        return 'SBI TT';
      case 'F_BILL':
        return 'F-Bill';
      case 'RBI_TT':
        return 'RBI TT';
      default:
        return type;
    }
  }
}

/// FxModel for currency pair data used in FutureController
class FxModel {
  final String pair;
  final double rate;
  final double change;
  final double changePercent;
  final double? bid;
  final double? ask;
  final double? high;
  final double? low;
  final DateTime lastUpdated;
  final String? source;

  FxModel({
    required this.pair,
    required this.rate,
    required this.change,
    required this.changePercent,
    this.bid,
    this.ask,
    this.high,
    this.low,
    required this.lastUpdated,
    this.source,
  });

  factory FxModel.fromJson(Map<String, dynamic> json) {
    return FxModel(
      pair: json['pair'] ?? json['currencyPair'] ?? '',
      rate: (json['rate'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['changePercent'] ?? 0).toDouble(),
      bid: json['bid']?.toDouble(),
      ask: json['ask']?.toDouble(),
      high: json['high']?.toDouble(),
      low: json['low']?.toDouble(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pair': pair,
      'rate': rate,
      'change': change,
      'changePercent': changePercent,
      'bid': bid,
      'ask': ask,
      'high': high,
      'low': low,
      'lastUpdated': lastUpdated.toIso8601String(),
      'source': source,
    };
  }

  FxModel copyWith({
    String? pair,
    double? rate,
    double? change,
    double? changePercent,
    double? bid,
    double? ask,
    double? high,
    double? low,
    DateTime? lastUpdated,
    String? source,
  }) {
    return FxModel(
      pair: pair ?? this.pair,
      rate: rate ?? this.rate,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      bid: bid ?? this.bid,
      ask: ask ?? this.ask,
      high: high ?? this.high,
      low: low ?? this.low,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      source: source ?? this.source,
    );
  }

  bool get isPositive => change >= 0;

  String get rateDisplay => rate.toStringAsFixed(4);

  String get changeDisplay =>
      isPositive ? '+${change.toStringAsFixed(4)}' : change.toStringAsFixed(4);

  String get changePercentDisplay => isPositive
      ? '+${changePercent.toStringAsFixed(2)}%'
      : '${changePercent.toStringAsFixed(2)}%';
}
