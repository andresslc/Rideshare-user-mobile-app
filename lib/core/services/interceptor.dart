import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Automatically injects the auth token into every outgoing request.
/// Calls [onTokenBlacklisted] when a 401 is received.
///
class DioInterceptor extends Interceptor {
  final Function onTokenBlacklisted;

  DioInterceptor({required this.onTokenBlacklisted});

  bool _shouldBlacklist(Response? response) {
    final message = response?.data['message'];

    // ✅ Skip blacklist for
    if (message == 'Incorrect current password!') return false;

    return response?.statusCode == 401 ||
        message == 'Your profile is paused' ||
        message == 'Invalid or expired token provided' ||
        message == 'Your profile is incomplete' ||
        message == 'Unauthorized - Please relogin' ||
        message == 'No such User found - Access denied';
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_shouldBlacklist(response)) {
      onTokenBlacklisted();
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_shouldBlacklist(err.response)) {
      onTokenBlacklisted();
    }
    super.onError(err, handler);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    super.onRequest(options, handler);
    debugPrint("Request::::::${options.uri}");
    debugPrint("Method::::::${options.method}");
    debugPrint("Headers::::::${options.headers}");
    debugPrint("QueryParms:::::::${options.queryParameters}");
    debugPrint("Body::::::${options.data}");
  }
}

/// Callback type alias for void callbacks.
typedef VoidCallback = void Function();
