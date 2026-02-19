/// Model for watchlist items with support for starring and alerts
class WatchlistItemModel {
  final String id;
  final String userId;
  final String itemId;
  final String itemType; // Spot, Future, FX, LME, SHFE, COMEX
  final String symbol;
  final String name;
  final String? exchange;
  final String? location;
  final DateTime addedAt;
  final double? price;
  final double? change;
  final double? changePercent;
  final String? type; // alias for itemType
  final String? currency;
  final bool? alertEnabled;
  final double? alertPrice;
  final String? alertType; // above, below
  final DateTime? lastUpdated;
  final bool isStarred;
  final String? unit;
  final double? previousPrice;
  final String? category; // Base Metal, BME, etc.

  WatchlistItemModel({
    String? id,
    String? userId,
    String? itemId,
    String? itemType,
    required this.symbol,
    required this.name,
    this.exchange,
    this.location,
    DateTime? addedAt,
    this.price,
    this.change,
    this.changePercent,
    String? type,
    this.currency,
    this.alertEnabled,
    this.alertPrice,
    this.alertType,
    this.lastUpdated,
    this.isStarred = false,
    this.unit,
    this.previousPrice,
    this.category,
  })  : id = id ?? symbol,
        userId = userId ?? '',
        itemId = itemId ?? symbol,
        itemType = itemType ?? type ?? '',
        type = type ?? itemType,
        addedAt = addedAt ?? DateTime.now();

  factory WatchlistItemModel.fromJson(Map<String, dynamic> json) {
    return WatchlistItemModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      itemId: json['itemId'] ?? '',
      itemType: json['itemType'] ?? json['type'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      exchange: json['exchange'],
      location: json['location'],
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'])
          : DateTime.now(),
      price: json['price']?.toDouble(),
      change: json['change']?.toDouble(),
      changePercent: json['changePercent']?.toDouble(),
      currency: json['currency'],
      alertEnabled: json['alertEnabled'],
      alertPrice: json['alertPrice']?.toDouble(),
      alertType: json['alertType'],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
      isStarred: json['isStarred'] ?? false,
      unit: json['unit'],
      previousPrice: json['previousPrice']?.toDouble(),
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'itemId': itemId,
      'itemType': itemType,
      'symbol': symbol,
      'name': name,
      'exchange': exchange,
      'location': location,
      'addedAt': addedAt.toIso8601String(),
      'price': price,
      'change': change,
      'changePercent': changePercent,
      'currency': currency,
      'alertEnabled': alertEnabled,
      'alertPrice': alertPrice,
      'alertType': alertType,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'isStarred': isStarred,
      'unit': unit,
      'previousPrice': previousPrice,
      'category': category,
    };
  }

  WatchlistItemModel copyWith({
    String? id,
    String? userId,
    String? itemId,
    String? itemType,
    String? symbol,
    String? name,
    String? exchange,
    String? location,
    DateTime? addedAt,
    double? price,
    double? change,
    double? changePercent,
    String? type,
    String? currency,
    bool? alertEnabled,
    double? alertPrice,
    String? alertType,
    DateTime? lastUpdated,
    bool? isStarred,
    String? unit,
    double? previousPrice,
    String? category,
  }) {
    return WatchlistItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      exchange: exchange ?? this.exchange,
      location: location ?? this.location,
      addedAt: addedAt ?? this.addedAt,
      price: price ?? this.price,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      currency: currency ?? this.currency,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      alertPrice: alertPrice ?? this.alertPrice,
      alertType: alertType ?? this.alertType,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isStarred: isStarred ?? this.isStarred,
      unit: unit ?? this.unit,
      previousPrice: previousPrice ?? this.previousPrice,
      category: category ?? this.category,
    );
  }

  bool get isFuture => itemType.toLowerCase() == 'future' ||
                        itemType.toLowerCase() == 'lme' ||
                        itemType.toLowerCase() == 'shfe' ||
                        itemType.toLowerCase() == 'comex';
  bool get isSpot => itemType.toLowerCase() == 'spot';
  bool get isFx => itemType.toLowerCase() == 'fx';
  bool get hasAlert => alertEnabled == true && alertPrice != null;

  /// Get display price with currency symbol
  String get displayPrice {
    if (price == null) return '--';
    final currencySymbol = currency == 'INR' ? '\u20B9' : '\$';
    return '$currencySymbol${price!.toStringAsFixed(2)}';
  }

  /// Get change display with sign
  String get displayChange {
    if (change == null) return '--';
    final sign = change! >= 0 ? '+' : '';
    return '$sign${change!.toStringAsFixed(2)}';
  }

  /// Get change percent display
  String get displayChangePercent {
    if (changePercent == null) return '--';
    final sign = changePercent! >= 0 ? '+' : '';
    return '$sign${changePercent!.toStringAsFixed(2)}%';
  }

  /// Check if change is positive
  bool get isPositive => (change ?? 0) >= 0;

  /// Get type color code
  String get typeColorCode {
    switch (itemType.toUpperCase()) {
      case 'LME':
        return 'blue';
      case 'SHFE':
        return 'red';
      case 'COMEX':
        return 'purple';
      case 'SPOT':
        return 'orange';
      case 'FX':
        return 'teal';
      default:
        return 'grey';
    }
  }

  /// Create from spot price data
  factory WatchlistItemModel.fromSpotPrice({
    required String id,
    required String symbol,
    required String name,
    required String location,
    required double price,
    double? previousPrice,
    double? change,
    double? changePercent,
    String unit = 'Rs/Kg',
    String? category,
  }) {
    return WatchlistItemModel(
      id: id,
      symbol: symbol,
      name: name,
      itemType: 'Spot',
      location: location,
      price: price,
      previousPrice: previousPrice,
      change: change,
      changePercent: changePercent,
      currency: 'INR',
      unit: unit,
      category: category,
    );
  }

  /// Create from future data
  factory WatchlistItemModel.fromFuture({
    required String symbol,
    required String name,
    required String exchange,
    required double price,
    double? change,
    double? changePercent,
    String currency = 'USD',
  }) {
    return WatchlistItemModel(
      id: '${exchange}_$symbol',
      symbol: symbol,
      name: name,
      itemType: exchange,
      exchange: exchange,
      price: price,
      change: change,
      changePercent: changePercent,
      currency: currency,
    );
  }

  /// Create from FX data
  factory WatchlistItemModel.fromFx({
    required String pair,
    required double rate,
    double? change,
    double? changePercent,
    String? source,
  }) {
    return WatchlistItemModel(
      id: 'FX_$pair',
      symbol: pair,
      name: pair,
      itemType: 'FX',
      price: rate,
      change: change,
      changePercent: changePercent,
      currency: 'INR',
      exchange: source,
    );
  }

  @override
  String toString() {
    return 'WatchlistItemModel(id: $id, symbol: $symbol, name: $name, type: $itemType, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WatchlistItemModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
