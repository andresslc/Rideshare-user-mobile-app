import 'dart:io';

import 'package:dio/dio.dart';

// Custom exceptions for network-related errors
class NoInternetException implements Exception {
  final String message;

  NoInternetException([this.message = 'No internet connection']);
}

class ConnectionException implements Exception {
  final String message;

  ConnectionException([this.message = 'Unable to connect']);
}

class AuthenticationException implements Exception {
  final String message;

  AuthenticationException([this.message = 'Authentication failed']);
}

class RateLimitException implements Exception {
  final String message;

  RateLimitException([this.message = 'Rate limit exceeded']);
}

class RedirectException implements Exception {
  final String message;

  RedirectException([this.message = 'Redirect error']);
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException([this.message = 'Request timed out']);
}

// NetworkException handler
class NetworkExceptions {
  static String handleException(DioException e) {
    if (e.error is SocketException) {
      return 'No internet connection';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return "Request Timed Out";
    } else if (e.type == DioExceptionType.badResponse) {
      return "Received invalid status code:";
    } else if (e.type == DioExceptionType.cancel) {
      return 'Request was cancelled';
    } else if (e.type == DioExceptionType.unknown) {
      return 'An unknown error occurred';
    } else {
      return 'Unexpected error: ${e.message}';
    }
  }
}
