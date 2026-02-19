# Market Hub - API & Data Models Reference

## 1. DATA MODELS

### 1.1 User Models

```dart
// lib/data/models/user/user_model.dart
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
  final String? pin;
  
  @HiveField(10)
  final bool isEmailVerified;
  
  @HiveField(11)
  final bool isApproved;
  
  @HiveField(12)
  final bool isRejected;
  
  @HiveField(13)
  final String? rejectionMessage;
  
  @HiveField(14)
  final String? planId;
  
  @HiveField(15)
  final String? planName;
  
  @HiveField(16)
  final DateTime? planExpiryDate;
  
  @HiveField(17)
  final String? deviceToken;
  
  @HiveField(18)
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
    this.pin,
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
      id: json['_id'] ?? json['id'],
      fullName: json['fullName'],
      email: json['email'],
      whatsappNumber: json['whatsappNumber'],
      whatsappCountryCode: json['whatsappCountryCode'],
      phoneNumber: json['phoneNumber'],
      countryCode: json['countryCode'],
      pincode: json['pincode'],
      visitingCardUrl: json['visitingCardUrl'],
      pin: json['pin'],
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
      createdAt: DateTime.parse(json['createdAt']),
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
      'pin': pin,
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
    String? pin,
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
      pin: pin ?? this.pin,
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
}
```

### 1.2 Registration Request

```dart
// lib/data/models/user/registration_request.dart
import 'dart:convert';

class RegistrationRequest {
  final String fullName;
  final String email;
  final String whatsappNumber;
  final String whatsappCountryCode;
  final String phoneNumber;
  final String countryCode;
  final String pincode;
  final String visitingCardBase64;

  RegistrationRequest({
    required this.fullName,
    required this.email,
    required this.whatsappNumber,
    required this.whatsappCountryCode,
    required this.phoneNumber,
    required this.countryCode,
    required this.pincode,
    required this.visitingCardBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'whatsappNumber': whatsappNumber,
      'whatsappCountryCode': whatsappCountryCode,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'pincode': pincode,
      'visitingCard': visitingCardBase64,
    };
  }
}
```

### 1.3 Plan Model

```dart
// lib/data/models/plan/plan_model.dart
class PlanModel {
  final String id;
  final String name;
  final String description;
  final List<String> features;
  final double price;
  final String duration; // 'monthly', 'quarterly', 'half-yearly', 'yearly'
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
      id: json['_id'] ?? json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      features: List<String>.from(json['features'] ?? []),
      price: (json['price'] ?? 0).toDouble(),
      duration: json['duration'] ?? 'monthly',
      durationDays: json['durationDays'] ?? 30,
      isPopular: json['isPopular'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
    );
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
}
```

### 1.4 Market Data Models

```dart
// lib/data/models/market/future_data_model.dart
class FutureDataModel {
  final String id;
  final String symbol;
  final String name;
  final String exchange; // 'LME', 'SHFE', 'COMEX'
  final double lastTradePrice;
  final double previousClose;
  final double high;
  final double low;
  final double open;
  final double change;
  final double changePercent;
  final int volume;
  final DateTime lastTradeTime;
  final DateTime updatedAt;

  FutureDataModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.lastTradePrice,
    required this.previousClose,
    required this.high,
    required this.low,
    required this.open,
    required this.change,
    required this.changePercent,
    required this.volume,
    required this.lastTradeTime,
    required this.updatedAt,
  });

  factory FutureDataModel.fromJson(Map<String, dynamic> json) {
    return FutureDataModel(
      id: json['_id'] ?? json['id'] ?? json['symbol'],
      symbol: json['symbol'],
      name: json['name'],
      exchange: json['exchange'],
      lastTradePrice: (json['lastTradePrice'] ?? 0).toDouble(),
      previousClose: (json['previousClose'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      open: (json['open'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['changePercent'] ?? 0).toDouble(),
      volume: json['volume'] ?? 0,
      lastTradeTime: DateTime.parse(json['lastTradeTime']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  bool get isPositive => change >= 0;
  
  String get changeDisplay => isPositive 
      ? '+${change.toStringAsFixed(2)}' 
      : change.toStringAsFixed(2);
  
  String get changePercentDisplay => isPositive 
      ? '+${changePercent.toStringAsFixed(2)}%' 
      : '${changePercent.toStringAsFixed(2)}%';
}
```

```dart
// lib/data/models/market/fx_model.dart
class FXModel {
  final String id;
  final String currencyPair;
  final String baseCurrency;
  final String quoteCurrency;
  final double rate;
  final double previousRate;
  final double change;
  final double changePercent;
  final double high;
  final double low;
  final DateTime updatedAt;

  FXModel({
    required this.id,
    required this.currencyPair,
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.rate,
    required this.previousRate,
    required this.change,
    required this.changePercent,
    required this.high,
    required this.low,
    required this.updatedAt,
  });

  factory FXModel.fromJson(Map<String, dynamic> json) {
    return FXModel(
      id: json['_id'] ?? json['id'],
      currencyPair: json['currencyPair'],
      baseCurrency: json['baseCurrency'],
      quoteCurrency: json['quoteCurrency'],
      rate: (json['rate'] ?? 0).toDouble(),
      previousRate: (json['previousRate'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['changePercent'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
```

```dart
// lib/data/models/market/reference_rate_model.dart
class ReferenceRateModel {
  final String id;
  final String type; // 'SBI_TT', 'F_BILL', 'RBI_TT'
  final String currency;
  final double buyRate;
  final double sellRate;
  final DateTime effectiveDate;
  final DateTime updatedAt;

  ReferenceRateModel({
    required this.id,
    required this.type,
    required this.currency,
    required this.buyRate,
    required this.sellRate,
    required this.effectiveDate,
    required this.updatedAt,
  });

  factory ReferenceRateModel.fromJson(Map<String, dynamic> json) {
    return ReferenceRateModel(
      id: json['_id'] ?? json['id'],
      type: json['type'],
      currency: json['currency'] ?? 'USD',
      buyRate: (json['buyRate'] ?? 0).toDouble(),
      sellRate: (json['sellRate'] ?? 0).toDouble(),
      effectiveDate: DateTime.parse(json['effectiveDate']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
```

### 1.5 Spot Price Models

```dart
// lib/data/models/market/spot_price_model.dart
class MetalCategoryModel {
  final String id;
  final String name;
  final String iconPath;

  MetalCategoryModel({
    required this.id,
    required this.name,
    required this.iconPath,
  });

  factory MetalCategoryModel.fromJson(Map<String, dynamic> json) {
    return MetalCategoryModel(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      iconPath: json['iconPath'] ?? 'assets/metals/${json['name'].toLowerCase()}.png',
    );
  }
}

class SpotPriceModel {
  final String id;
  final String metalId;
  final String metalName;
  final String location;
  final String locationCode;
  final double price;
  final double previousPrice;
  final double change;
  final double changePercent;
  final String unit; // 'per kg', 'per ton'
  final DateTime updatedAt;

  SpotPriceModel({
    required this.id,
    required this.metalId,
    required this.metalName,
    required this.location,
    required this.locationCode,
    required this.price,
    required this.previousPrice,
    required this.change,
    required this.changePercent,
    required this.unit,
    required this.updatedAt,
  });

  factory SpotPriceModel.fromJson(Map<String, dynamic> json) {
    return SpotPriceModel(
      id: json['_id'] ?? json['id'],
      metalId: json['metalId'],
      metalName: json['metalName'],
      location: json['location'],
      locationCode: json['locationCode'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      previousPrice: (json['previousPrice'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['changePercent'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'per kg',
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  bool get isPositive => change >= 0;
  String get formattedPrice => '₹${price.toStringAsFixed(2)}';
}
```

### 1.6 Content Models

```dart
// lib/data/models/content/update_model.dart
class UpdateModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? pdfUrl;
  final DateTime createdAt;

  UpdateModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.pdfUrl,
    required this.createdAt,
  });

  factory UpdateModel.fromJson(Map<String, dynamic> json) {
    return UpdateModel(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      description: json['description'] ?? json['note'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'],
      pdfUrl: json['pdfUrl'] ?? json['pdf'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasPdf => pdfUrl != null && pdfUrl!.isNotEmpty;
}
```

```dart
// lib/data/models/content/news_model.dart
class NewsModel {
  final String id;
  final String title;
  final String description;
  final String? summary;
  final String? imageUrl;
  final String? pdfUrl;
  final String? sourceLink;
  final String newsType; // 'english', 'hindi', 'live_feed'
  final List<String> targetPlanIds;
  final DateTime publishedAt;
  final DateTime createdAt;

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
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      summary: json['summary'],
      imageUrl: json['imageUrl'] ?? json['image'],
      pdfUrl: json['pdfUrl'] ?? json['pdf'],
      sourceLink: json['sourceLink'] ?? json['link'],
      newsType: json['newsType'] ?? json['type'] ?? 'english',
      targetPlanIds: List<String>.from(json['targetPlanIds'] ?? json['plans'] ?? []),
      publishedAt: DateTime.parse(json['publishedAt'] ?? json['createdAt']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
```

```dart
// lib/data/models/content/circular_model.dart
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
    return CircularModel(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      pdfUrl: json['pdfUrl'] ?? json['pdf'],
      targetPlanIds: List<String>.from(json['targetPlanIds'] ?? json['plans'] ?? []),
      publishedAt: DateTime.parse(json['publishedAt'] ?? json['createdAt']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
```

```dart
// lib/data/models/content/economic_event_model.dart
class EconomicEventModel {
  final String id;
  final String eventName;
  final String country;
  final String countryCode;
  final DateTime eventTime;
  final String impact; // 'low', 'medium', 'high'
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
      id: json['_id'] ?? json['id'] ?? json['eventName'],
      eventName: json['eventName'] ?? json['event'],
      country: json['country'],
      countryCode: json['countryCode'] ?? '',
      eventTime: DateTime.parse(json['eventTime'] ?? json['time']),
      impact: json['impact'] ?? 'low',
      actual: json['actual'],
      forecast: json['forecast'],
      previous: json['previous'],
    );
  }

  bool get isHighImpact => impact == 'high';
  bool get isMediumImpact => impact == 'medium';
}
```

### 1.7 Watchlist Model

```dart
// lib/data/models/watchlist/watchlist_item_model.dart
class WatchlistItemModel {
  final String id;
  final String userId;
  final String itemId;
  final String itemType; // 'future', 'spot'
  final String symbol;
  final String name;
  final String? exchange;
  final String? location;
  final DateTime addedAt;

  WatchlistItemModel({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.itemType,
    required this.symbol,
    required this.name,
    this.exchange,
    this.location,
    required this.addedAt,
  });

  factory WatchlistItemModel.fromJson(Map<String, dynamic> json) {
    return WatchlistItemModel(
      id: json['_id'] ?? json['id'],
      userId: json['userId'],
      itemId: json['itemId'],
      itemType: json['itemType'],
      symbol: json['symbol'],
      name: json['name'],
      exchange: json['exchange'],
      location: json['location'],
      addedAt: DateTime.parse(json['addedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemType': itemType,
      'symbol': symbol,
      'name': name,
      'exchange': exchange,
      'location': location,
    };
  }
}
```

---

## 2. API CONSTANTS

```dart
// lib/core/constants/api_constants.dart
class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://api.markethubindia.com';
  static const String wsUrl = 'wss://api.markethubindia.com/ws';
  
  // Auth Endpoints
  static const String register = '/api/auth/register';
  static const String verifyEmail = '/api/auth/verify-email';
  static const String resendOtp = '/api/auth/resend-otp';
  static const String updateEmail = '/api/auth/update-email';
  static const String setPin = '/api/auth/set-pin';
  static const String login = '/api/auth/login';
  static const String forgotPin = '/api/auth/forgot-pin';
  static const String resetPin = '/api/auth/reset-pin';
  static const String checkApproval = '/api/auth/check-approval';
  static const String logout = '/api/auth/logout';
  
  // Plans
  static const String plans = '/api/plans';
  static const String selectPlan = '/api/plans/select';
  
  // Home Updates
  static const String updates = '/api/updates';
  
  // Market Data
  static const String marketLme = '/api/market/lme';
  static const String marketShfe = '/api/market/shfe';
  static const String marketComex = '/api/market/comex';
  static const String marketFx = '/api/market/fx';
  static const String referenceRates = '/api/market/reference-rates';
  static const String warehouseStock = '/api/market/warehouse-stock';
  static const String settlement = '/api/market/settlement';
  
  // Spot Price
  static const String baseMetals = '/api/spot/base-metals';
  static const String bme = '/api/spot/bme';
  
  // Content
  static const String news = '/api/content/news';
  static const String hindiNews = '/api/content/hindi-news';
  static const String circulars = '/api/content/circulars';
  static const String liveFeed = '/api/content/live-feed';
  static const String economicCalendar = '/api/content/economic-calendar';
  
  // Watchlist
  static const String watchlist = '/api/watchlist';
  static const String watchlistFuture = '/api/watchlist/future';
  static const String watchlistSpot = '/api/watchlist/spot';
  
  // Profile
  static const String profile = '/api/profile';
  static const String feedback = '/api/profile/feedback';
  static const String changePin = '/api/profile/change-pin';
  
  // WebSocket Channels
  static const String wsMarket = '/market';
  static const String wsLme = 'lme';
  static const String wsShfe = 'shfe';
  static const String wsComex = 'comex';
  static const String wsFx = 'fx';
  static const String wsSpot = 'spot';
}
```

---

## 3. API RESPONSE STRUCTURE

```dart
// lib/data/models/api_response.dart
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final ApiError? error;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      error: json['error'] != null 
          ? ApiError.fromJson(json['error']) 
          : null,
    );
  }
}

class ApiError {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  ApiError({
    required this.code,
    required this.message,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] ?? 'UNKNOWN',
      message: json['message'] ?? 'An error occurred',
      details: json['details'],
    );
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  PaginatedResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse(
      items: (json['items'] as List)
          .map((item) => fromJsonT(item))
          .toList(),
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
      hasMore: json['hasMore'] ?? false,
    );
  }
}
```

---

## 4. WEBSOCKET MESSAGE STRUCTURE

```dart
// lib/data/models/websocket_message.dart
class WebSocketMessage {
  final String type; // 'subscribe', 'unsubscribe', 'data', 'error', 'ping', 'pong'
  final String channel;
  final dynamic payload;
  final DateTime timestamp;

  WebSocketMessage({
    required this.type,
    required this.channel,
    this.payload,
    required this.timestamp,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'],
      channel: json['channel'],
      payload: json['payload'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'channel': channel,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Helper constructors
  factory WebSocketMessage.subscribe(String channel) {
    return WebSocketMessage(
      type: 'subscribe',
      channel: channel,
      timestamp: DateTime.now(),
    );
  }

  factory WebSocketMessage.unsubscribe(String channel) {
    return WebSocketMessage(
      type: 'unsubscribe',
      channel: channel,
      timestamp: DateTime.now(),
    );
  }

  factory WebSocketMessage.ping() {
    return WebSocketMessage(
      type: 'ping',
      channel: '',
      timestamp: DateTime.now(),
    );
  }
}
```

---

## 5. ERROR CODES

```dart
// lib/core/constants/error_codes.dart
class ErrorCodes {
  // Authentication Errors
  static const String invalidCredentials = 'AUTH_001';
  static const String emailNotVerified = 'AUTH_002';
  static const String userNotApproved = 'AUTH_003';
  static const String userRejected = 'AUTH_004';
  static const String invalidOtp = 'AUTH_005';
  static const String otpExpired = 'AUTH_006';
  static const String pinMismatch = 'AUTH_007';
  static const String deviceMismatch = 'AUTH_008';
  
  // Validation Errors
  static const String invalidEmail = 'VAL_001';
  static const String invalidPhone = 'VAL_002';
  static const String invalidPincode = 'VAL_003';
  static const String missingField = 'VAL_004';
  
  // User Errors
  static const String userNotFound = 'USER_001';
  static const String userAlreadyExists = 'USER_002';
  static const String planNotSelected = 'USER_003';
  
  // Content Errors
  static const String contentNotFound = 'CONTENT_001';
  static const String accessDenied = 'CONTENT_002';
  
  // Network Errors
  static const String networkError = 'NET_001';
  static const String timeout = 'NET_002';
  static const String serverError = 'NET_003';
  
  // WebSocket Errors
  static const String wsConnectionFailed = 'WS_001';
  static const String wsDisconnected = 'WS_002';
}
```

This document contains all the data models and API structures needed for the Market Hub application.
