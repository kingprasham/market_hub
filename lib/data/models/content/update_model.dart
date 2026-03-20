class UpdateModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? pdfUrl;
  final String? category;
  final DateTime createdAt;
  final bool isImportant;
  final List<String> targetPlanIds;

  UpdateModel({
    String? id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.pdfUrl,
    this.category,
    DateTime? createdAt,
    DateTime? timestamp, // alias for createdAt
    this.isImportant = false,
    this.targetPlanIds = const ['all'],
  })  : id = id ?? title,
        createdAt = createdAt ?? timestamp ?? DateTime.now();

  factory UpdateModel.fromJson(Map<String, dynamic> json) {
    // Parse targetPlans - can be from targetPlanIds or targetPlans field
    List<String> parsedTargetPlans = ['all'];
    if (json['targetPlanIds'] != null) {
      parsedTargetPlans = List<String>.from(json['targetPlanIds']);
    } else if (json['targetPlans'] != null) {
      parsedTargetPlans = List<String>.from(json['targetPlans']);
    }

    return UpdateModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? json['note'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'],
      pdfUrl: json['pdfUrl'] ?? json['pdf'],
      category: json['category'],
      createdAt: _parseDate(json['createdAt']),
      isImportant: json['isImportant'] ?? false,
      targetPlanIds: parsedTargetPlans,
    );
  }

  static DateTime _parseDate(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().isEmpty) return DateTime.now();
    try {
      String str = dateStr.toString();
      // Regular expression to check for ISO 8601 timezone offset (+HH:mm or -HH:mm or Z)
      final hasTz = str.endsWith('Z') || RegExp(r'[+-]\d{2}(:?\d{2})?$').hasMatch(str);
      
      if (!hasTz) {
        // If no timezone is provided, assume it's UTC from PHP without 'c' format
        str += 'Z';
      }
      
      return DateTime.parse(str).toLocal();
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'pdfUrl': pdfUrl,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'isImportant': isImportant,
      'targetPlanIds': targetPlanIds,
    };
  }

  // Alias for compatibility
  DateTime get timestamp => createdAt;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasPdf => pdfUrl != null && pdfUrl!.isNotEmpty;
}
