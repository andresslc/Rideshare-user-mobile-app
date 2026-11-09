import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:ride_app/core/config/app_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../di/service_locator.dart';
import '../utils/app_log.dart';
import 'storage_service.dart';

class SocketService with WidgetsBindingObserver {
  final StorageService _storageService;
  final void Function(String message)? onAuthRequired;

  io.Socket? _socket;
  final StreamController<SocketConnectionStatus> _statusController =
      StreamController<SocketConnectionStatus>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  String? _lastErrorMessage;
  bool _isDisconnecting = false;
  bool _isAppInBackground = false;

  SocketService(this._storageService, {this.onAuthRequired}) {
    WidgetsBinding.instance.addObserver(this);
  }

  Stream<SocketConnectionStatus> get statusStream => _statusController.stream;
  Stream<String> get errorStream => _errorController.stream;
  bool get isConnected => _socket?.connected ?? false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _isAppInBackground =
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused;
  }

  Future<void> connect({
    String? socketUrl,
    String? token,
    Map<String, dynamic>? query,
    bool forceReconnect = false,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    if (isConnected && !forceReconnect) return;

    if (forceReconnect) {
      disconnect();
    }

    final String resolvedSocketUrl = (socketUrl ?? locator<AppConfig>().baseUrl)
        .trim();
    if (resolvedSocketUrl.isEmpty) {
      throw const FormatException('Socket URL is empty.');
    }

    final String? authToken = token ?? _storageService.getToken;
    if (authToken == null || authToken.isEmpty) {
      throw StateError('Cannot connect socket without an authenticated user.');
    }
    final Map<String, String> headers = <String, String>{};
    headers['token'] = authToken;

    _statusController.add(SocketConnectionStatus.connecting);
    _isDisconnecting = false;

    final Completer<void> connectedCompleter = Completer<void>();

    _socket = io.io(
      resolvedSocketUrl,
      io.OptionBuilder()
          .setTransports(<String>['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .enableForceNew()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(5000)
          .setReconnectionDelayMax(5000)
          .setExtraHeaders(headers)
          .setTimeout(60000)
          .build(),
    );

    _registerCoreListeners(connectedCompleter);
    _socket?.connect();

    await connectedCompleter.future.timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        'Socket connect timeout after ${timeout.inSeconds}s',
      ),
    );
  }

  Future<dynamic> emitWithAck(
    String event,
    dynamic data, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final io.Socket socket = await _requireConnectedSocket();
    final Completer<dynamic> ackCompleter = Completer<dynamic>();

    final Timer timer = Timer(timeout, () {
      if (!ackCompleter.isCompleted) {
        ackCompleter.completeError(
          TimeoutException('Ack timeout for event <$event>.'),
        );
      }
    });

    socket.emitWithAck(
      event,
      data,
      ack: (dynamic ackPayload) {
        if (!ackCompleter.isCompleted) {
          ackCompleter.complete(_normalizeAckPayload(ackPayload));
        }
      },
    );

    try {
      return await ackCompleter.future;
    } finally {
      timer.cancel();
    }
  }

  Future<SocketAckResponse> emitWithAckResponse(
    String event,
    dynamic data, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final dynamic raw = await emitWithAck(event, data, timeout: timeout);
    return SocketAckResponse.fromDynamic(raw);
  }

  Future<void> emit(String event, [dynamic data]) async {
    final io.Socket socket = await _requireConnectedSocket();
    socket.emit(event, data);
    log('Socket emit <$event>: $data', name: 'SocketService');
  }

  Future<void> on(String event, void Function(dynamic payload) callback) async {
    log('socket on: $event', name: 'ride socket');
    (await _requireConnectedSocket()).on(event, callback);
  }

  Future<void> onAny(
    void Function(String event, dynamic payload) callback,
  ) async {
    (await _requireConnectedSocket()).onAny((dynamic event, dynamic payload) {
      log('Received event: $event');
      log('Received payload: $payload');
      callback(event.toString(), payload);
      log('Callback executed for event: $event');
    });
  }

  void off(String event, [void Function(dynamic payload)? callback]) {
    final io.Socket? socket = _socket;
    if (socket == null) return;
    if (callback == null) {
      socket.off(event);
      return;
    }
    socket.off(event, callback);
  }

  void offAny() {
    _socket?.offAny();
  }

  Future<void> refreshConnectionWithLatestToken() async {
    final bool wasConnected = isConnected;
    if (!wasConnected) return;
    final String socketUrl = _socket?.io.uri ?? locator<AppConfig>().baseUrl;
    disconnect();
    await connect(socketUrl: socketUrl, forceReconnect: true);
  }

  /// Update the socket URL at runtime (e.g. from Remote Config).
  /// If the URL has changed and the socket is connected, it will reconnect.
  Future<void> updateSocketUrl(String newSocketUrl) async {
    if (newSocketUrl.isEmpty) return;
    final String currentUrl = _socket?.io.uri ?? '';
    if (currentUrl != newSocketUrl) {
      log('🔄 Socket URL updated → $newSocketUrl', name: 'SocketService');
      final bool wasConnected = isConnected;
      if (wasConnected) {
        disconnect();
        await connect(socketUrl: newSocketUrl, forceReconnect: true);
      }
    }
  }

  void disconnect() {
    _isDisconnecting = true;
    _socket?.offAny();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _statusController.add(SocketConnectionStatus.disconnected);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disconnect();
    _errorController.close();
    _statusController.close();
  }

  /// Tries to (re)connect up to [maxAttempts] times with [retryDelay] between
  /// each attempt. Throws [StateError] if the socket is still not connected
  /// after all retries.
  Future<io.Socket> _requireConnectedSocket({
    int maxAttempts = 4,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    final io.Socket? socket = _socket;
    if (socket == null) {
      throw 'Socket is not initialized!';
    }

    if (socket.connected) return socket;

    // Not connected — attempt to reconnect up to maxAttempts times.
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      log(
        'Socket not connected. Reconnect attempt $attempt/$maxAttempts…',
        name: 'SocketService',
      );
      _statusController.add(SocketConnectionStatus.reconnecting);
      socket.connect();

      // Wait for the connection to establish (or the delay to elapse).
      await Future<void>.delayed(retryDelay);

      if (_socket != null && _socket!.connected) {
        log('Reconnect succeeded on attempt $attempt.', name: 'SocketService');
        return _socket!;
      }
    }

    // All attempts exhausted.
    log(
      'Socket reconnect failed after $maxAttempts attempts.',
      name: 'SocketService',
    );
    throw 'Internal Server Error';
  }

  void _registerCoreListeners(Completer<void> connectedCompleter) {
    _socket?.onConnect((_) {
      log('Socket connected', name: 'SocketService');
      debugPrint(_green('Socket connected'));
      _lastErrorMessage = null;
      _isDisconnecting = false;
      _statusController.add(SocketConnectionStatus.connected);
      if (!connectedCompleter.isCompleted) {
        connectedCompleter.complete();
      }
    });

    _socket?.onDisconnect((dynamic reason) {
      log('Socket disconnected: $reason', name: 'SocketService');
      debugPrint(_green('Socket disconnected: $reason'));
      _statusController.add(SocketConnectionStatus.disconnected);
      if (_isDisconnecting) return;
      if (_isAppInBackground) return;
      final String? message = _normalizeDisconnectReason(reason);
      if (message != null) {
        _publishError(message);
      }
    });

    _socket?.onReconnectAttempt((_) {
      _statusController.add(SocketConnectionStatus.reconnecting);
    });

    _socket?.onError((dynamic error) {
      log('Socket error: $error', name: 'SocketService');
      _statusController.add(SocketConnectionStatus.error);
      final String message = _normalizeSocketErrorMessage(error);

      if (!_isAppInBackground) {
        _publishError(message);
      }
      _handleAuthFailureIfNeeded(error, message);
      if (!connectedCompleter.isCompleted) {
        connectedCompleter.completeError(SocketConnectionException(message));
      }
    });

    _socket?.onConnectError((dynamic error) {
      log('Socket connect error: $error', name: 'SocketService');
      _statusController.add(SocketConnectionStatus.error);
      final String message = _normalizeSocketErrorMessage(error);

      if (!_isAppInBackground) {
        _publishError(message);
      }
      _handleAuthFailureIfNeeded(error, message);

      if (!connectedCompleter.isCompleted) {
        connectedCompleter.completeError(
          SocketConnectionException(_normalizeSocketErrorMessage(error)),
        );
      }
    });

    _socket?.onAny((dynamic event, dynamic payload) {
      log('Socket onAny <$event>:payload: $payload', name: 'SocketService');

      final String message = _normalizeSocketErrorMessage(payload);
      // if (!_isAppInBackground) {
      //   _publishError(message);
      // }
      _handleAuthFailureIfNeeded(payload, message);
    });
  }

  void _publishError(String message) {
    final String normalized = message.trim();
    if (normalized.isEmpty) return;
    if (_lastErrorMessage == normalized) return;
    _lastErrorMessage = normalized;
    if (!_errorController.isClosed) {
      _errorController.add(normalized);
    }
  }

  String _normalizeSocketErrorMessage(dynamic error) {
    final String raw = _extractErrorMessage(error);
    final String lower = raw.toLowerCase();

    if (lower.contains('status code: 502')) {
      return 'Live ride updates are temporarily unavailable. Please wait.';
    }

    if (lower.contains('status code: 401') ||
        lower.contains('status code: 401') ||
        lower.contains('status code: 403')) {
      return 'Your session expired. Please sign in again.';
    }

    if (lower.contains('timeout')) {
      return 'Unable to connect to live ride updates right now. Please wait.';
    }

    if (lower.contains('socketexception') ||
        lower.contains('websocketexception') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup')) {
      return 'Please check your internet connection and try again.';
    }

    if (raw.isEmpty) {
      return 'Unable to connect to live ride updates right now.';
    }

    return raw;
  }

  String _extractErrorMessage(dynamic error) {
    if (error is Map) {
      final dynamic message = error['message'];
      if (message != null) {
        return message.toString().trim();
      }
      return error.toString().trim();
    }

    if (error is List && error.isNotEmpty) {
      return _extractErrorMessage(error.first);
    }

    return error?.toString().trim() ?? '';
  }

  String? _normalizeDisconnectReason(dynamic reason) {
    final String raw = reason?.toString().trim() ?? '';
    if (raw.isEmpty || raw == 'io client disconnect') {
      return null;
    }

    final String lower = raw.toLowerCase();
    if (lower == 'transport close' ||
        lower == 'ping timeout' ||
        lower == 'transport error') {
      return 'Connection to live ride updates was lost. Retrying...';
    }

    return null;
  }

  bool _isAuthFailureMessage(String message) {
    final String lower = message.toLowerCase();
    return lower.contains('re-login') ||
        lower.contains('please re-login') ||
        lower.contains('relgin') ||
        lower.contains('sign in again') ||
        lower.contains('session expired') ||
        lower.contains('unauthorized') ||
        lower.contains('token expired');
  }

  void _handleAuthFailureIfNeeded(dynamic error, String message) {
    if (!_isAuthFailureMessage(message)) {
      return;
    }

    disconnect();
    onAuthRequired?.call(message);
  }

  dynamic _normalizeAckPayload(dynamic ackPayload) {
    if (ackPayload is List<dynamic>) {
      if (ackPayload.isEmpty) return <String, dynamic>{};
      return _normalizeAckPayload(ackPayload.first);
    }

    if (ackPayload is String) {
      final dynamic decoded = _tryParseJson(ackPayload);
      return decoded ?? ackPayload;
    }

    return ackPayload;
  }

  dynamic _tryParseJson(String source) {
    try {
      return jsonDecode(source);
    } catch (_) {
      return null;
    }
  }

  String _green(String text) => '\x1B[32m$text\x1B[0m';
}

enum SocketConnectionStatus {
  initial,
  connecting,
  connected,
  reconnecting,
  disconnected,
  error,
}

class SocketAckResponse {
  final bool success;
  final String message;
  final dynamic data;
  final Map<String, dynamic> raw;

  const SocketAckResponse({
    required this.success,
    required this.message,
    this.data,
    this.raw = const <String, dynamic>{},
  });

  factory SocketAckResponse.fromDynamic(dynamic source) {
    final dynamic normalized = _normalize(source);
    if (normalized is Map<String, dynamic>) {
      return SocketAckResponse(
        success: normalized['success'] == true,
        message: (normalized['message'] ?? '').toString(),
        data: normalized['data'],
        raw: normalized,
      );
    }

    if (normalized is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(normalized);
      return SocketAckResponse(
        success: map['success'] == true,
        message: (map['message'] ?? '').toString(),
        data: map['data'],
        raw: map,
      );
    }

    return SocketAckResponse(
      success: false,
      message: 'Invalid ack payload format',
      data: normalized,
      raw: <String, dynamic>{'raw': normalized},
    );
  }

  static dynamic _normalize(dynamic payload) {
    if (payload is List<dynamic>) {
      if (payload.isEmpty) return <String, dynamic>{};
      return _normalize(payload.first);
    }

    if (payload is String) {
      try {
        return jsonDecode(payload);
      } catch (_) {
        return payload;
      }
    }

    return payload;
  }
}

class SocketConnectionException implements Exception {
  final String message;

  const SocketConnectionException(this.message);

  @override
  String toString() => message;
}
