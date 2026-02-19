class FutureDataModel {
  final String id;
  final String symbol;
  final String name;
  final String exchange;
  final double lastTradePrice;
  final double previousClose;
  final double high;
  final double low;
  final double open;
  final double change;
  final double changePercent;
  final int volume;
  final DateTime lastTradeTime;
  final DateTime lastUpdated;
  final String? currency;

  FutureDataModel({
    String? id,
    required this.symbol,
    required this.name,
    required this.exchange,
    double? lastTradePrice,
    double? price, // alias for lastTradePrice
    double? previousClose,
    required this.high,
    required this.low,
    required this.open,
    required this.change,
    required this.changePercent,
    required this.volume,
    DateTime? lastTradeTime,
    DateTime? lastUpdated,
    this.currency,
  })  : id = id ?? symbol,
        lastTradePrice = lastTradePrice ?? price ?? 0.0,
        previousClose = previousClose ?? 0.0,
        lastTradeTime = lastTradeTime ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  factory FutureDataModel.fromJson(Map<String, dynamic> json) {
    return FutureDataModel(
      id: json['_id'] ?? json['id'] ?? json['symbol'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      exchange: json['exchange'] ?? '',
      lastTradePrice: (json['lastTradePrice'] ?? json['price'] ?? 0).toDouble(),
      previousClose: (json['previousClose'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      open: (json['open'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['changePercent'] ?? 0).toDouble(),
      volume: json['volume'] ?? 0,
      lastTradeTime: json['lastTradeTime'] != null
          ? DateTime.parse(json['lastTradeTime'])
          : DateTime.now(),
      lastUpdated: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      currency: json['currency'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'exchange': exchange,
      'lastTradePrice': lastTradePrice,
      'previousClose': previousClose,
      'high': high,
      'low': low,
      'open': open,
      'change': change,
      'changePercent': changePercent,
      'volume': volume,
      'lastTradeTime': lastTradeTime.toIso8601String(),
      'updatedAt': lastUpdated.toIso8601String(),
      'currency': currency,
    };
  }

  FutureDataModel copyWith({
    String? id,
    String? symbol,
    String? name,
    String? exchange,
    double? lastTradePrice,
    double? price,
    double? previousClose,
    double? high,
    double? low,
    double? open,
    double? change,
    double? changePercent,
    int? volume,
    DateTime? lastTradeTime,
    DateTime? lastUpdated,
    String? currency,
  }) {
    return FutureDataModel(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      exchange: exchange ?? this.exchange,
      lastTradePrice: lastTradePrice ?? price ?? this.lastTradePrice,
      previousClose: previousClose ?? this.previousClose,
      high: high ?? this.high,
      low: low ?? this.low,
      open: open ?? this.open,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      volume: volume ?? this.volume,
      lastTradeTime: lastTradeTime ?? this.lastTradeTime,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currency: currency ?? this.currency,
    );
  }

  bool get isPositive => change >= 0;

  // Alias for compatibility
  double get price => lastTradePrice;

  String get changeDisplay =>
      isPositive ? '+${change.toStringAsFixed(2)}' : change.toStringAsFixed(2);

  String get changePercentDisplay => isPositive
      ? '+${changePercent.toStringAsFixed(2)}%'
      : '${changePercent.toStringAsFixed(2)}%';

  String get priceDisplay => '\$${lastTradePrice.toStringAsFixed(2)}';

  String get highDisplay => '\$${high.toStringAsFixed(2)}';

  String get lowDisplay => '\$${low.toStringAsFixed(2)}';
}
