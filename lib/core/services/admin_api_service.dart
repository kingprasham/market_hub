import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import '../constants/api_constants.dart';
import '../storage/local_storage.dart';
import '../services/firebase_messaging_service.dart';
import '../../data/models/user/user_model.dart';

/// Admin API Service
/// Handles all communication with Market Hub Admin Dashboard APIs
class AdminApiService extends GetxService {
  static AdminApiService get to => Get.find();

  late Dio _dio;

  // User state
  final Rx<Map<String, dynamic>?> currentUser = Rx(null);
  final RxBool isLoggedIn = false.obs;

  Future<AdminApiService> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.adminBaseUrl,
      connectTimeout:
          const Duration(milliseconds: ApiConstants.connectionTimeout),
      receiveTimeout:
          const Duration(milliseconds: ApiConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Check if we have a saved token
    final token = await LocalStorage.getAuthToken();
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      await _loadProfile();
    }

    return this;
  }

  /// Load user profile
  Future<void> _loadProfile() async {
    try {
      final response = await _dio.get(ApiConstants.adminProfile);
      if (response.data['success'] == true) {
        currentUser.value = response.data['user'];
        isLoggedIn.value = true;
        
        // Save to local storage
        try {
          final userModel = UserModel.fromJson(response.data['user']);
          await LocalStorage.saveUser(userModel);
        } catch (e) {
          debugPrint('Error saving user to local storage: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      await logout();
    }
  }

  // ==================== AUTH ====================

  /// Update Profile
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    String? whatsapp,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.adminUpdateProfile, data: {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        if (whatsapp != null) 'whatsapp': whatsapp,
      });

      // Handle response - might be String or Map
      final data = response.data is String 
          ? jsonDecode(response.data) 
          : response.data;
          
      if (data['success'] == true) {
        // Update local user state
        currentUser.value = data['user'];
      }
      
      return data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String pin,
    String? whatsapp,
    int? planId,
    String? visitingCardPath,
  }) async {
    try {
      debugPrint('=== REGISTRATION DEBUG ===');
      debugPrint('fullName: $fullName');
      debugPrint('email: $email');
      debugPrint('phone: $phone');
      debugPrint('whatsapp: $whatsapp');
      debugPrint('planId: $planId');
      debugPrint('visitingCardPath: $visitingCardPath');
      
      // Get FCM token
      String? deviceToken;
      try {
        deviceToken = FirebaseMessagingService.to.fcmToken;
        debugPrint('FCM Token: $deviceToken');
      } catch (e) {
        debugPrint('Failed to get FCM token: $e');
      }
      
      final Map<String, dynamic> formFields = {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'pin': pin,
        if (deviceToken != null) 'fcm_token': deviceToken,
      };
      
      if (whatsapp != null && whatsapp.isNotEmpty) {
        formFields['whatsapp'] = whatsapp;
      }
      if (planId != null) {
        formFields['plan_id'] = planId;
      }
      
      // Add visiting card file if exists
      if (visitingCardPath != null && visitingCardPath.isNotEmpty) {
        final file = File(visitingCardPath);
        if (await file.exists()) {
          debugPrint('Visiting card file exists, adding to form');
          formFields['visiting_card'] = await MultipartFile.fromFile(
            visitingCardPath,
            filename: visitingCardPath.split('/').last,
          );
        } else {
          debugPrint('WARNING: Visiting card file does not exist: $visitingCardPath');
        }
      }
      
      FormData formData = FormData.fromMap(formFields);
      debugPrint('FormData fields: ${formData.fields}');
      debugPrint('FormData files: ${formData.files.length}');
      debugPrint('Sending to: ${ApiConstants.adminBaseUrl}${ApiConstants.adminRegister}');

      final response = await _dio.post(
        ApiConstants.adminRegister,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');
      debugPrint('Response data type: ${response.data.runtimeType}');
      
      // Handle response - might be String or Map depending on server config
      if (response.data is String) {
        return jsonDecode(response.data) as Map<String, dynamic>;
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('DioException: ${e.type} - ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      return _handleError(e);
    } catch (e, stackTrace) {
      debugPrint('Registration Exception: $e');
      debugPrint('Stack trace: $stackTrace');
      return {'success': false, 'error': 'Registration failed: ${e.toString()}'};
    }
  }

  /// Verify email with OTP
  Future<Map<String, dynamic>> verifyEmail({
    required int userId,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.adminVerifyEmail, data: {
        'user_id': userId,
        'otp': otp,
      });
      // Handle response - might be String or Map depending on server config
      if (response.data is String) {
        return jsonDecode(response.data) as Map<String, dynamic>;
      }
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Set PIN
  Future<Map<String, dynamic>> setPin({
    required int userId,
    required String pin,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.adminSetPin, data: {
        'user_id': userId,
        'pin': pin,
      });
      // Handle response
      if (response.data is String) {
        return jsonDecode(response.data) as Map<String, dynamic>;
      }
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Login with email and PIN
  Future<Map<String, dynamic>> login({
    required String email,
    required String pin,
  }) async {
    try {
      // Get FCM token for push notifications
      String? deviceToken;
      try {
        deviceToken = FirebaseMessagingService.to.fcmToken;
      } catch (_) {}

      final response = await _dio.post(ApiConstants.adminLogin, data: {
        'email': email,
        'pin': pin,
        if (deviceToken != null) 'device_token': deviceToken,
        if (deviceToken != null) 'fcm_token': deviceToken, // Send as fcm_token too
      });

      // Handle response logic
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data) as Map<String, dynamic>;
      } else {
        responseData = response.data;
      }

      if (responseData['success'] == true) {
        final authToken = responseData['auth_token'];
        await LocalStorage.saveAuthToken(authToken);
        _dio.options.headers['Authorization'] = 'Bearer $authToken';
        currentUser.value = responseData['user'];
        isLoggedIn.value = true;
        
        // Save to local storage
        try {
          final userModel = UserModel.fromJson(responseData['user']);
          await LocalStorage.saveUser(userModel);
        } catch (e) {
          debugPrint('Error saving user to local storage: $e');
        }
      }

      return responseData;
    } on DioException catch (e) {
      debugPrint('LOGIN ERROR: ${e.message}');
      debugPrint('LOGIN ERROR TYPE: ${e.type}');
      debugPrint('LOGIN ERROR RESPONSE: ${e.response}');
      return _handleError(e);
    } catch (e) {
      debugPrint('LOGIN UNEXPECTED ERROR: $e');
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  /// Check account approval status
  Future<Map<String, dynamic>> checkStatus({
    int? userId,
    String? email,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.adminCheckStatus,
        queryParameters: {
          if (userId != null) 'user_id': userId,
          if (email != null) 'email': email,
        },
      );
      // Handle response
      if (response.data is String) {
        return jsonDecode(response.data) as Map<String, dynamic>;
      }
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Logout
  Future<void> logout() async {
    await LocalStorage.logout();
    _dio.options.headers.remove('Authorization');
    currentUser.value = null;
    isLoggedIn.value = false;
  }

  /// Request PIN reset via email
  Future<Map<String, dynamic>> forgotPin({
    required String email,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.adminForgotPin, data: {
        'email': email,
      });
      // Handle response
      if (response.data is String) {
        return jsonDecode(response.data) as Map<String, dynamic>;
      }
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Verify PIN reset OTP
  Future<Map<String, dynamic>> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.adminVerifyResetOtp, data: {
        'email': email,
        'otp': otp,
      });
      // Handle response
      if (response.data is String) {
        return jsonDecode(response.data) as Map<String, dynamic>;
      }
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Reset PIN with token
  Future<Map<String, dynamic>> resetPin({
    required String resetToken,
    required String newPin,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.adminResetPin, data: {
        'reset_token': resetToken,
        'new_pin': newPin,
      });
      // Handle response
      if (response.data is String) {
        return jsonDecode(response.data) as Map<String, dynamic>;
      }
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ==================== PLANS ====================

  /// Get available plans
  Future<List<Map<String, dynamic>>> getPlans() async {
    try {
      final response = await _dio.get(ApiConstants.adminPlans);
      
      final data = response.data is String 
          ? jsonDecode(response.data) 
          : response.data;
          
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['plans'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Failed to get plans: $e');
      return [];
    }
  }

  // ==================== CONTENT ====================

  /// Get home updates
  Future<List<Map<String, dynamic>>> getHomeUpdates() async {
    try {
      final response = await _dio.get(ApiConstants.adminHomeUpdates);
      
      final data = response.data is String 
          ? jsonDecode(response.data) 
          : response.data;

      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['updates'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Failed to get home updates: $e');
      return [];
    }
  }

  /// Get news (English)
  Future<List<Map<String, dynamic>>> getNews() async {
    try {
      final response = await _dio.get(ApiConstants.adminNews);
      
      final data = response.data is String 
          ? jsonDecode(response.data) 
          : response.data;

      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['news'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Failed to get news: $e');
      return [];
    }
  }

  /// Get news (Hindi)
  Future<List<Map<String, dynamic>>> getHindiNews() async {
    try {
      final response = await _dio.get(ApiConstants.adminHindiNews);
      
      final data = response.data is String 
          ? jsonDecode(response.data) 
          : response.data;

      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['news'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Failed to get Hindi news: $e');
      return [];
    }
  }

  /// Get circulars
  Future<List<Map<String, dynamic>>> getCirculars() async {
    try {
      final response = await _dio.get(ApiConstants.adminCirculars);
      
      final data = response.data is String 
          ? jsonDecode(response.data) 
          : response.data;

      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(
            data['circulars'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Failed to get circulars: $e');
      return [];
    }
  }

  /// Get latest updates (combined news, circulars, home updates)
  Future<List<Map<String, dynamic>>> getLatestUpdates({int limit = 20}) async {
    try {
      debugPrint('Fetching latest updates from API...');
      final response = await _dio.get(
        ApiConstants.adminLatestUpdates,
        queryParameters: {'limit': limit},
      );
      
      final data = response.data is String 
          ? jsonDecode(response.data) 
          : response.data;

      if (data['success'] == true && data['updates'] != null && (data['updates'] as List).isNotEmpty) {
        debugPrint('Successfully fetched latest updates from primary endpoint');
        return List<Map<String, dynamic>>.from(data['updates'] ?? []);
      }
      
      debugPrint('Primary endpoint returned empty or failed, trying fallback...');
      throw Exception('Primary endpoint empty');
    } catch (e) {
      debugPrint('Primary latest-updates endpoint failed: $e. Using fallback aggregation.');
      
      // Fallback: Fetch from individual endpoints and aggregate
      try {
        final results = await Future.wait([
          getNews(),
          getHindiNews(),
          getCirculars(),
          getHomeUpdates(),
        ]);
        
        final news = results[0];
        final hindiNews = results[1];
        final circulars = results[2];
        final homeUpdates = results[3];
        
        final List<Map<String, dynamic>> aggregated = [];
        
        // Helper to add content type and normalize
        void addItems(List<Map<String, dynamic>> items, String type, String prefix) {
          for (var item in items) {
            aggregated.add({
              ...item,
              'id': '${prefix}_${item['id']}', // Unique ID
              'contentType': type, // Required by NotificationsController
              'createdAt': item['createdAt'] ?? DateTime.now().toIso8601String(),
            });
          }
        }
        
        addItems(news, 'news', 'news');
        addItems(hindiNews, 'hindi_news', 'hindi');
        addItems(circulars, 'circular', 'circular');
        addItems(homeUpdates, 'home_update', 'update');
        
        // Sort by date descending
        aggregated.sort((a, b) {
          final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
        
        // Limit results
        if (aggregated.length > limit) {
          return aggregated.sublist(0, limit);
        }
        
        return aggregated;
      } catch (fallbackError) {
        debugPrint('Fallback aggregation failed: $fallbackError');
        return [];
      }
    }
  }

  // ==================== SETTINGS ====================

  /// Get app settings (T&C, About, Contact)
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _dio.get(ApiConstants.adminSettings);
      
      final data = response.data is String 
          ? jsonDecode(response.data) 
          : response.data;

      if (data['success'] == true) {
        return data['settings'] ?? {};
      }
      return {};
    } catch (e) {
      debugPrint('Failed to get settings: $e');
      return {};
    }
  }

  /// Submit feedback
  Future<Map<String, dynamic>> submitFeedback({
    required String message,
    int? rating,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.adminFeedback, data: {
        'message': message,
        if (rating != null) 'rating': rating,
      });
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ==================== PRICE ALERTS ====================

  /// Get user's price alerts
  Future<List<Map<String, dynamic>>> getPriceAlerts() async {
    try {
      final response = await _dio.get(ApiConstants.adminGetPriceAlerts);

      final data = response.data is String
          ? jsonDecode(response.data)
          : response.data;

      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['alerts'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Failed to get price alerts: $e');
      return [];
    }
  }

  /// Add a new price alert
  Future<Map<String, dynamic>> addPriceAlert({
    required String metal,
    required String location,
    required double targetPrice,
    required String conditionType,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.adminAddPriceAlert, data: {
        'metal': metal,
        'location': location,
        'target_price': targetPrice,
        'condition_type': conditionType,
      });

      final data = response.data is String
          ? jsonDecode(response.data)
          : response.data;

      return data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Delete a price alert
  Future<Map<String, dynamic>> deletePriceAlert(int alertId) async {
    try {
      final response = await _dio.post(ApiConstants.adminDeletePriceAlert, data: {
        'alert_id': alertId,
      });

      final data = response.data is String
          ? jsonDecode(response.data)
          : response.data;

      return data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ==================== ERROR HANDLING ====================

  Map<String, dynamic> _handleError(DioException e) {
    debugPrint('API Error: ${e.message}');
    debugPrint('API Error Response: ${e.response?.data}');
    debugPrint('API Error Status: ${e.response?.statusCode}');
    String errorMessage = 'Something went wrong';

    try {
      var responseData = e.response?.data;
      // Parse string response to Map if needed
      if (responseData is String && responseData.isNotEmpty) {
        try {
          responseData = jsonDecode(responseData);
        } catch (_) {
          // Not valid JSON
        }
      }
      if (responseData is Map) {
        errorMessage = responseData['error'] ?? errorMessage;
      }
    } catch (_) {}

    if (e.type == DioExceptionType.connectionError) {
      errorMessage = 'No internet connection';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      errorMessage = 'Connection timeout';
    }

    return {'success': false, 'error': errorMessage};
  }
}
