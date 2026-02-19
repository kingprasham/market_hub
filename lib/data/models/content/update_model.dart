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
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? json['note'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'],
      pdfUrl: json['pdfUrl'] ?? json['pdf'],
      category: json['category'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isImportant: json['isImportant'] ?? false,
      targetPlanIds: parsedTargetPlans,
    );
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
