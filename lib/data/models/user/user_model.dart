import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String fullName;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String whatsappNumber;

  @HiveField(4)
  final String whatsappCountryCode;

  @HiveField(5)
  final String phoneNumber;

  @HiveField(6)
  final String countryCode;

  @HiveField(7)
  final String pincode;

  @HiveField(8)
  final String? visitingCardUrl;

  @HiveField(9)
  final bool isEmailVerified;

  @HiveField(10)
  final bool isApproved;

  @HiveField(11)
  final bool isRejected;

  @HiveField(12)
  final String? rejectionMessage;

  @HiveField(13)
  final String? planId;

  @HiveField(14)
  final String? planName;

  @HiveField(15)
  final DateTime? planExpiryDate;

  @HiveField(16)
  final String? deviceToken;

  @HiveField(17)
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.whatsappNumber,
    required this.whatsappCountryCode,
    required this.phoneNumber,
    required this.countryCode,
    required this.pincode,
    this.visitingCardUrl,
    this.isEmailVerified = false,
    this.isApproved = false,
    this.isRejected = false,
    this.rejectionMessage,
    this.planId,
    this.planName,
    this.planExpiryDate,
    this.deviceToken,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      whatsappNumber: json['whatsappNumber'] ?? '',
      whatsappCountryCode: json['whatsappCountryCode'] ?? '+91',
      phoneNumber: json['phoneNumber'] ?? '',
      countryCode: json['countryCode'] ?? '+91',
      pincode: json['pincode'] ?? '',
      visitingCardUrl: json['visitingCardUrl'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      isApproved: json['isApproved'] ?? false,
      isRejected: json['isRejected'] ?? false,
      rejectionMessage: json['rejectionMessage'],
      planId: json['planId'],
      planName: json['planName'],
      planExpiryDate: json['planExpiryDate'] != null
          ? DateTime.parse(json['planExpiryDate'])
          : null,
      deviceToken: json['deviceToken'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'whatsappNumber': whatsappNumber,
      'whatsappCountryCode': whatsappCountryCode,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'pincode': pincode,
      'visitingCardUrl': visitingCardUrl,
      'isEmailVerified': isEmailVerified,
      'isApproved': isApproved,
      'isRejected': isRejected,
      'rejectionMessage': rejectionMessage,
      'planId': planId,
      'planName': planName,
      'planExpiryDate': planExpiryDate?.toIso8601String(),
      'deviceToken': deviceToken,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? whatsappNumber,
    String? whatsappCountryCode,
    String? phoneNumber,
    String? countryCode,
    String? pincode,
    String? visitingCardUrl,
    bool? isEmailVerified,
    bool? isApproved,
    bool? isRejected,
    String? rejectionMessage,
    String? planId,
    String? planName,
    DateTime? planExpiryDate,
    String? deviceToken,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      whatsappCountryCode: whatsappCountryCode ?? this.whatsappCountryCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      pincode: pincode ?? this.pincode,
      visitingCardUrl: visitingCardUrl ?? this.visitingCardUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isApproved: isApproved ?? this.isApproved,
      isRejected: isRejected ?? this.isRejected,
      rejectionMessage: rejectionMessage ?? this.rejectionMessage,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      planExpiryDate: planExpiryDate ?? this.planExpiryDate,
      deviceToken: deviceToken ?? this.deviceToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isPlanExpired {
    if (planExpiryDate == null) return true;
    return DateTime.now().isAfter(planExpiryDate!);
  }

  int get daysUntilExpiry {
    if (planExpiryDate == null) return 0;
    return planExpiryDate!.difference(DateTime.now()).inDays;
  }
}
