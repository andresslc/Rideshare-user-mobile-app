import 'package:flutter/foundation.dart';

enum SessionStatus { unknown, unauthenticated, authenticated }

class SessionController extends ChangeNotifier {
  SessionStatus _status = SessionStatus.unknown;

  SessionStatus get status => _status;
  bool get isAuthenticated => _status == SessionStatus.authenticated;

  void initializeFromToken(String? token) {
    _status = (token != null && token.isNotEmpty)
        ? SessionStatus.authenticated
        : SessionStatus.unauthenticated;
    notifyListeners();
  }

  void setAuthenticated() {
    if (_status == SessionStatus.authenticated) return;
    _status = SessionStatus.authenticated;
    notifyListeners();
  }

  void setUnauthenticated() {
    if (_status == SessionStatus.unauthenticated) return;
    _status = SessionStatus.unauthenticated;
    notifyListeners();
  }
}
