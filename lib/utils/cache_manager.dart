import 'dart:async';

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry(this.data, this.timestamp, this.ttl);

  bool get isExpired => DateTime.now().isAfter(timestamp.add(ttl));
}

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, CacheEntry> _cache = {};
  Timer? _cleanupTimer;

  static const Duration _defaultTtl = Duration(minutes: 5);
  static const Duration _cleanupInterval = Duration(minutes: 1);

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) => _cleanup());
  }

  void _cleanup() {
    final keysToRemove = <String>[];
    
    _cache.forEach((key, entry) {
      if (entry.isExpired) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  void set<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = CacheEntry(
      value,
      DateTime.now(),
      ttl ?? _defaultTtl,
    );

    if (_cleanupTimer == null || !_cleanupTimer!.isActive) {
      _startCleanupTimer();
    }
  }

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T?;
  }

  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;

    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  void clearExpired() {
    _cleanup();
  }

  int get size => _cache.length;

  List<String> get keys => _cache.keys.toList();

  // Cache patterns for common API calls
  String userProfileKey(String userId) => 'user_profile_$userId';
  String racesKey([String? season]) => 'races_${season ?? 'current'}';
  String driversKey([String? season]) => 'drivers_${season ?? 'current'}';
  String tournamentsKey(String userId) => 'tournaments_$userId';
  String betResultsKey(String userId, {int page = 1}) => 'bet_results_${userId}_page_$page';
  String tournamentStandingsKey(int tournamentId) => 'tournament_standings_$tournamentId';

  void dispose() {
    clear();
  }
}