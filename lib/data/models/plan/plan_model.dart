class PlanModel {
  final String id;
  final String name;
  final String description;
  final List<String> features;
  final double price;
  final String duration;
  final int durationDays;
  final bool isPopular;
  final int sortOrder;

  PlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.features,
    required this.price,
    required this.duration,
    required this.durationDays,
    this.isPopular = false,
    this.sortOrder = 0,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      features: List<String>.from(json['features'] ?? []),
      price: (json['price'] ?? 0).toDouble(),
      duration: json['duration'] ?? 'monthly',
      durationDays: json['durationDays'] ?? 30,
      isPopular: json['isPopular'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'features': features,
      'price': price,
      'duration': duration,
      'durationDays': durationDays,
      'isPopular': isPopular,
      'sortOrder': sortOrder,
    };
  }

  String get formattedPrice => '₹${price.toStringAsFixed(0)}';

  String get durationLabel {
    switch (duration) {
      case 'monthly':
        return 'per month';
      case 'quarterly':
        return 'per quarter';
      case 'half-yearly':
        return 'per 6 months';
      case 'yearly':
        return 'per year';
      default:
        return '';
    }
  }

  String get durationText {
    switch (duration) {
      case 'monthly':
        return '1 Month';
      case 'quarterly':
        return '3 Months';
      case 'half-yearly':
        return '6 Months';
      case 'yearly':
        return '1 Year';
      default:
        return '$durationDays Days';
    }
  }
}
