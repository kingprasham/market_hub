class NewsModel {
  final String id;
  final String title;
  final String description;
  final String? summary;
  final String? imageUrl;
  final String? pdfUrl;
  final String? sourceLink;
  final String newsType;
  final List<String> targetPlanIds;
  final DateTime publishedAt;
  final DateTime createdAt;
  final bool isUrgent;
  final String? _sourceName;

  NewsModel({
    required this.id,
    required this.title,
    required this.description,
    this.summary,
    this.imageUrl,
    this.pdfUrl,
    this.sourceLink,
    required this.newsType,
    required this.targetPlanIds,
    required this.publishedAt,
    required this.createdAt,
    this.isUrgent = false,
    String? sourceName,
  }) : _sourceName = sourceName;

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    // Parse targetPlans - can be from targetPlanIds, targetPlans, or plans field
    List<String> parsedTargetPlans = ['all'];
    if (json['targetPlanIds'] != null) {
      parsedTargetPlans = List<String>.from(json['targetPlanIds']);
    } else if (json['targetPlans'] != null) {
      parsedTargetPlans = List<String>.from(json['targetPlans']);
    } else if (json['plans'] != null) {
      parsedTargetPlans = List<String>.from(json['plans']);
    }

    // Parse date treating timezone-less strings as local (IST) time from server.
    // Do NOT add 'Z' — the server stores IST timestamps without offset markers.
    DateTime parseDate(dynamic dateStr) {
      if (dateStr == null || dateStr.toString().isEmpty) return DateTime.now();
      try {
        return DateTime.parse(dateStr.toString().trim());
      } catch (e) {
        return DateTime.now();
      }
    }

    return NewsModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      summary: json['summary'],
      imageUrl: json['imageUrl'] ?? json['image'],
      pdfUrl: json['pdfUrl'] ?? json['pdf'],
      sourceLink: json['sourceLink'] ?? json['link'],
      newsType: json['newsType'] ?? json['type'] ?? 'english',
      targetPlanIds: parsedTargetPlans,
      publishedAt: parseDate(json['publishedAt'] ?? json['createdAt']),
      createdAt: parseDate(json['createdAt']),
      isUrgent: json['isUrgent'] ?? json['urgent'] ?? false,
      sourceName: json['sourceName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'summary': summary,
      'imageUrl': imageUrl,
      'pdfUrl': pdfUrl,
      'sourceLink': sourceLink,
      'newsType': newsType,
      'targetPlanIds': targetPlanIds,
      'publishedAt': publishedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isUrgent': isUrgent,
      'sourceName': sourceName,
    };
  }

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasPdf => pdfUrl != null && pdfUrl!.isNotEmpty;
  bool get hasLink => sourceLink != null && sourceLink!.isNotEmpty;
  
  // Aliases for compatibility
  DateTime get timestamp => publishedAt;
  String get content => description;
  String? get source => sourceLink;
  
  /// Get source name - either from explicit field or extracted from URL
  String get sourceName {
    if (_sourceName != null && _sourceName!.isNotEmpty) return _sourceName!;
    if (sourceLink == null || sourceLink!.isEmpty) return 'Market Hub';
    try {
      final uri = Uri.parse(sourceLink!);
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return 'News';
    }
  }
}

class CircularModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String pdfUrl;
  final List<String> targetPlanIds;
  final DateTime publishedAt;
  final DateTime createdAt;

  CircularModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.pdfUrl,
    required this.targetPlanIds,
    required this.publishedAt,
    required this.createdAt,
  });

  factory CircularModel.fromJson(Map<String, dynamic> json) {
    // Parse date treating timezone-less strings as local (IST) time from server.
    DateTime parseDate(dynamic dateStr) {
      if (dateStr == null || dateStr.toString().isEmpty) return DateTime.now();
      try {
        return DateTime.parse(dateStr.toString().trim());
      } catch (e) {
        return DateTime.now();
      }
    }

    return CircularModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      pdfUrl: json['pdfUrl'] ?? json['pdf'] ?? '',
      targetPlanIds: List<String>.from(json['targetPlanIds'] ?? json['plans'] ?? []),
      publishedAt: parseDate(json['publishedAt'] ?? json['createdAt']),
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'pdfUrl': pdfUrl,
      'targetPlanIds': targetPlanIds,
      'publishedAt': publishedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class EconomicEventModel {
  final String id;
  final String eventName;
  final String country;
  final String countryCode;
  final DateTime eventTime;
  final String impact;
  final String? actual;
  final String? forecast;
  final String? previous;

  EconomicEventModel({
    required this.id,
    required this.eventName,
    required this.country,
    required this.countryCode,
    required this.eventTime,
    required this.impact,
    this.actual,
    this.forecast,
    this.previous,
  });

  factory EconomicEventModel.fromJson(Map<String, dynamic> json) {
    return EconomicEventModel(
      id: (json['_id'] ?? json['id'] ?? json['eventName'] ?? '').toString(),
      eventName: json['eventName'] ?? json['event'] ?? '',
      country: json['country'] ?? '',
      countryCode: json['countryCode'] ?? '',
      eventTime: json['eventTime'] != null
          ? DateTime.parse(json['eventTime'])
          : DateTime.now(),
      impact: json['impact'] ?? 'low',
      actual: json['actual'],
      forecast: json['forecast'],
      previous: json['previous'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventName': eventName,
      'country': country,
      'countryCode': countryCode,
      'eventTime': eventTime.toIso8601String(),
      'impact': impact,
      'actual': actual,
      'forecast': forecast,
      'previous': previous,
    };
  }

  bool get isHighImpact => impact == 'high';
  bool get isMediumImpact => impact == 'medium';
  bool get isLowImpact => impact == 'low';
}
