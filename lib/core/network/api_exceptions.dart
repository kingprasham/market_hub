class ApiException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  ApiException(this.message, {this.code, this.details});

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class TimeoutException extends ApiException {
  TimeoutException(super.message);
}

class BadRequestException extends ApiException {
  BadRequestException(super.message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class ForbiddenException extends ApiException {
  ForbiddenException(super.message);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  ValidationException(super.message, this.errors);

  String? getFieldError(String field) {
    if (errors == null) return null;
    final fieldErrors = errors![field];
    if (fieldErrors is List && fieldErrors.isNotEmpty) {
      return fieldErrors.first.toString();
    } else if (fieldErrors is String) {
      return fieldErrors;
    }
    return null;
  }
}

class ServerException extends ApiException {
  ServerException(super.message);
}

class CacheException extends ApiException {
  CacheException(super.message);
}
