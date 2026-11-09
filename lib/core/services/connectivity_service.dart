import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionChangeController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionChangeController.stream;

  bool _hasConnection = true;
  bool get lastStatus => _hasConnection;

  late StreamSubscription<List<ConnectivityResult>> _subscription;

  Future<void> initialize() async {
    final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
    _checkStatus(result);
    _subscription = _connectivity.onConnectivityChanged.listen(_checkStatus);
  }

  void _checkStatus(List<ConnectivityResult> result) {
    bool previousConnection = _hasConnection;
    _hasConnection = !result.contains(ConnectivityResult.none);

    if (previousConnection != _hasConnection) {
      _connectionChangeController.add(_hasConnection);
    }
  }

  Future<bool> get hasConnection async {
    final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
    _hasConnection = !result.contains(ConnectivityResult.none);
    return _hasConnection;
  }

  void dispose() {
    _subscription.cancel();
    _connectionChangeController.close();
  }
}
