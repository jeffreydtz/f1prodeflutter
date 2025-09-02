import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../models/betresult.dart';
import '../models/user.dart';
import '../models/race.dart';
import '../models/tournament.dart';
import '../models/bet.dart';
import '../utils/logger.dart';
import '../utils/api_exception.dart';
import '../utils/cache_manager.dart';

/// Improved ApiService with better error handling, caching, and architecture
class ImprovedApiService {
  static final ImprovedApiService _instance = ImprovedApiService._internal();
  factory ImprovedApiService() => _instance;
  ImprovedApiService._internal();

  static const String baseUrl = 'https://f1prodedjango.vercel.app/api';
  static const Duration defaultTimeout = Duration(seconds: 30);

  final CacheManager _cache = CacheManager();
  final http.Client _httpClient = http.Client();
  
  UserModel? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  
  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _accessToken != null && _currentUser != null;

  // ==================== INITIALIZATION ====================

  /// Initialize the service by loading stored credentials
  Future<bool> initialize() async {
    try {
      await _loadStoredTokens();
      
      if (_accessToken != null) {
        // Verify token validity and refresh if needed
        if (_isTokenExpired(_accessToken!)) {
          final refreshed = await _attemptTokenRefresh();
          if (!refreshed) {
            await logout();
            return false;
          }
        }
        
        // Load user profile
        await _loadUserProfile();
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('[ApiService] Initialization failed: $e');
      return false;
    }
  }

  // ==================== AUTHENTICATION ====================

  /// Login with username and password
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/token/',
        body: {
          'username': username,
          'password': password,
        },
        requiresAuth: false,
      );

      final accessToken = response['access'] as String;
      final refreshToken = response['refresh'] as String;

      await _saveTokens(accessToken, refreshToken);
      await _loadUserProfile();

      return {'success': true, 'message': 'Login successful'};
    } catch (e) {
      Logger.error('[ApiService] Login failed: $e');
      if (e is ApiException) {
        return {'success': false, 'error': e.getUserFriendlyMessage()};
      }
      return {'success': false, 'error': 'Login failed. Please try again.'};
    }
  }

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? favoriteTeam,
    String? avatarBase64,
  }) async {
    try {
      final body = <String, dynamic>{
        'username': username,
        'email': email,
        'password': password,
      };

      if (firstName?.isNotEmpty == true) body['first_name'] = firstName;
      if (lastName?.isNotEmpty == true) body['last_name'] = lastName;
      if (favoriteTeam?.isNotEmpty == true) body['favorite_team'] = favoriteTeam;
      if (avatarBase64?.isNotEmpty == true) body['avatar'] = avatarBase64;

      final response = await _makeRequest(
        'POST',
        '/users/register/',
        body: body,
        requiresAuth: false,
      );

      return {
        'success': response['success'] ?? true,
        'message': response['message'] ?? 'Registration successful',
        'user': response['user'],
      };
    } catch (e) {
      Logger.error('[ApiService] Registration failed: $e');
      if (e is ApiException) {
        return {'success': false, 'error': e.getUserFriendlyMessage()};
      }
      return {'success': false, 'error': 'Registration failed. Please try again.'};
    }
  }

  /// Logout and clear all stored data
  Future<void> logout() async {
    try {
      _currentUser = null;
      _accessToken = null;
      _refreshToken = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_data');
      
      _cache.clear();
    } catch (e) {
      Logger.error('[ApiService] Logout error: $e');
    }
  }

  // ==================== USER MANAGEMENT ====================

  /// Get current user profile
  Future<UserModel?> getUserProfile({bool forceRefresh = false}) async {
    const cacheKey = 'user_profile';
    
    if (!forceRefresh && _cache.has(cacheKey)) {
      final cachedUser = _cache.get<UserModel>(cacheKey);
      if (cachedUser != null) {
        _currentUser = cachedUser;
        return cachedUser;
      }
    }

    try {
      final response = await _makeRequest('GET', '/users/profile/');
      
      if (response['success'] == true && response['profile'] != null) {
        final user = UserModel.fromJson(response['profile']);
        _currentUser = user;
        _cache.set(cacheKey, user, ttl: Duration(minutes: 10));
        
        // Store user data for offline access
        await _storeUserData(user);
        
        return user;
      }
      return null;
    } catch (e) {
      Logger.error('[ApiService] Get profile failed: $e');
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? favoriteTeam,
    String? avatar,
    String? newPassword,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (favoriteTeam != null) body['favorite_team'] = favoriteTeam;
      if (avatar != null) body['avatar'] = avatar;
      if (newPassword?.isNotEmpty == true) body['new_password'] = newPassword;

      await _makeRequest('PATCH', '/users/profile/', body: body);
      
      // Refresh profile data
      await getUserProfile(forceRefresh: true);
      return true;
    } catch (e) {
      Logger.error('[ApiService] Update profile failed: $e');
      return false;
    }
  }

  /// Check username/email availability
  Future<bool> checkAvailability(String fieldType, String value, [String? currentUserId]) async {
    try {
      final body = {
        'field_type': fieldType,
        'value': value,
      };
      
      if (currentUserId != null) {
        body['current_user_id'] = currentUserId;
      }

      final response = await _makeRequest(
        'POST',
        '/users/check-availability/',
        body: body,
        requiresAuth: false,
      );
      
      return response['available'] == true;
    } catch (e) {
      Logger.error('[ApiService] Check availability failed: $e');
      return true; // Assume available on error to avoid blocking users
    }
  }

  // ==================== F1 DATA ====================

  /// Get all races for current season
  Future<List<Race>> getRaces({bool forceRefresh = false}) async {
    final cacheKey = _cache.racesKey();
    
    if (!forceRefresh && _cache.has(cacheKey)) {
      final cachedRaces = _cache.get<List<Race>>(cacheKey);
      if (cachedRaces != null) return cachedRaces;
    }

    try {
      final response = await _makeRequest('GET', '/f1/races/');
      
      List<Race> races = [];
      if (response is Map<String, dynamic> && response['races'] is List) {
        races = (response['races'] as List)
            .map((raceData) => Race.fromJson(raceData))
            .toList();
      } else if (response is List) {
        races = response.map((raceData) => Race.fromJson(raceData)).toList();
      }
      
      _cache.set(cacheKey, races, ttl: Duration(minutes: 30));
      return races;
    } catch (e) {
      Logger.error('[ApiService] Get races failed: $e');
      return [];
    }
  }

  /// Get upcoming races
  Future<List<Race>> getUpcomingRaces({bool forceRefresh = false}) async {
    const cacheKey = 'upcoming_races';
    
    if (!forceRefresh && _cache.has(cacheKey)) {
      final cachedRaces = _cache.get<List<Race>>(cacheKey);
      if (cachedRaces != null) return cachedRaces;
    }

    try {
      final response = await _makeRequest('GET', '/f1/upcoming-races/');
      
      List<Race> races = [];
      if (response is List) {
        races = response.map((raceData) => Race.fromJson(raceData)).toList();
      } else if (response is Map<String, dynamic>) {
        final racesList = response['races'] ?? response['results'] ?? [];
        races = (racesList as List)
            .map((raceData) => Race.fromJson(raceData))
            .toList();
      }
      
      _cache.set(cacheKey, races, ttl: Duration(minutes: 15));
      return races;
    } catch (e) {
      Logger.error('[ApiService] Get upcoming races failed: $e');
      return [];
    }
  }

  /// Get current season drivers
  Future<List<String>> getDrivers({String? season, bool forceRefresh = false}) async {
    final cacheKey = _cache.driversKey(season);
    
    if (!forceRefresh && _cache.has(cacheKey)) {
      final cachedDrivers = _cache.get<List<String>>(cacheKey);
      if (cachedDrivers != null) return cachedDrivers;
    }

    try {
      final params = season != null ? '?season=$season' : '';
      final response = await _makeRequest('GET', '/f1/drivers/$params');
      
      List<String> drivers = [];
      if (response is List) {
        drivers = response.cast<String>();
      } else if (response is Map<String, dynamic>) {
        final driversList = response['drivers'] ?? response['results'] ?? [];
        drivers = (driversList as List).cast<String>();
      }
      
      _cache.set(cacheKey, drivers, ttl: Duration(hours: 1));
      return drivers;
    } catch (e) {
      Logger.error('[ApiService] Get drivers failed: $e');
      return [];
    }
  }

  // ==================== BETTING ====================

  /// Create a new bet
  Future<Map<String, dynamic>> createBet(Bet bet) async {
    try {
      final response = await _makeRequest('POST', '/bets/', body: bet.toJson());
      
      if (response['success'] == true) {
        // Clear cached bet results to force refresh
        _cache.remove(_cache.betResultsKey(_currentUser?.id ?? ''));
        
        return {
          'success': true,
          'message': response['message'] ?? 'Bet created successfully'
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to create bet'
        };
      }
    } catch (e) {
      Logger.error('[ApiService] Create bet failed: $e');
      if (e is ApiException) {
        return {'success': false, 'error': e.getUserFriendlyMessage()};
      }
      return {'success': false, 'error': 'Failed to create bet. Please try again.'};
    }
  }

  /// Get user's bet results with pagination
  Future<List<BetResult>> getUserBetResults({int page = 1, int pageSize = 20, bool forceRefresh = false}) async {
    final cacheKey = _cache.betResultsKey(_currentUser?.id ?? '', page: page);
    
    if (!forceRefresh && _cache.has(cacheKey)) {
      final cachedResults = _cache.get<List<BetResult>>(cacheKey);
      if (cachedResults != null) return cachedResults;
    }

    try {
      final response = await _makeRequest(
        'GET', 
        '/bets/all-results/?page=$page&page_size=$pageSize'
      );
      
      List<BetResult> results = [];
      if (response is Map<String, dynamic> && response['bets'] is List) {
        results = (response['bets'] as List)
            .map((betData) => BetResult.fromJson(betData))
            .toList();
      }
      
      _cache.set(cacheKey, results, ttl: Duration(minutes: 10));
      return results;
    } catch (e) {
      Logger.error('[ApiService] Get bet results failed: $e');
      return [];
    }
  }

  // ==================== TOURNAMENTS ====================

  /// Get user's tournaments
  Future<List<Tournament>> getTournaments({bool forceRefresh = false}) async {
    final cacheKey = _cache.tournamentsKey(_currentUser?.id ?? '');
    
    if (!forceRefresh && _cache.has(cacheKey)) {
      final cachedTournaments = _cache.get<List<Tournament>>(cacheKey);
      if (cachedTournaments != null) return cachedTournaments;
    }

    try {
      final response = await _makeRequest('GET', '/tournaments/');
      
      List<Tournament> tournaments = [];
      if (response is List) {
        tournaments = response
            .map((tournamentData) => Tournament.fromJson(tournamentData))
            .toList();
      } else if (response is Map<String, dynamic>) {
        final tournamentsList = response['tournaments'] ?? response['results'] ?? [];
        tournaments = (tournamentsList as List)
            .map((tournamentData) => Tournament.fromJson(tournamentData))
            .toList();
      }
      
      _cache.set(cacheKey, tournaments, ttl: Duration(minutes: 15));
      return tournaments;
    } catch (e) {
      Logger.error('[ApiService] Get tournaments failed: $e');
      return [];
    }
  }

  /// Create a new tournament
  Future<Map<String, dynamic>> createTournament(String name) async {
    try {
      final response = await _makeRequest(
        'POST', 
        '/tournaments/', 
        body: {'name': name}
      );
      
      // Clear tournaments cache
      _cache.remove(_cache.tournamentsKey(_currentUser?.id ?? ''));
      
      return {'success': true, 'tournament': response};
    } catch (e) {
      Logger.error('[ApiService] Create tournament failed: $e');
      if (e is ApiException) {
        return {'success': false, 'error': e.getUserFriendlyMessage()};
      }
      return {'success': false, 'error': 'Failed to create tournament'};
    }
  }

  /// Join a tournament with invite code
  Future<Map<String, dynamic>> joinTournament(String inviteCode) async {
    try {
      final response = await _makeRequest(
        'POST', 
        '/tournaments/join/', 
        body: {'inviteCode': inviteCode}
      );
      
      if (response['success'] == true) {
        // Clear tournaments cache to refresh the list
        _cache.remove(_cache.tournamentsKey(_currentUser?.id ?? ''));
        return {'success': true, 'result': response};
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to join tournament',
          'detail': response['detail'] ?? 'Unknown error occurred'
        };
      }
    } catch (e) {
      Logger.error('[ApiService] Join tournament failed: $e');
      if (e is ApiException) {
        return {
          'success': false,
          'error': e.getUserFriendlyMessage(),
          'detail': e.message
        };
      }
      return {
        'success': false,
        'error': 'Failed to join tournament',
        'detail': e.toString()
      };
    }
  }

  // ==================== PASSWORD RESET ====================

  /// Request password reset email
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      await _makeRequest(
        'POST',
        '/users/password-reset/',
        body: {'email': email},
        requiresAuth: false,
      );
      
      return {
        'success': true,
        'message': 'Password reset email sent successfully'
      };
    } catch (e) {
      Logger.error('[ApiService] Password reset request failed: $e');
      if (e is ApiException) {
        return {'success': false, 'error': e.getUserFriendlyMessage()};
      }
      return {'success': false, 'error': 'Failed to send password reset email'};
    }
  }

  /// Confirm password reset with token
  Future<Map<String, dynamic>> confirmPasswordReset(String uid, String token, String newPassword) async {
    try {
      await _makeRequest(
        'POST',
        '/users/password-reset-confirm/',
        body: {
          'uid': uid,
          'token': token,
          'new_password': newPassword,
        },
        requiresAuth: false,
      );
      
      return {
        'success': true,
        'message': 'Password reset successfully'
      };
    } catch (e) {
      Logger.error('[ApiService] Password reset confirmation failed: $e');
      if (e is ApiException) {
        return {'success': false, 'error': e.getUserFriendlyMessage()};
      }
      return {'success': false, 'error': 'Failed to reset password'};
    }
  }

  // ==================== PRIVATE METHODS ====================

  /// Make HTTP request with proper error handling
  Future<dynamic> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final url = queryParams != null 
          ? uri.replace(queryParameters: queryParams)
          : uri;

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (requiresAuth) {
        final token = await _getValidAccessToken();
        if (token == null) {
          throw ApiException.unauthorized('No valid access token available');
        }
        headers['Authorization'] = 'Bearer $token';
      }

      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _httpClient.get(url, headers: headers).timeout(defaultTimeout);
          break;
        case 'POST':
          response = await _httpClient.post(
            url, 
            headers: headers, 
            body: body != null ? jsonEncode(body) : null
          ).timeout(defaultTimeout);
          break;
        case 'PUT':
          response = await _httpClient.put(
            url, 
            headers: headers, 
            body: body != null ? jsonEncode(body) : null
          ).timeout(defaultTimeout);
          break;
        case 'PATCH':
          response = await _httpClient.patch(
            url, 
            headers: headers, 
            body: body != null ? jsonEncode(body) : null
          ).timeout(defaultTimeout);
          break;
        case 'DELETE':
          response = await _httpClient.delete(url, headers: headers).timeout(defaultTimeout);
          break;
        default:
          throw ApiException(message: 'Unsupported HTTP method: $method');
      }

      return _processResponse(response);
    } on SocketException {
      throw ApiException.network('No internet connection');
    } on TimeoutException {
      throw ApiException.timeout('Request timed out');
    } on http.ClientException catch (e) {
      throw ApiException.network(e.message);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Request failed: ${e.toString()}');
    }
  }

  /// Process HTTP response and handle errors
  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      
      try {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } catch (e) {
        return utf8.decode(response.bodyBytes);
      }
    }

    // Handle error responses
    String errorMessage = 'Server error';
    Map<String, dynamic>? errorDetails;

    try {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      if (errorData is Map<String, dynamic>) {
        errorMessage = errorData['detail'] ?? 
                      errorData['error'] ?? 
                      errorData['message'] ?? 
                      errorMessage;
        errorDetails = errorData;
      }
    } catch (e) {
      // Ignore JSON decode errors, use default message
    }

    switch (response.statusCode) {
      case 400:
        throw ApiException.validation(errorMessage, errorDetails);
      case 401:
        throw ApiException.unauthorized(errorMessage);
      case 403:
        throw ApiException.forbidden(errorMessage);
      case 404:
        throw ApiException.notFound(errorMessage);
      case 429:
        throw ApiException.validation('Too many requests. Please try again later.');
      case 500:
      case 502:
      case 503:
      case 504:
        throw ApiException.serverError(errorMessage);
      default:
        throw ApiException(message: 'HTTP ${response.statusCode}: $errorMessage');
    }
  }

  /// Get valid access token, refreshing if necessary
  Future<String?> _getValidAccessToken() async {
    if (_accessToken == null) return null;

    if (_isTokenExpired(_accessToken!)) {
      final refreshed = await _attemptTokenRefresh();
      if (!refreshed) {
        await logout();
        return null;
      }
    }

    return _accessToken;
  }

  /// Check if JWT token is expired
  bool _isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      return true; // Assume expired if we can't decode
    }
  }

  /// Attempt to refresh access token
  Future<bool> _attemptTokenRefresh() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/users/token/refresh/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': _refreshToken}),
      ).timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        await _saveTokens(data['access'], _refreshToken!);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      Logger.error('[ApiService] Token refresh failed: $e');
      return false;
    }
  }

  /// Save tokens to secure storage
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);
    } catch (e) {
      Logger.error('[ApiService] Failed to save tokens: $e');
    }
  }

  /// Load stored tokens
  Future<void> _loadStoredTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');
    } catch (e) {
      Logger.error('[ApiService] Failed to load tokens: $e');
    }
  }

  /// Load user profile from cache or stored data
  Future<void> _loadUserProfile() async {
    try {
      // Try cache first
      const cacheKey = 'user_profile';
      if (_cache.has(cacheKey)) {
        _currentUser = _cache.get<UserModel>(cacheKey);
        if (_currentUser != null) return;
      }

      // Try stored data
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        final userJson = jsonDecode(userData);
        _currentUser = UserModel.fromJson(userJson);
        _cache.set(cacheKey, _currentUser!, ttl: const Duration(minutes: 10));
        return;
      }

      // Fetch from server
      await getUserProfile(forceRefresh: true);
    } catch (e) {
      Logger.error('[ApiService] Failed to load user profile: $e');
    }
  }

  /// Store user data for offline access
  Future<void> _storeUserData(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(user.toJson()));
    } catch (e) {
      Logger.error('[ApiService] Failed to store user data: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
    _cache.dispose();
  }
}