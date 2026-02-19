/// Represents the complete spot price bulletin from Google Sheets
/// Structured to match the DELHI For App spreadsheet format
class SpotBulletinModel {
  final String bulletinDate;
  final String marketName;
  final List<MetalSection> metalSections;
  final List<String> cities;
  final DateTime fetchedAt;

  SpotBulletinModel({
    required this.bulletinDate,
    required this.marketName,
    required this.metalSections,
    required this.cities,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  /// Get all unique metal categories
  List<String> get metalCategories =>
      metalSections.map((s) => s.metalName).toSet().toList();

  /// Get prices for a specific metal
  MetalSection? getMetalSection(String metalName) {
    try {
      return metalSections.firstWhere(
        (s) => s.metalName.toLowerCase() == metalName.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get all prices for a specific city
  List<MetalPriceEntry> getPricesForCity(String city) {
    final prices = <MetalPriceEntry>[];
    for (final section in metalSections) {
      for (final entry in section.entries) {
        if (entry.city.toLowerCase() == city.toLowerCase()) {
          prices.add(entry);
        }
      }
    }
    return prices;
  }

  factory SpotBulletinModel.empty() {
    return SpotBulletinModel(
      bulletinDate: '',
      marketName: '',
      metalSections: [],
      cities: [],
    );
  }
}

/// Represents a section for a specific metal (e.g., Copper section)
class MetalSection {
  final String metalName;
  final String metalSymbol;
  final List<MetalSubtype> subtypes;
  final List<MetalPriceEntry> entries;

  MetalSection({
    required this.metalName,
    String? metalSymbol,
    required this.subtypes,
    required this.entries,
  }) : metalSymbol = metalSymbol ?? _getSymbolForMetal(metalName);

  static String _getSymbolForMetal(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('copper')) return 'Cu';
    if (lower.contains('brass')) return 'Br';
    if (lower.contains('aluminium') || lower.contains('aluminum')) return 'Al';
    if (lower.contains('lead')) return 'Pb';
    if (lower.contains('gun')) return 'GM';
    if (lower.contains('zinc')) return 'Zn';
    if (lower.contains('nickel')) return 'Ni';
    if (lower.contains('tin')) return 'Sn';
    if (lower.contains('steel') || lower.contains('ss')) return 'SS';
    return name.substring(0, 2).toUpperCase();
  }

  /// Get all unique subtypes for this metal
  List<String> get subtypeNames => subtypes.map((s) => s.name).toList();

  /// Get entries for a specific subtype
  List<MetalPriceEntry> getEntriesForSubtype(String subtypeName) {
    return entries.where((e) =>
      e.subtype.toLowerCase() == subtypeName.toLowerCase()
    ).toList();
  }

  /// Get entries for a specific city
  List<MetalPriceEntry> getEntriesForCity(String city) {
    return entries.where((e) =>
      e.city.toLowerCase() == city.toLowerCase()
    ).toList();
  }
}

/// Represents a subtype of a metal (e.g., Copper Scrap ARM, Copper CCR Rod)
class MetalSubtype {
  final String name;
  final String? description;
  final String? grade;

  MetalSubtype({
    required this.name,
    this.description,
    this.grade,
  });
}

/// Represents a single price entry for a metal subtype in a specific city
class MetalPriceEntry {
  final String id;
  final String metalName;
  final String subtype;
  final String city;
  final double cashPrice;
  final double? creditPrice;
  final double? change;
  final double? changePercent;
  final String unit;
  final String? grade;
  final DateTime lastUpdated;

  MetalPriceEntry({
    String? id,
    required this.metalName,
    required this.subtype,
    required this.city,
    required this.cashPrice,
    this.creditPrice,
    this.change,
    this.changePercent,
    String? unit,
    this.grade,
    DateTime? lastUpdated,
  }) : id = id ?? '${metalName}_${subtype}_$city'.replaceAll(' ', '_').toLowerCase(),
       unit = unit ?? 'Rs/Kg',
       lastUpdated = lastUpdated ?? DateTime.now();

  /// Display name combining metal and subtype
  String get displayName => '$metalName $subtype';

  /// Full identifier
  String get fullId => '${metalName}_${subtype}_$city'.replaceAll(' ', '_').toLowerCase();

  /// Price display with cash/credit
  String get priceDisplay {
    if (creditPrice != null && creditPrice! > 0) {
      return '${cashPrice.toStringAsFixed(0)}/${creditPrice!.toStringAsFixed(0)}';
    }
    return cashPrice.toStringAsFixed(0);
  }

  /// Is price positive change
  bool get isPositive => (change ?? 0) >= 0;

  /// Convert to SpotPriceModel for compatibility
  Map<String, dynamic> toSpotPriceJson() {
    return {
      'id': id,
      'metalId': metalName.toLowerCase(),
      'metalName': displayName,
      'location': city,
      'locationCode': _getCityCode(city),
      'price': cashPrice,
      'previousPrice': cashPrice - (change ?? 0),
      'change': change ?? 0,
      'changePercent': changePercent ?? 0,
      'unit': unit,
      'updatedAt': lastUpdated.toIso8601String(),
      'category': metalName,
      'purity': grade,
    };
  }

  static String _getCityCode(String city) {
    final codes = {
      'delhi': 'DEL',
      'mumbai': 'MUM',
      'ahmedabad': 'AMD',
      'kolkata': 'KOL',
      'chennai': 'CHE',
      'jaipur': 'JAI',
      'bhiwadi': 'BHI',
      'pune': 'PUN',
      'hyderabad': 'HYD',
      'nagpur': 'NAG',
      'jamnagar': 'JAM',
      'bangalore': 'BLR',
      'ludhiana': 'LDH',
      'jalandhar': 'JAL',
    };
    return codes[city.toLowerCase()] ?? city.substring(0, 3).toUpperCase();
  }

  factory MetalPriceEntry.fromJson(Map<String, dynamic> json) {
    return MetalPriceEntry(
      id: json['id'],
      metalName: json['metalName'] ?? '',
      subtype: json['subtype'] ?? '',
      city: json['city'] ?? '',
      cashPrice: (json['cashPrice'] ?? json['price'] ?? 0).toDouble(),
      creditPrice: json['creditPrice']?.toDouble(),
      change: json['change']?.toDouble(),
      changePercent: json['changePercent']?.toDouble(),
      unit: json['unit'],
      grade: json['grade'],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'metalName': metalName,
      'subtype': subtype,
      'city': city,
      'cashPrice': cashPrice,
      'creditPrice': creditPrice,
      'change': change,
      'changePercent': changePercent,
      'unit': unit,
      'grade': grade,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Static configuration for metals based on the spreadsheet
class SpotMetalConfig {
  static const List<MetalInfo> metals = [
    MetalInfo(
      name: 'Copper',
      symbol: 'Cu',
      subtypes: ['Scrap (ARM)', 'CCR Rod', 'CC Rod', 'Super D', 'Zero Grade', '8mm CCR', '1.6mm CCR'],
      gradientColors: [0xFFB87333, 0xFFDA8A67],
      accentColor: 0xFFB87333,
    ),
    MetalInfo(
      name: 'Brass',
      symbol: 'Br',
      subtypes: ['Purja', 'Honey', 'Chadri', 'Bharat', 'Sheet Cutting'],
      gradientColors: [0xFFD4AF37, 0xFFE6C84A],
      accentColor: 0xFFD4AF37,
    ),
    MetalInfo(
      name: 'Aluminium',
      symbol: 'Al',
      subtypes: ['Purja (Desi)', 'Engine', 'Bartan', 'Wire', 'Company Ingot', 'Company Rod', 'Local Rod', 'Tense'],
      gradientColors: [0xFF848789, 0xFFA8A9AB],
      accentColor: 0xFF848789,
    ),
    MetalInfo(
      name: 'Lead',
      symbol: 'Pb',
      subtypes: ['Local', 'NILMA', 'Battery (Batt)', 'PP Grade', 'India Make'],
      gradientColors: [0xFF5C6670, 0xFF7A8A94],
      accentColor: 0xFF5C6670,
    ),
    MetalInfo(
      name: 'Gun Metal',
      symbol: 'GM',
      subtypes: ['Local', 'Mix', 'Jalandhar'],
      gradientColors: [0xFF6B4423, 0xFF8B6914],
      accentColor: 0xFF6B4423,
    ),
    MetalInfo(
      name: 'Zinc',
      symbol: 'Zn',
      subtypes: ['HZL', 'Imported', 'Australia', 'PMI', 'Dross', 'Tukadi'],
      gradientColors: [0xFF5F9EA0, 0xFF7FBFC1],
      accentColor: 0xFF5F9EA0,
    ),
    MetalInfo(
      name: 'Nickel',
      symbol: 'Ni',
      subtypes: ['Russian Cathode', 'Norway Cathode', 'Jinchuan Cathode'],
      gradientColors: [0xFF727472, 0xFF929492],
      accentColor: 0xFF727472,
    ),
    MetalInfo(
      name: 'Tin',
      symbol: 'Sn',
      subtypes: ['Indo Retail', 'Indo Wholesale', 'LME Grade'],
      gradientColors: [0xFFA9A9A9, 0xFFC9C9C9],
      accentColor: 0xFFA9A9A9,
    ),
    MetalInfo(
      name: 'Stainless Steel',
      symbol: 'SS',
      subtypes: ['SS 202', 'SS 304', 'SS 309', 'SS 310', 'SS 316'],
      gradientColors: [0xFF71797E, 0xFF91999E],
      accentColor: 0xFF71797E,
    ),
  ];

  static const List<String> defaultCities = [
    'Delhi',
    'Bhiwadi',
    'Mumbai',
    'Ahmedabad',
    'Pune',
    'Hyderabad',
    'Nagpur',
    'Chennai',
    'Kolkata',
    'Jaipur',
    'Ludhiana',
    'Jalandhar',
    'Jamnagar',
    'Bangalore',
  ];

  static MetalInfo? getMetalInfo(String metalName) {
    try {
      return metals.firstWhere(
        (m) => m.name.toLowerCase() == metalName.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Information about a specific metal
class MetalInfo {
  final String name;
  final String symbol;
  final List<String> subtypes;
  final List<int> gradientColors;
  final int accentColor;

  const MetalInfo({
    required this.name,
    required this.symbol,
    required this.subtypes,
    required this.gradientColors,
    required this.accentColor,
  });
}

/// Represents a BME (Bullion/Gold/Silver) rate from Google Sheets
class BmeRate {
  final String id;
  final String metalName; // Gold, Silver, etc.
  final String purity; // 995, 999, 22K, etc.
  final double price;
  final double? previousPrice;
  final double change;
  final double changePercent;
  final String unit; // Rs/10gm, Rs/Kg
  final String city;
  final DateTime lastUpdated;
  final Map<String, dynamic>? additionalData;

  BmeRate({
    required this.id,
    required this.metalName,
    required this.purity,
    required this.price,
    this.previousPrice,
    double? change,
    double? changePercent,
    required this.unit,
    required this.city,
    DateTime? lastUpdated,
    this.additionalData,
  })  : change = change ?? 0.0,
        changePercent = changePercent ?? 0.0,
        lastUpdated = lastUpdated ?? DateTime.now();

  BmeRate copyWith({
    String? id,
    String? metalName,
    String? purity,
    double? price,
    double? previousPrice,
    double? change,
    double? changePercent,
    String? unit,
    String? city,
    DateTime? lastUpdated,
    Map<String, dynamic>? additionalData,
  }) {
    return BmeRate(
      id: id ?? this.id,
      metalName: metalName ?? this.metalName,
      purity: purity ?? this.purity,
      price: price ?? this.price,
      previousPrice: previousPrice ?? this.previousPrice,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      unit: unit ?? this.unit,
      city: city ?? this.city,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}

/// Represents city-wise rate data from OTHER_RATE sheet
class CityRate {
  final String productName;
  final String city;
  final double? cashPrice;
  final double? creditPrice;
  final String unit;
  final DateTime lastUpdated;

  CityRate({
    required this.productName,
    required this.city,
    this.cashPrice,
    this.creditPrice,
    required this.unit,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
}
