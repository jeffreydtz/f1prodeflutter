import 'package:flutter/foundation.dart';

class Logger {
  // Set this to true to enable all logs by default
  static bool _enableLogs = true;

  static void log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void error(String message) {
    if (kDebugMode) {
      debugPrint('ERROR: $message');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('INFO: $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('WARNING: $message');
    }
  }

  static void enableLogs() {
    _enableLogs = true;
  }

  static void disableLogs() {
    _enableLogs = false;
  }

  static bool isEnabled() {
    return _enableLogs;
  }
}
