class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final Map<String, dynamic>? details;
  
  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.details,
  });

  factory ApiException.network([String? message]) {
    return ApiException(
      message: message ?? 'Network error. Please check your connection.',
      errorCode: 'NETWORK_ERROR',
    );
  }

  factory ApiException.unauthorized([String? message]) {
    return ApiException(
      message: message ?? 'Authentication failed. Please login again.',
      statusCode: 401,
      errorCode: 'UNAUTHORIZED',
    );
  }

  factory ApiException.forbidden([String? message]) {
    return ApiException(
      message: message ?? 'Access denied. You don\'t have permission.',
      statusCode: 403,
      errorCode: 'FORBIDDEN',
    );
  }

  factory ApiException.notFound([String? message]) {
    return ApiException(
      message: message ?? 'Resource not found.',
      statusCode: 404,
      errorCode: 'NOT_FOUND',
    );
  }

  factory ApiException.serverError([String? message]) {
    return ApiException(
      message: message ?? 'Server error. Please try again later.',
      statusCode: 500,
      errorCode: 'SERVER_ERROR',
    );
  }

  factory ApiException.validation(String message, [Map<String, dynamic>? details]) {
    return ApiException(
      message: message,
      statusCode: 400,
      errorCode: 'VALIDATION_ERROR',
      details: details,
    );
  }

  factory ApiException.timeout([String? message]) {
    return ApiException(
      message: message ?? 'Request timeout. Please try again.',
      errorCode: 'TIMEOUT',
    );
  }

  @override
  String toString() {
    return 'ApiException: $message${statusCode != null ? ' ($statusCode)' : ''}';
  }

  String getUserFriendlyMessage() {
    switch (errorCode) {
      case 'NETWORK_ERROR':
        return 'No internet connection. Please check your network and try again.';
      case 'UNAUTHORIZED':
        return 'Your session has expired. Please login again.';
      case 'FORBIDDEN':
        return 'You don\'t have permission to perform this action.';
      case 'NOT_FOUND':
        return 'The requested information could not be found.';
      case 'SERVER_ERROR':
        return 'Our servers are experiencing issues. Please try again later.';
      case 'TIMEOUT':
        return 'The request is taking too long. Please check your connection and try again.';
      case 'VALIDATION_ERROR':
        return message;
      default:
        return message;
    }
  }
}