import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for synchronizing local time with server time
/// This prevents users from bypassing bet cutoffs by changing device time
class TimeSyncService {
  static final TimeSyncService _instance = TimeSyncService._internal();
  factory TimeSyncService() => _instance;
  TimeSyncService._internal();

  /// Time difference between server and local time (server - local)
  Duration _timeDelta = Duration.zero;

  /// Last sync timestamp
  DateTime? _lastSync;

  /// Sync interval (re-sync every 5 minutes)
  static const Duration _syncInterval = Duration(minutes: 5);

  /// Get the current server time
  DateTime get serverTime => DateTime.now().add(_timeDelta);

  /// Get time delta (for debugging)
  Duration get timeDelta => _timeDelta;

  /// Check if we need to re-sync
  bool get needsSync {
    if (_lastSync == null) return true;
    return DateTime.now().difference(_lastSync!) > _syncInterval;
  }

  /// Sync time with server by reading the Date header from an API response
  Future<bool> syncWithServer(String baseUrl) async {
    try {
      // Make a lightweight HEAD request to get server time from headers
      final response = await http.head(
        Uri.parse('$baseUrl/f1/races/'),
      ).timeout(const Duration(seconds: 5));

      // Get server time from Date header
      final dateHeader = response.headers['date'];
      if (dateHeader != null) {
        final serverTime = HttpDate.parse(dateHeader);
        final localTime = DateTime.now();

        // Calculate delta
        _timeDelta = serverTime.difference(localTime);
        _lastSync = localTime;

        debugPrint('[TimeSync] Synced with server. Delta: ${_timeDelta.inSeconds}s');
        return true;
      }

      debugPrint('[TimeSync] No date header in response');
      return false;
    } catch (e) {
      debugPrint('[TimeSync] Error syncing: $e');
      return false;
    }
  }

  /// Reset time sync (useful for testing)
  void reset() {
    _timeDelta = Duration.zero;
    _lastSync = null;
  }
}

/// HTTP Date parser (simplified for RFC 1123 format)
class HttpDate {
  static DateTime parse(String date) {
    return DateTime.parse(date);
  }
}
