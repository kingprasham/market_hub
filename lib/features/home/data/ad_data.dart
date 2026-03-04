/// Data model for ad content displayed in the home carousel and detail screen.
class AdData {
  final int id;
  final String imagePath;
  final String carouselTitle;
  final String carouselSubtitle;
  final String companyName;
  final String heading;
  final List<AdInfoItem> infoItems;
  final List<AdContactItem> contacts;
  final String? disclaimer;

  const AdData({
    required this.id,
    required this.imagePath,
    required this.carouselTitle,
    required this.carouselSubtitle,
    required this.companyName,
    required this.heading,
    required this.infoItems,
    required this.contacts,
    this.disclaimer,
  });

  factory AdData.fromJson(Map<String, dynamic> json) {
    List<AdInfoItem> parsedInfo = [];
    if (json['infoItems'] is List) {
      for (var item in json['infoItems']) {
        if (item is Map<String, dynamic>) {
          parsedInfo.add(AdInfoItem.fromJson(item));
        }
      }
    }

    List<AdContactItem> parsedContacts = [];
    if (json['contacts'] is List) {
      for (var contact in json['contacts']) {
        if (contact is Map<String, dynamic>) {
          parsedContacts.add(AdContactItem.fromJson(contact));
        }
      }
    }

    return AdData(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      imagePath: json['imagePath']?.toString() ?? '',
      carouselTitle: json['carouselTitle']?.toString() ?? '',
      carouselSubtitle: json['carouselSubtitle']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      heading: json['heading']?.toString() ?? '',
      infoItems: parsedInfo,
      contacts: parsedContacts,
      disclaimer: json['disclaimer']?.toString(),
    );
  }
}

class AdInfoItem {
  final String title;
  final String description;
  final String iconName;

  const AdInfoItem({
    required this.title,
    required this.description,
    this.iconName = 'info',
  });

  factory AdInfoItem.fromJson(Map<String, dynamic> json) {
    return AdInfoItem(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      iconName: json['iconName']?.toString() ?? 'info',
    );
  }
}

class AdContactItem {
  final String type; // 'phone', 'email', 'website', 'whatsapp'
  final String label;
  final String uri;

  const AdContactItem({
    required this.type,
    required this.label,
    required this.uri,
  });

  factory AdContactItem.fromJson(Map<String, dynamic> json) {
    return AdContactItem(
      type: json['type']?.toString() ?? 'phone',
      label: json['label']?.toString() ?? '',
      uri: json['uri']?.toString() ?? '',
    );
  }
}
