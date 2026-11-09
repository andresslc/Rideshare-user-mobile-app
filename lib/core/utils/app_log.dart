import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// Simple debug logger — only logs in debug mode.
void log(String message, {String name = 'App'}) {
  if (kDebugMode) {
    dev.log(message, name: name);
  }
}
