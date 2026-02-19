class MetalCategoryModel {
  final String id;
  final String name;
  final String iconPath;

  MetalCategoryModel({
    required this.id,
    required this.name,
    required this.iconPath,
  });

  factory MetalCategoryModel.fromJson(Map<String, dynamic> json) {
    return MetalCategoryModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      iconPath: json['iconPath'] ?? 'assets/metals/${(json['name'] ?? 'default').toString().toLowerCase()}.png',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconPath': iconPath,
    };
  }
}

class SpotPriceModel {
  final String id;
  final String metalId;
  final String metalName;
  final String location;
  final String locationCode;
  final double price;
  final double previousPrice;
  final double change;
  final double changePercent;
  final String unit;
  final DateTime updatedAt;
  final String? category;
  final String? purity;

  SpotPriceModel({
    String? id,
    String? metalId,
    String? metalName,
    String? location,
    String? locationCode,
    required this.price,
    double? previousPrice,
    required this.change,
    required this.changePercent,
    String? unit,
    DateTime? updatedAt,
    DateTime? lastUpdated, // alias for updatedAt
    String? symbol, // alias for metalName
    String? name, // alias for metalName
    this.category,
    this.purity,
  })  : id = id ?? metalName ?? symbol ?? name ?? '',
        metalId = metalId ?? metalName ?? symbol ?? name ?? '',
        metalName = metalName ?? symbol ?? name ?? '',
        location = location ?? '',
        locationCode = locationCode ?? '',
        previousPrice = previousPrice ?? 0.0,
        unit = unit ?? 'per kg',
        updatedAt = updatedAt ?? lastUpdated ?? DateTime.now();

  factory SpotPriceModel.fromJson(Map<String, dynamic> json) {
    return SpotPriceModel(
      id: json['_id'] ?? json['id'] ?? '',
      metalId: json['metalId'] ?? '',
      metalName: json['metalName'] ?? json['symbol'] ?? json['name'] ?? '',
      location: json['location'] ?? '',
      locationCode: json['locationCode'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      previousPrice: (json['previousPrice'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['changePercent'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'per kg',
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      category: json['category'],
      purity: json['purity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'metalId': metalId,
      'metalName': metalName,
      'location': location,
      'locationCode': locationCode,
      'price': price,
      'previousPrice': previousPrice,
      'change': change,
      'changePercent': changePercent,
      'unit': unit,
      'updatedAt': updatedAt.toIso8601String(),
      'category': category,
      'purity': purity,
    };
  }

  SpotPriceModel copyWith({
    String? id,
    String? metalId,
    String? metalName,
    String? location,
    String? locationCode,
    double? price,
    double? previousPrice,
    double? change,
    double? changePercent,
    String? unit,
    DateTime? updatedAt,
    DateTime? lastUpdated,
    String? category,
    String? purity,
  }) {
    return SpotPriceModel(
      id: id ?? this.id,
      metalId: metalId ?? this.metalId,
      metalName: metalName ?? this.metalName,
      location: location ?? this.location,
      locationCode: locationCode ?? this.locationCode,
      price: price ?? this.price,
      previousPrice: previousPrice ?? this.previousPrice,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      unit: unit ?? this.unit,
      updatedAt: updatedAt ?? lastUpdated ?? this.updatedAt,
      category: category ?? this.category,
      purity: purity ?? this.purity,
    );
  }

  // Aliases for compatibility
  String get symbol => metalName;
  String get name => metalName;

  bool get isPositive => change >= 0;

  String get formattedPrice => '₹${price.toStringAsFixed(2)}';

  String get changeDisplay =>
      isPositive ? '+${change.toStringAsFixed(2)}' : change.toStringAsFixed(2);

  String get changePercentDisplay => isPositive
      ? '+${changePercent.toStringAsFixed(2)}%'
      : '${changePercent.toStringAsFixed(2)}%';
}

