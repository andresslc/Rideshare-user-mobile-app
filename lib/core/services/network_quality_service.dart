import 'dart:async';

import 'package:dio/dio.dart';
import 'package:ride_app/core/utils/app_log.dart';

enum NetworkQuality { good, degraded }

/// Monitors real API reachability and request timeouts to detect slow or
/// unreliable internet (distinct from [ConnectivityService], which only knows
/// if Wi‑Fi/mobile radio is on).
class NetworkQualityService {
  static const Duration pingInterval = Duration(seconds: 20);
  static const Duration pingTimeout = Duration(seconds: 5);
  static const Duration maxAcceptableLatency = Duration(seconds: 4);
  static const int failuresForDegraded = 2;
  static const int successesForRecovery = 2;

  final StreamController<NetworkQuality> _qualityController =
      StreamController<NetworkQuality>.broadcast();

  Stream<NetworkQuality> get qualityStream => _qualityController.stream;

  NetworkQuality _quality = NetworkQuality.good;
  NetworkQuality get lastQuality => _quality;

  Timer? _pingTimer;
  bool _isForeground = true;
  bool _isChecking = false;
  int _consecutiveFailures = 0;
  int _consecutiveSuccesses = 0;
  String _baseUrl = '';

  late final Dio _pingDio = Dio(
    BaseOptions(
      connectTimeout: pingTimeout,
      receiveTimeout: pingTimeout,
      sendTimeout: pingTimeout,
      validateStatus: (int? status) => status != null && status < 500,
    ),
  );

  void configure({required String baseUrl}) {
    final String trimmed = baseUrl.trim();
    if (trimmed.isEmpty) return;
    _baseUrl = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    _pingDio.options.baseUrl = _baseUrl;
  }

  void setForeground(bool isForeground) {
    _isForeground = isForeground;
    if (isForeground) {
      startMonitoring();
      unawaited(checkNow());
    } else {
      stopMonitoring();
    }
  }

  void startMonitoring() {
    _pingTimer?.cancel();
    if (!_isForeground || _baseUrl.isEmpty) return;

    _pingTimer = Timer.periodic(pingInterval, (_) {
      unawaited(checkNow());
    });
  }

  void stopMonitoring() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void recordRequestSuccess() {
    _applyProbeResult(success: true, source: 'api_success');
  }

  void recordRequestTimeout() {
    _applyProbeResult(success: false, source: 'api_timeout');
  }

  Future<void> checkNow() async {
    if (_isChecking || _baseUrl.isEmpty) return;
    _isChecking = true;
    try {
      final bool reachable = await _pingServer();
      _applyProbeResult(success: reachable, source: 'ping');
    } finally {
      _isChecking = false;
    }
  }

  Future<bool> _pingServer() async {
    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      await _pingDio.get<Object?>(
        '/',
        options: Options(
          headers: const <String, String>{'X-Network-Quality-Ping': '1'},
        ),
      );
      stopwatch.stop();
      if (stopwatch.elapsed > maxAcceptableLatency) {
        log(
          'Network ping slow: ${stopwatch.elapsed.inMilliseconds}ms',
          name: 'NetworkQuality',
        );
        return false;
      }
      return true;
    } on DioException catch (e, st) {
      log('Network ping failed: ${e.type} $e\n$st', name: 'NetworkQuality');
      return false;
    } catch (e, st) {
      log('Network ping error: $e\n$st', name: 'NetworkQuality');
      return false;
    }
  }

  void _applyProbeResult({required bool success, required String source}) {
    if (success) {
      _consecutiveFailures = 0;
      _consecutiveSuccesses++;
      if (_quality == NetworkQuality.degraded &&
          _consecutiveSuccesses >= successesForRecovery) {
        _setQuality(NetworkQuality.good, source: source);
      }
      return;
    }

    _consecutiveSuccesses = 0;
    _consecutiveFailures++;
    if (_quality == NetworkQuality.good &&
        _consecutiveFailures >= failuresForDegraded) {
      _setQuality(NetworkQuality.degraded, source: source);
    }
  }

  void _setQuality(NetworkQuality next, {required String source}) {
    if (_quality == next) return;
    _quality = next;
    log('Network quality → $next (via $source)', name: 'NetworkQuality');
    _qualityController.add(next);
  }

  void dispose() {
    stopMonitoring();
    _qualityController.close();
  }
}
