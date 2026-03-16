class HistoricalPriceModel {
  final String date;
  final double cash;
  final double threeM;
  final double stock;

  HistoricalPriceModel({
    required this.date,
    required this.cash,
    required this.threeM,
    required this.stock,
  });

  factory HistoricalPriceModel.fromJson(Map<String, dynamic> json) {
    return HistoricalPriceModel(
      date: json['date'] ?? '',
      cash: (json['cash'] ?? 0.0).toDouble(),
      threeM: (json['three_m'] ?? 0.0).toDouble(),
      stock: (json['stock'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'cash': cash,
        'three_m': threeM,
        'stock': stock,
      };
}
