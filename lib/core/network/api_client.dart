import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import '../storage/local_storage.dart';
import 'api_exceptions.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  bool _isInitialized = false;

  Dio get dio {
    if (!_isInitialized) {
      _initialize();
    }
    return _dio;
  }

  void _initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
    ));

    _isInitialized = true;
  }

  // GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Upload file with multipart
  Future<Response<T>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? data,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?data,
        fieldName: await MultipartFile.fromFile(filePath),
      });

      return await dio.post<T>(
        path,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handler
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('Connection timeout. Please try again.');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final data = error.response?.data;
        String message = 'Something went wrong';

        if (data is Map<String, dynamic>) {
          message = data['message'] ?? message;
        }

        switch (statusCode) {
          case 400:
            return BadRequestException(message);
          case 401:
            return UnauthorizedException('Session expired. Please login again.');
          case 403:
            return ForbiddenException('Access denied.');
          case 404:
            return NotFoundException('Resource not found.');
          case 422:
            return ValidationException(message, data?['errors']);
          case 500:
          case 502:
          case 503:
            return ServerException('Server error. Please try again later.');
          default:
            return ApiException(message);
        }

      case DioExceptionType.cancel:
        return ApiException('Request was cancelled.');

      case DioExceptionType.connectionError:
        return NetworkException('No internet connection.');

      default:
        return ApiException('Something went wrong. Please try again.');
    }
  }
}

// Auth Interceptor
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await LocalStorage.getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired, logout user
      LocalStorage.logout();
      // Navigate to login - handled by the app
    }
    handler.next(err);
  }
}
