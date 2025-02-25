import 'package:flutter/foundation.dart';

class Logger {
  // Set this to true to enable all logs by default
  static bool _enableLogs = true;

  static void log(String message) {
    if (_enableLogs) {
      if (kDebugMode) {
        print(message);
      }
    }
  }

  static void error(String message) {
    if (_enableLogs) {
      if (kDebugMode) {
        print('ERROR: $message');
      }
    }
  }

  static void info(String message) {
    if (_enableLogs) {
      if (kDebugMode) {
        print('INFO: $message');
      }
    }
  }

  static void warning(String message) {
    if (_enableLogs) {
      if (kDebugMode) {
        print('WARNING: $message');
      }
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
