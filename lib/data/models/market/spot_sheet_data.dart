
class FerrousSpotItem {
  final String category; // Ingot, Billet, etc.
  final String region; // Raipur, Ludhiana, etc.
  final double price;
  final String type; // APP, WHATSAPP, STEEL TRADE, etc.

  FerrousSpotItem({
    required this.category,
    required this.region,
    required this.price,
    required this.type,
  });

  @override
  String toString() {
    return 'FerrousSpotItem(category: $category, region: $region, price: $price, type: $type)';
  }
}

class MinorFerroItem {
  final String category; // Raw Materials, Base Metals, etc.
  final String item;
  final String quality;
  final double price;
  final String unit;
  final String date;

  MinorFerroItem({
    required this.category,
    required this.item,
    required this.quality,
    required this.price,
    required this.unit,
    required this.date,
  });

  @override
  String toString() {
    return 'MinorFerroItem(category: $category, item: $item, price: $price)';
  }
}
