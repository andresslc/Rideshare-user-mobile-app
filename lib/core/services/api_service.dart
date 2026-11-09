import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/navigation/routes.dart';
import 'package:ride_app/core/services/device_info_service.dart';

import '../navigation/app_router.dart';
import '../utils/app_log.dart';
import 'interceptor.dart';
import 'network_quality_interceptor.dart';
import 'socket_service.dart';
import 'storage_service.dart';

/// Generic Dio HTTP client wrapper.
///
/// Provides `get`, `post`, `put`, `patch`, `delete` with
/// automatic auth-token injection and logging.
class ApiService {
  final Dio _dio;
  final StorageService _storage;
  final DeviceInfoService deviceInfoService;
  final SocketService _socketService;

  ApiService(
    this._storage,
    this.deviceInfoService,
    this._socketService, {
    String? baseUrl,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl ?? '',
           connectTimeout: const Duration(seconds: 30),
           receiveTimeout: const Duration(seconds: 30),
         ),
       ) {
    _dio.interceptors.addAll([
      LogInterceptor(
        responseBody: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        logPrint: (o) => log(o.toString(), name: 'Dio'),
      ),
      DioInterceptor(
        onTokenBlacklisted: () {
          unawaited(_clearSessionAfterAuthFailure());
        },
      ),
      NetworkQualityInterceptor(),
    ]);
  }

  // ── Token management ───────────────────────────────────────────────────

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<void> _clearSessionAfterAuthFailure() async {
    await _storage.clearAuthSession();
    clearAuthToken();
    _socketService.disconnect();
    final BuildContext? ctx = rootNavigatorKey.currentState?.overlay?.context;
    if (ctx != null && ctx.mounted) {
      ctx.goNamed(Routes.login.name, extra: true);
    }
  }

  void setDeviceIds() {
    final Map<String, String> apiHeaders = {
      'devicemodel': deviceInfoService.safeDeviceName,
      'deviceuniqueid':
          "${deviceInfoService.safeDeviceID}_${_storage.getFCMToken}",
    };

    _dio.options.headers.addAll(apiHeaders);
    // return apiHeaders;
  }

  /// Update the base URL at runtime (e.g. from Remote Config).
  void updateBaseUrl(String newBaseUrl) {
    if (newBaseUrl.isEmpty) return;
    if (_dio.options.baseUrl != newBaseUrl) {
      log('🔄 Base URL updated → $newBaseUrl', name: 'ApiService');
      _dio.options.baseUrl = newBaseUrl;
    }
  }

  void clearDeviceIds() {
    _dio.options.headers.remove('devicemodel');
    _dio.options.headers.remove('deviceuniqueid');
  }

  // ── HTTP methods ───────────────────────────────────────────────────────

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    return _dio.get(
      endpoint,
      queryParameters: queryParameters,
      options: headers != null ? Options(headers: headers) : null,
      cancelToken: cancelToken,
    );
  }

  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    return _dio.post(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: headers != null ? Options(headers: headers) : null,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }

  Future<Response> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.put(endpoint, data: data, queryParameters: queryParameters);
  }

  Future<Response> patch(String endpoint, {dynamic data}) async {
    return _dio.patch(endpoint, data: data);
  }

  Future<Response> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.delete(endpoint, data: data, queryParameters: queryParameters);
  }
}
