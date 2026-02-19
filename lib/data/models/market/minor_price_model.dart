class MinorPriceModel {
  final String category;
  final String item;
  final String quality;
  final String price; // Keeping as String for now to handle ranges or standard formatting, or parse to double if cleaner
  final String unit;
  final String date;
  final DateTime? parsedDate;

  MinorPriceModel({
    required this.category,
    required this.item,
    required this.quality,
    required this.price,
    required this.unit,
    required this.date,
    this.parsedDate,
  });

  factory MinorPriceModel.fromJson(Map<String, dynamic> json) {
    return MinorPriceModel(
      category: json['category'] ?? '',
      item: json['item'] ?? '',
      quality: json['quality'] ?? '',
      price: json['price'] ?? '',
      unit: json['unit'] ?? '',
      date: json['date'] ?? '',
      parsedDate: json['parsedDate'] != null ? DateTime.parse(json['parsedDate']) : null,
    );
  }
}
