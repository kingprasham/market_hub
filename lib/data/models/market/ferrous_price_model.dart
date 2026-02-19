class FerrousPriceModel {
  final String category; // e.g., INGOT, BILLET, SCRAP
  final String city;
  final double price;
  final String? unit;
  final String? changeRaw; // e.g., 'WHATSAPP' or actual change
  final DateTime lastUpdated;

  FerrousPriceModel({
    required this.category,
    required this.city,
    required this.price,
    this.unit,
    this.changeRaw,
    required this.lastUpdated,
  });

  factory FerrousPriceModel.fromJson(Map<String, dynamic> json) {
    return FerrousPriceModel(
      category: json['category'],
      city: json['city'],
      price: json['price']?.toDouble() ?? 0.0,
      unit: json['unit'],
      changeRaw: json['changeRaw'],
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : DateTime.now(),
    );
  }
}
