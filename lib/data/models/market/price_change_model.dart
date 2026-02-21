/// Represents a single price change detected between data refreshes.
class PriceChange {
  /// Unique key used for deduplication (e.g. "Ferrous|Ingot|Delhi").
  final String key;

  /// Display name of the metal/product.
  final String name;

  /// City or quality descriptor.
  final String city;

  /// Top-level category: Ferrous, Non-Ferrous, Minor Metals, Bullion.
  final String category;

  /// Formatted previous price string (e.g. "₹42,500").
  final String oldPrice;

  /// Formatted current price string.
  final String newPrice;

  /// When the change was detected.
  final DateTime detectedAt;

  const PriceChange({
    required this.key,
    required this.name,
    required this.city,
    required this.category,
    required this.oldPrice,
    required this.newPrice,
    required this.detectedAt,
  });

  factory PriceChange.fromJson(Map<String, dynamic> json) {
    return PriceChange(
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      category: json['category'] ?? '',
      oldPrice: json['oldPrice'] ?? '',
      newPrice: json['newPrice'] ?? '',
      detectedAt: DateTime.parse(json['detectedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'name': name,
    'city': city,
    'category': category,
    'oldPrice': oldPrice,
    'newPrice': newPrice,
    'detectedAt': detectedAt.toIso8601String(),
  };
}
