import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage service that uses platform-specific storage
/// - iOS/Android: flutter_secure_storage (Keychain/Keystore)
/// - Web: localStorage with expiration tracking via SharedPreferences
class SecureStorageService {
  // Singleton pattern
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  // Secure storage for mobile platforms
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // SharedPreferences for web platform
  SharedPreferences? _prefs;

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpirationKey = 'token_expiration';

  /// Initialize the storage service
  Future<void> init() async {
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  /// Write a value to secure storage
  Future<void> write(String key, String value) async {
    if (kIsWeb) {
      // Web: use SharedPreferences
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      // iOS/Android: use secure storage
      await _secureStorage.write(key: key, value: value);
    }
  }

  /// Read a value from secure storage
  Future<String?> read(String key) async {
    if (kIsWeb) {
      // Web: use SharedPreferences
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      // iOS/Android: use secure storage
      return await _secureStorage.read(key: key);
    }
  }

  /// Delete a value from secure storage
  Future<void> delete(String key) async {
    if (kIsWeb) {
      // Web: use SharedPreferences
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      // iOS/Android: use secure storage
      await _secureStorage.delete(key: key);
    }
  }

  /// Delete all values from secure storage
  Future<void> deleteAll() async {
    if (kIsWeb) {
      // Web: clear only auth-related keys
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_tokenExpirationKey);
    } else {
      // iOS/Android: use secure storage
      await _secureStorage.deleteAll();
    }
  }

  // ----- Token-specific methods -----

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    await write(_accessTokenKey, token);

    // For web, also save expiration timestamp
    if (kIsWeb) {
      // Calculate expiration (typically JWT tokens are valid for ~15-60 minutes)
      // We'll store the current timestamp to check validity later
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setInt(_tokenExpirationKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    final token = await read(_accessTokenKey);

    // For web, check if token is expired based on storage time
    if (kIsWeb && token != null) {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final storedTime = prefs.getInt(_tokenExpirationKey);

      if (storedTime != null) {
        final storedDateTime = DateTime.fromMillisecondsSinceEpoch(storedTime);
        final now = DateTime.now();

        // Consider token potentially expired after 14 minutes (conservative)
        // The actual validation will be done by JWT decoder
        if (now.difference(storedDateTime).inMinutes >= 14) {
          debugPrint('[SecureStorage] Web token may be expired (stored ${now.difference(storedDateTime).inMinutes} minutes ago)');
        }
      }
    }

    return token;
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await write(_refreshTokenKey, token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await read(_refreshTokenKey);
  }

  /// Delete all tokens
  Future<void> deleteTokens() async {
    await delete(_accessTokenKey);
    await delete(_refreshTokenKey);
    if (kIsWeb) {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove(_tokenExpirationKey);
    }
  }

  /// Check if we have stored tokens
  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  /// Save both tokens at once
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }
}
