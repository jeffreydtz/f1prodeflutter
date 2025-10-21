import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import 'secure_storage_service.dart';

import '../models/betresult.dart';
import '../models/user.dart';
import '../models/race.dart';
import '../models/tournament.dart';
import '../models/sanction.dart';

class ApiService {
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// URL base del backend Django
  static const String baseUrl = 'https://f1prodedjango.vercel.app/api';

  /// Variable para almacenar el usuario logueado
  UserModel? currentUser;

  String? _accessToken;
  String? _refreshToken;

  // Secure storage service
  final SecureStorageService _secureStorage = SecureStorageService();

  // Cache para evitar llamadas repetidas
  Map<String, dynamic> _cache = {};
  Map<String, DateTime> _cacheTimestamps = {};
  // Aumentar la duración del caché a 30 minutos
  static const Duration _cacheDuration = Duration(minutes: 30);

  // Endpoints
  static const String loginEndpoint = '/users/token/';
  static const String refreshEndpoint = '/users/token/refresh/';
  static const String registerEndpoint = '/users/register/';
  static const String profileEndpoint = '/users/profile/';
  static const String checkAvailabilityEndpoint = '/users/check-availability/';
  static const String passwordResetEndpoint = '/users/password-reset/';
  static const String passwordResetConfirmEndpoint =
      '/users/password-reset-confirm/';
  static const String racesEndpoint = '/f1/races/';
  static const String upcomingRacesEndpoint = '/f1/upcoming-races/';
  static const String driversEndpoint = '/f1/drivers/';
  static const String betsEndpoint = '/bets/';
  static const String allBetResultsEndpoint = '/bets/all-results/';
  static const String updateRaceResultsEndpoint = '/bets/update_race_results/';
  static const String tournamentsEndpoint = '/tournaments/';
  static const String joinTournamentEndpoint = '/tournaments/join/';

  final _storage = SharedPreferences.getInstance();

  // -------------------------------------------------
  // 1. REGISTER (CREACIÓN DE USUARIO)
  // -------------------------------------------------
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
      final registerUrl = '$baseUrl$registerEndpoint';

      final Map<String, dynamic> requestBody = {
        'username': username,
        'email': email,
        'password': password,
      };

      // Añadir campos opcionales según la API
      if (firstName != null && firstName.isNotEmpty) {
        requestBody['first_name'] = firstName;
      }
      if (lastName != null && lastName.isNotEmpty) {
        requestBody['last_name'] = lastName;
      }
      if (favoriteTeam != null && favoriteTeam.isNotEmpty) {
        requestBody['favorite_team'] = favoriteTeam;
      }
      if (avatarBase64 != null && avatarBase64.isNotEmpty) {
        requestBody['avatar'] = avatarBase64;
      }

      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 201) {
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Usuario creado exitosamente',
          'user': data['user']
        };
      } else {
        return {'success': false, 'errors': data};
      }
    } on http.ClientException catch (e) {
      return {'success': false, 'error': 'Error de conexión: ${e.message}'};
    } on FormatException catch (e) {
      return {
        'success': false,
        'error': 'Error en formato de respuesta: ${e.message}'
      };
    } catch (e) {
      return {'success': false, 'error': 'Error inesperado: ${e.toString()}'};
    }
  }

  // -------------------------------------------------
  // 2. LOGIN
  // -------------------------------------------------
  Future<Map<String, dynamic>> login(String username, String password) async {
    const String loginEndpoint = '/token/';
    final String loginUrl = '$baseUrl$loginEndpoint';

    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // Guardar tokens
        final String accessToken = data['access'];
        final String refreshToken = data['refresh'];

        _accessToken = accessToken;
        _refreshToken = refreshToken;

        // Decodificar token para obtener user_id y otros datos
        String userId = '0';
        try {
          Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
          userId = decodedToken['user_id'].toString();

          // Guardar tokens y datos básicos
          await _saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );

          // Guardar datos del usuario en SharedPreferences
          final prefs = await _storage;
          await prefs.setString('user_id', userId);
          await prefs.setString('username', username);

          // Inicializar usuario con datos básicos
          currentUser = UserModel(
            id: userId,
            username: username,
            email: '',
            points: 0,
          );

          // Guardar en caché
          _saveToCache('user_profile', {
            'id': userId,
            'username': username,
            'email': '',
            'points': 0,
          });

          // Cargar perfil completo del servidor
          try {
            final profileData = await _loadUserProfile();
            if (profileData.containsKey('username')) {
              currentUser = UserModel(
                id: userId,
                username: profileData['username'],
                email: profileData['email'] ?? '',
                points: profileData['points'] ?? 0,
                avatar: profileData['avatar'],
              );

              // Actualizar SharedPreferences con datos completos
              await prefs.setString('username', profileData['username']);
              await prefs.setString('email', profileData['email'] ?? '');
              await prefs.setInt('points', profileData['points'] ?? 0);
              if (profileData['avatar'] != null) {
                await prefs.setString('avatar', profileData['avatar']);
              }
            }
          } catch (profileError) {
            // Continuar con datos básicos si hay error al cargar el perfil
          }
        } catch (e) {
          // Error al decodificar el token
        }

        return {'success': true, 'message': 'Inicio de sesión exitoso'};
      } else {
        String errorMessage = 'Error de autenticación';
        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data.containsKey('detail')) {
            errorMessage = data['detail'];
          } else if (data.containsKey('non_field_errors')) {
            errorMessage = data['non_field_errors'][0];
          }
        } catch (e) {
          errorMessage = 'Error de autenticación: ${response.statusCode}';
        }
        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: ${e.toString()}'};
    }
  }

  // -------------------------------------------------
  // 3. TOKEN MANAGEMENT
  // -------------------------------------------------
  Future<String?> _getAccessToken() async {
    if (_accessToken == null) {
      try {
        // Load from secure storage
        _accessToken = await _secureStorage.getAccessToken();
        debugPrint(
            '[ApiService] Token from storage: ${_accessToken != null ? 'Found' : 'Not found'}');

        // Verificar si el token está por expirar
        if (_accessToken != null) {
          try {
            final decodedToken = JwtDecoder.decode(_accessToken!);
            final expiration =
                DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
            final now = DateTime.now();
            final minutesUntilExpiry = expiration.difference(now).inMinutes;
            debugPrint(
                '[ApiService] Token expires in $minutesUntilExpiry minutes');

            // Si el token expira en menos de 5 minutos, refrescarlo
            if (minutesUntilExpiry < 5) {
              debugPrint(
                  '[ApiService] Token expires soon, attempting refresh...');
              await _refreshAccessTokenFromServer();
            }
          } catch (e) {
            debugPrint('[ApiService] Error decoding token: $e');
            // Si hay un error al decodificar, intentar refrescar de todas formas
            await _refreshAccessTokenFromServer();
          }
        }
      } catch (e) {
        debugPrint('[ApiService] Error accessing secure storage: $e');
        // Error accediendo a secure storage
        // Intentar retornar el token en memoria si existe
      }
    }
    debugPrint(
        '[ApiService] Final token status: ${_accessToken != null ? 'Available' : 'Null'}');
    return _accessToken;
  }

  Future<String?> _getRefreshToken() async {
    if (_refreshToken == null) {
      try {
        // Load from secure storage
        _refreshToken = await _secureStorage.getRefreshToken();
      } catch (e) {
        // Error accediendo a secure storage
        debugPrint('[ApiService] Error accessing refresh token: $e');
      }
    }
    return _refreshToken;
  }

  Future<bool> _refreshAccessTokenFromServer() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl$refreshEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        await _saveTokens(
          accessToken: data['access'],
          refreshToken: refreshToken, // Mantener el mismo refresh token
        );
        return true;
      } else {
        await _clearTokens();
        return false;
      }
    } catch (e) {
      // No borrar tokens en caso de error de red para permitir reintentos
      return false;
    }
  }

  Future<void> _saveTokens({String? accessToken, String? refreshToken}) async {
    try {
      // Actualizar en memoria primero para garantizar disponibilidad
      if (accessToken != null) {
        _accessToken = accessToken;
      }
      if (refreshToken != null) {
        _refreshToken = refreshToken;
      }

      // Guardar en secure storage (iOS/Android) o SharedPreferences (Web)
      if (accessToken != null) {
        await _secureStorage.saveAccessToken(accessToken);

        // Extraer y guardar más información del usuario del token JWT en SharedPreferences
        try {
          final prefs = await _storage;
          final decodedToken = JwtDecoder.decode(accessToken);
          if (decodedToken.containsKey('user_id')) {
            final userId = decodedToken['user_id'].toString();
            await prefs.setString('user_id', userId);

            // Si hay más campos en el token, guardarlos también
            if (decodedToken.containsKey('username')) {
              await prefs.setString('username', decodedToken['username']);
            }
            if (decodedToken.containsKey('email')) {
              await prefs.setString('email', decodedToken['email']);
            }
          }
        } catch (e) {
          // Ignorar errores al decodificar el token
        }
      }
      if (refreshToken != null) {
        await _secureStorage.saveRefreshToken(refreshToken);
      }
    } catch (e) {
      // Error guardando tokens, pero ya están en memoria
      debugPrint('[ApiService] Error saving tokens: $e');
    }
  }

  Future<void> _loadTokens() async {
    try {
      // Load tokens from secure storage
      _accessToken = await _secureStorage.getAccessToken();
      _refreshToken = await _secureStorage.getRefreshToken();

      // Intentar cargar datos del usuario desde SharedPreferences
      if (_accessToken != null) {
        final prefs = await _storage;
        final userId = prefs.getString('user_id');
        final username = prefs.getString('username');
        final email = prefs.getString('email');
        final points = prefs.getInt('points') ?? 0;
        final avatar = prefs.getString('avatar');

        if (userId != null && username != null) {
          currentUser = UserModel(
            id: userId,
            username: username,
            email: email ?? '',
            points: points,
            avatar: avatar,
          );

          // Guardar en caché
          _saveToCache('user_profile', {
            'id': userId,
            'username': username,
            'email': email ?? '',
            'points': points,
            'avatar': avatar,
          });
        }
      }
    } catch (e) {
      // Error cargando tokens, continuar con valores null
      debugPrint('[ApiService] Error loading tokens: $e');
    }
  }

  Future<void> _clearTokens() async {
    try {
      // Clear tokens from secure storage
      await _secureStorage.deleteTokens();

      // Clear user data from SharedPreferences
      final prefs = await _storage;
      await prefs.remove('user_id');
      await prefs.remove('username');
      await prefs.remove('email');
      await prefs.remove('points');
      await prefs.remove('avatar');
    } catch (e) {
      // Error borrando tokens
      debugPrint('[ApiService] Error clearing tokens: $e');
    } finally {
      // Asegurar que se borren de memoria en cualquier caso
      _accessToken = null;
      _refreshToken = null;
      currentUser = null;
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAccessToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return headers;
  }

  // Initializes the app by checking auth state and clearing invalid sessions
  Future<bool> initializeApp() async {
    try {
      // First, clear cache to prevent stale data
      _clearCache();

      // Try to load tokens
      await _loadTokens();

      // Verify token validity
      if (_accessToken != null) {
        try {
          final decodedToken = JwtDecoder.decode(_accessToken!);
          final expiration =
              DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
          final now = DateTime.now();

          // If token is expired or about to expire
          if (now.isAfter(expiration) ||
              expiration.difference(now).inMinutes < 5) {
            // Try to refresh the token
            final refreshSuccess = await _refreshAccessTokenFromServer();
            if (!refreshSuccess) {
              // If refresh fails, clear everything
              await _clearTokens();
              currentUser = null;
              return false;
            }
          }

          // Load user profile if token is valid
          await _loadUserProfile();
          return true;
        } catch (e) {
          // Token is invalid, clear it
          await _clearTokens();
          currentUser = null;
          return false;
        }
      }
      return false;
    } catch (e) {
      // On any error, log out to be safe
      await _clearTokens();
      currentUser = null;
      return false;
    }
  }

  // Clear all cached data
  void _clearCache() {
    _cache = {};
    _cacheTimestamps = {};
  }

  // -------------------------------------------------
  // 4. AUTHENTICATED REQUEST HELPER
  // -------------------------------------------------
  Future<dynamic> _authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    int retryCount = 0,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );

    // Verificar si hay token de acceso
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      debugPrint(
          '[ApiService] No access token available for endpoint: $endpoint');
      throw Exception(
          'No hay token de acceso disponible. Por favor, inicia sesión nuevamente.');
    }

    // Obtener headers con token
    final headers = await _getAuthHeaders();

    http.Response response;
    try {
      // Realizar la solicitud según el método
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PATCH':
          response = await http.patch(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Método HTTP no soportado: $method');
      }

      // Si el token expiró (401), intentar refrescarlo y reintentar
      if (response.statusCode == 401) {
        final refreshSuccess = await _refreshAccessTokenFromServer();

        if (refreshSuccess) {
          // Obtener nuevos headers con el token refrescado
          final newHeaders = await _getAuthHeaders();

          // Reintentar la solicitud con el nuevo token
          switch (method.toUpperCase()) {
            case 'GET':
              response = await http.get(url, headers: newHeaders);
              break;
            case 'POST':
              response = await http.post(
                url,
                headers: newHeaders,
                body: body != null ? jsonEncode(body) : null,
              );
              break;
            case 'PUT':
              response = await http.put(
                url,
                headers: newHeaders,
                body: body != null ? jsonEncode(body) : null,
              );
              break;
            case 'PATCH':
              response = await http.patch(
                url,
                headers: newHeaders,
                body: body != null ? jsonEncode(body) : null,
              );
              break;
            case 'DELETE':
              response = await http.delete(url, headers: newHeaders);
              break;
          }
        } else {
          throw Exception('Error de autenticación: token expirado');
        }
      }

      // Procesar redirecciones 3xx (algunos hostings devuelven 301/302/307/308)
      if ((response.statusCode == 301 ||
              response.statusCode == 302 ||
              response.statusCode == 307 ||
              response.statusCode == 308) &&
          response.headers['location'] != null &&
          retryCount < 1) {
        final location = response.headers['location']!;
        final Uri redirected = location.startsWith('http')
            ? Uri.parse(location)
            : Uri.parse('$baseUrl$location');

        // Reintentar contra la URL redirigida
        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(redirected, headers: headers);
            break;
          case 'POST':
            response = await http.post(
              redirected,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          case 'PUT':
            response = await http.put(
              redirected,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          case 'PATCH':
            response = await http.patch(
              redirected,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          case 'DELETE':
            response = await http.delete(redirected, headers: headers);
            break;
        }
      }

      // Procesar la respuesta según el código de estado
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Intentar decodificar como JSON
        try {
          final responseBody = utf8.decode(response.bodyBytes);
          if (responseBody.isEmpty) {
            return null;
          }

          final decodedData = jsonDecode(responseBody);
          return decodedData;
        } catch (e) {
          return utf8.decode(response.bodyBytes);
        }
      } else {
        // Error en la respuesta
        try {
          // Intentar decodificar como JSON
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));

          if (errorData is Map) {
            final errorMessage = errorData['detail'] ??
                errorData['error'] ??
                'Error del servidor (${response.statusCode})';
            throw Exception(errorMessage);
          }
          throw Exception('Error del servidor (${response.statusCode})');
        } catch (e) {
          // Si no se puede decodificar como JSON, verificar si es HTML
          final responseBody = utf8.decode(response.bodyBytes);
          if (responseBody.trim().startsWith('<!DOCTYPE html>') ||
              responseBody.trim().startsWith('<html>')) {
            if (response.statusCode == 404) {
              throw Exception(
                  'Recurso no encontrado (404). La URL solicitada no existe en el servidor.');
            } else {
              debugPrint(
                  '[ApiService] HTML response received for $endpoint. Status: ${response.statusCode}');
              debugPrint(
                  '[ApiService] Response body: ${responseBody.substring(0, 200)}...');
              throw Exception(
                  'Error de autenticación o servidor. Por favor, inicia sesión nuevamente.');
            }
          }

          if (e is Exception) {
            rethrow;
          }
          throw Exception('Error del servidor (${response.statusCode})');
        }
      }
    } on SocketException catch (e) {
      // Reintentar en caso de error de conexión
      if (retryCount < 2) {
        // Esperar un segundo antes de reintentar
        await Future.delayed(Duration(seconds: 1));
        return _authenticatedRequest(
          method,
          endpoint,
          body: body,
          queryParams: queryParams,
          retryCount: retryCount + 1,
        );
      }
      throw Exception('Error de conexión: ${e.toString()}');
    } catch (e) {
      // Reintentar para otros errores también
      if (retryCount < 2) {
        // Esperar un segundo antes de reintentar
        await Future.delayed(Duration(seconds: 1));
        return _authenticatedRequest(
          method,
          endpoint,
          body: body,
          queryParams: queryParams,
          retryCount: retryCount + 1,
        );
      }
      throw Exception('Error en solicitud: ${e.toString()}');
    }
  }

  // -------------------------------------------------
  // 5. USER PROFILE
  // -------------------------------------------------
  Future<Map<String, dynamic>> _loadUserProfile() async {
    const cacheKey = 'user_profile';

    // Primero intentamos usar los datos en memoria si existen
    if (currentUser != null) {
      return {
        'id': currentUser!.id,
        'username': currentUser!.username,
        'email': currentUser!.email,
        'points': currentUser!.points,
        'total_points': currentUser!.points,
        'races_played': 0,
        'poles_guessed': 0,
        'avatar': currentUser!.avatar,
      };
    }

    try {
      // Intentar obtener datos del servidor primero
      final response = await _authenticatedRequest(
        'GET',
        profileEndpoint,
      );

      if (response != null && response is Map<String, dynamic>) {
        // Asegurar que los campos necesarios existan
        final Map<String, dynamic> safeProfileData = {
          'id': response['id']?.toString() ?? '',
          'username': response['username'] ?? 'Usuario',
          'email': response['email'] ?? '',
          'points': response['points'] ?? 0,
          'total_points': response['total_points'] ?? response['points'] ?? 0,
          'races_played': response['races_played'] ?? 0,
          'poles_guessed': response['poles_guessed'] ?? 0,
          'avatar': response['avatar'],
        };

        // Actualizar el currentUser con los datos del perfil
        try {
          currentUser = UserModel(
            id: safeProfileData['id'],
            username: safeProfileData['username'],
            email: safeProfileData['email'],
            points: safeProfileData['points'],
            avatar: safeProfileData['avatar'],
          );

          // Guardar en SharedPreferences para persistencia
          final prefs = await _storage;
          await prefs.setString('user_id', safeProfileData['id']);
          await prefs.setString('username', safeProfileData['username']);
          await prefs.setString('email', safeProfileData['email']);
          await prefs.setInt('points', safeProfileData['points']);
          if (safeProfileData['avatar'] != null) {
            await prefs.setString('avatar', safeProfileData['avatar']);
          }
        } catch (storageError) {
          // Continuar incluso si hay errores al guardar
        }

        // Guardar en caché
        _saveToCache(cacheKey, safeProfileData);
        return safeProfileData;
      }
    } catch (e) {
      // Si hay error al cargar desde el servidor, continuamos con los datos en caché
    }

    // Si no hay respuesta válida del servidor, intentar usar datos en caché
    final cachedData = _getFromCache(cacheKey);
    if (cachedData != null && cachedData is Map<String, dynamic>) {
      // Intentar actualizar currentUser con los datos de caché
      try {
        currentUser = UserModel(
          id: cachedData['id'],
          username: cachedData['username'],
          email: cachedData['email'],
          points: cachedData['points'],
          avatar: cachedData['avatar'],
        );
      } catch (e) {
        // Ignorar errores al actualizar currentUser desde caché
      }

      return cachedData;
    }

    // Si no hay datos en caché, usar datos almacenados en SharedPreferences
    try {
      final prefs = await _storage;
      final userId = prefs.getString('user_id');
      final username = prefs.getString('username');
      final email = prefs.getString('email');
      final points = prefs.getInt('points') ?? 0;
      final avatar = prefs.getString('avatar');

      if (userId != null && username != null) {
        final userData = {
          'id': userId,
          'username': username,
          'email': email ?? '',
          'points': points,
          'total_points': points,
          'races_played': 0,
          'poles_guessed': 0,
          'avatar': avatar,
        };

        // Actualizar currentUser
        currentUser = UserModel(
          id: userId,
          username: username,
          email: email ?? '',
          points: points,
          avatar: avatar,
        );

        // También guardar en caché
        _saveToCache(cacheKey, userData);

        return userData;
      }
    } catch (e) {
      // Ignorar errores al cargar desde SharedPreferences
    }

    // Si todo lo demás falla, usar datos por defecto
    return {
      'id': '0',
      'username': 'Usuario',
      'email': '',
      'points': 0,
      'total_points': 0,
      'races_played': 0,
      'poles_guessed': 0,
      'avatar': null,
    };
  }

  // -------------------------------------------------
  // MÉTODOS PÚBLICOS DE API
  // -------------------------------------------------

  // Método para obtener el perfil del usuario
  Future<UserModel?> getUserProfile() async {
    try {
      final response = await _authenticatedRequest(
        'GET',
        profileEndpoint,
      );

      if (response != null && response['success'] == true) {
        // Extraer los datos del perfil según la estructura de la API
        final Map<String, dynamic> profileData =
            response['profile'] as Map<String, dynamic>;

        // Crear el modelo de usuario con los datos del perfil
        final user = UserModel(
          id: currentUser?.id ?? '0', // Mantenemos el ID del token JWT
          username: profileData['username'] ?? '',
          email: profileData['email'] ?? '',
          points: profileData['points'] ?? 0,
          avatar: profileData['avatar'],
          firstName: profileData['first_name'],
          lastName: profileData['last_name'],
          favoriteTeam: profileData['favorite_team'],
        );

        // Actualizar el usuario actual en memoria
        currentUser = user;

        // Guardar en SharedPreferences
        final prefs = await _storage;
        await prefs.setString('username', user.username);
        await prefs.setString('email', user.email);
        await prefs.setInt('points', user.points);
        if (user.avatar != null) await prefs.setString('avatar', user.avatar!);
        if (user.firstName != null)
          await prefs.setString('first_name', user.firstName!);
        if (user.lastName != null)
          await prefs.setString('last_name', user.lastName!);
        if (user.favoriteTeam != null)
          await prefs.setString('favorite_team', user.favoriteTeam!);

        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Método para actualizar el perfil del usuario
  Future<bool> updateUserProfile({
    String? firstName,
    String? lastName,
    String? favoriteTeam,
    String? avatar,
    String? newPassword,
  }) async {
    try {
      final Map<String, dynamic> userData = {};

      // Solo incluir campos que se van a actualizar (PATCH)
      if (firstName != null) {
        userData['first_name'] = firstName;
      }

      if (lastName != null) {
        userData['last_name'] = lastName;
      }

      if (favoriteTeam != null) {
        userData['favorite_team'] = favoriteTeam;
      }

      if (avatar != null) {
        userData['avatar'] = avatar;
      }

      if (newPassword != null && newPassword.isNotEmpty) {
        userData['new_password'] = newPassword;
      }

      final response = await _authenticatedRequest(
        'PATCH',
        profileEndpoint,
        body: userData,
      );

      if (response != null) {
        // Recargar el perfil después de la actualización
        await getUserProfile();
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Método para cerrar sesión
  Future<void> logout() async {
    await _clearTokens();
    clearCache(); // Limpiar caché al cerrar sesión

    // Asegurar que se borren correctamente las variables en memoria
    _accessToken = null;
    _refreshToken = null;
    currentUser = null;
  }

  // Método para obtener el usuario actual
  UserModel? getCurrentUser() {
    if (currentUser == null) {
      // Intentar cargar el perfil de forma asíncrona si no está disponible
      _loadUserProfile().then((profile) {
        // Actualizar currentUser con datos recién cargados
        if (currentUser == null) {
          currentUser = UserModel(
            id: profile['id'],
            username: profile['username'],
            email: profile['email'] ?? '',
            points: profile['points'],
            avatar: profile['avatar'],
          );
        }
      }).catchError((e) {
        debugPrint('Error al cargar perfil en getCurrentUser: $e');
      });
    }

    return currentUser;
  }

  Future<void> loadStoredTokens() async {
    await _loadTokens();
  }

  Future<String?> getStoredAccessToken() async {
    return _getAccessToken();
  }

  Future<Map<String, dynamic>> loadUserProfile() async {
    return _loadUserProfile();
  }

  // Método para verificar disponibilidad de username/email
  Future<bool> checkAvailability(String fieldType, String value,
      {String? currentUserId}) async {
    try {
      final Map<String, dynamic> requestBody = {
        'field_type': fieldType, // 'username' o 'email'
        'value': value,
      };

      if (currentUserId != null) {
        requestBody['current_user_id'] = int.parse(currentUserId);
      }

      final response = await http.post(
        Uri.parse('$baseUrl$checkAvailabilityEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['available'] == true;
      }

      // En caso de error, asumimos que está disponible para evitar bloquear al usuario
      return true;
    } catch (e) {
      // En caso de error, asumimos que está disponible para evitar bloquear al usuario
      return true;
    }
  }

  // Métodos para gestión de caché
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final timestamp = _cacheTimestamps[key]!;
    final now = DateTime.now();
    return now.difference(timestamp) < _cacheDuration;
  }

  void _saveToCache(String key, dynamic data) {
    try {
      _cache[key] = data;
      _cacheTimestamps[key] = DateTime.now();
    } catch (e) {
      // Error al guardar en caché, pero no es crítico
    }
  }

  dynamic _getFromCache(String key) {
    try {
      if (_isCacheValid(key)) {
        return _cache[key];
      }
    } catch (e) {
      // Error al leer de caché
    }
    return null;
  }

  // Método para obtener todas las carreras
  Future<List<Race>> getRaces() async {
    try {
      Logger.info(
          '[ApiService.getRaces] Fetching races from $baseUrl$racesEndpoint');
      final response = await _authenticatedRequest(
        'GET',
        racesEndpoint,
      );

      List<Race> results = [];

      if (response == null) {
        Logger.warning('[ApiService.getRaces] Null response');
        return results;
      }

      // La API puede devolver { success, races: [...] } o directamente una lista
      if (response is Map<String, dynamic>) {
        Logger.info('[ApiService.getRaces] Map response keys: ' +
            response.keys.join(', '));
        if (response['races'] is List) {
          final List<dynamic> races = response['races'];
          Logger.info('[ApiService.getRaces] races count: ${races.length}');
          results = races.map((raceData) => Race.fromJson(raceData)).toList();
        } else if (response['results'] is List) {
          final List<dynamic> races = response['results'];
          Logger.info('[ApiService.getRaces] results count: ${races.length}');
          results = races.map((raceData) => Race.fromJson(raceData)).toList();
        } else if (response is List) {
          results = (response as List)
              .map((raceData) => Race.fromJson(raceData))
              .toList();
        }
      } else if (response is List) {
        Logger.info(
            '[ApiService.getRaces] List response length: ${response.length}');
        results = response.map((raceData) => Race.fromJson(raceData)).toList();
      }

      if (results.isNotEmpty) {
        final sample = results.first;
        Logger.info(
            '[ApiService.getRaces] Sample race: ${sample.name} | hasBet=${sample.hasBet} | season=${sample.season} round=${sample.round}');
      }
      return results;
    } catch (e) {
      Logger.error('[ApiService.getRaces] Error: ${e.toString()}');
      return [];
    }
  }

  // Método para obtener carreras próximas
  Future<List<Race>> getUpcomingRaces() async {
    try {
      Logger.info('[ApiService.getUpcomingRaces] Fetching upcoming races');
      final response = await _authenticatedRequest(
        'GET',
        upcomingRacesEndpoint,
      );

      List<Race> results = [];

      if (response is List) {
        results = response.map((raceData) => Race.fromJson(raceData)).toList();
      } else if (response is Map<String, dynamic>) {
        if (response['races'] is List) {
          final List<dynamic> races = response['races'];
          Logger.info(
              '[ApiService.getUpcomingRaces] races count: ${races.length}');
          results = races.map((raceData) => Race.fromJson(raceData)).toList();
        } else if (response['results'] is List) {
          final List<dynamic> races = response['results'];
          Logger.info(
              '[ApiService.getUpcomingRaces] results count: ${races.length}');
          results = races.map((raceData) => Race.fromJson(raceData)).toList();
        }
      }

      return results;
    } catch (e) {
      Logger.error('[ApiService.getUpcomingRaces] Error: ${e.toString()}');
      return [];
    }
  }

  // Método para obtener conductores/pilotos
  Future<List<String>> getDrivers() async {
    try {
      Logger.info('[ApiService.getDrivers] Fetching drivers');
      final response = await _authenticatedRequest(
        'GET',
        driversEndpoint,
      );

      if (response is List) {
        return response.map((driver) => driver.toString()).toList();
      } else if (response is Map<String, dynamic>) {
        if (response.containsKey('drivers') && response['drivers'] is List) {
          final List<dynamic> drivers = response['drivers'];
          return drivers.map((driver) => driver.toString()).toList();
        } else if (response.containsKey('results') &&
            response['results'] is List) {
          final List<dynamic> results = response['results'];
          return results.map((driver) => driver.toString()).toList();
        }
      }

      return [];
    } catch (e) {
      Logger.error('[ApiService.getDrivers] Error: ${e.toString()}');
      return [];
    }
  }

  // Método para obtener resultados de apuestas del usuario
  Future<List<BetResult>> getUserBetResults(
      {int page = 1, int pageSize = 20}) async {
    try {
      Logger.info(
          '[ApiService.getUserBetResults] Fetching bets page=$page size=$pageSize');
      final response = await _authenticatedRequest(
        'GET',
        allBetResultsEndpoint,
        queryParams: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

      List<BetResult> results = [];

      if (response != null) {
        if (response is List) {
          // Si la respuesta es directamente una lista
          Logger.info(
              '[ApiService.getUserBetResults] Response is a list with ${response.length} items');
          results =
              response.map((betData) => BetResult.fromJson(betData)).toList();
        } else if (response is Map<String, dynamic>) {
          // Si la respuesta es un objeto con múltiples estructuras posibles
          if (response.containsKey('bets') && response['bets'] is List) {
            final List<dynamic> bets = response['bets'];
            Logger.info(
                '[ApiService.getUserBetResults] Found bets array with ${bets.length} items');
            results =
                bets.map((betData) => BetResult.fromJson(betData)).toList();
          } else if (response.containsKey('results') &&
              response['results'] is List) {
            final List<dynamic> bets = response['results'];
            Logger.info(
                '[ApiService.getUserBetResults] Found results array with ${bets.length} items');
            results =
                bets.map((betData) => BetResult.fromJson(betData)).toList();
          } else if (response.containsKey('data') && response['data'] is List) {
            final List<dynamic> bets = response['data'];
            Logger.info(
                '[ApiService.getUserBetResults] Found data array with ${bets.length} items');
            results =
                bets.map((betData) => BetResult.fromJson(betData)).toList();
          } else {
            // Si no hay estructura conocida, intentar procesar directamente
            Logger.warning(
                '[ApiService.getUserBetResults] Unknown response structure: ${response.keys}');
          }
        }
      }

      Logger.info(
          '[ApiService.getUserBetResults] Bets returned: ${results.length}');
      if (results.isNotEmpty) {
        final sample = results.first;
        Logger.info(
            '[ApiService.getUserBetResults] Sample bet: season=${sample.season} round=${sample.round} race=${sample.raceName}');
      }
      return results;
    } catch (e) {
      Logger.error('[ApiService.getUserBetResults] Error: ${e.toString()}');
      return [];
    }
  }

  // Método para obtener información de paginación de apuestas
  Future<Map<String, dynamic>> getUserBetResultsWithPagination(
      {int page = 1, int pageSize = 20}) async {
    try {
      final response = await _authenticatedRequest(
        'GET',
        allBetResultsEndpoint,
        queryParams: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

      if (response != null && response is Map<String, dynamic>) {
        final List<BetResult> bets = [];
        if (response.containsKey('bets') && response['bets'] is List) {
          final List<dynamic> betsData = response['bets'];
          bets.addAll(
              betsData.map((betData) => BetResult.fromJson(betData)).toList());
        }

        return {
          'bets': bets,
          'total_bets': response['total_bets'] ?? 0,
          'page': response['page'] ?? 1,
          'page_size': response['page_size'] ?? 20,
          'total_pages': response['total_pages'] ?? 1,
        };
      }

      return {
        'bets': <BetResult>[],
        'total_bets': 0,
        'page': 1,
        'page_size': 20,
        'total_pages': 1,
      };
    } catch (e) {
      return {
        'bets': <BetResult>[],
        'total_bets': 0,
        'page': 1,
        'page_size': 20,
        'total_pages': 1,
      };
    }
  }

  // Método para crear una apuesta
  Future<Map<String, dynamic>> createBet({
    required String season,
    required String round,
    required String raceName,
    required String date,
    required String circuit,
    required bool hasSprint,
    required String poleman,
    required List<String> top10,
    required String dnf,
    required String fastestLap,
    List<String>? sprintTop10,
  }) async {
    try {
      final betData = {
        'season': season,
        'round': round,
        'race_name': raceName,
        'date': date,
        'circuit': circuit,
        'has_sprint': hasSprint,
        'poleman': poleman,
        'top10': top10,
        'dnf': dnf,
        'fastest_lap': fastestLap,
      };

      if (hasSprint && sprintTop10 != null) {
        betData['sprint_top10'] = sprintTop10;
      } else {
        betData['sprint_top10'] = [];
      }

      final response = await _authenticatedRequest(
        'POST',
        betsEndpoint,
        body: betData,
      );

      if (response != null && response['success'] == true) {
        return {
          'success': true,
          'message': response['message'] ?? 'Apuesta creada exitosamente'
        };
      } else {
        return {
          'success': false,
          'error': response?['error'] ?? 'No se pudo crear la apuesta'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Método legacy para mantener compatibilidad
  @Deprecated('Use createBet with named parameters instead')
  Future<Map<String, dynamic>> createBetLegacy(Map<String, dynamic> bet) async {
    return createBet(
      season: bet['season']?.toString() ?? '',
      round: bet['round']?.toString() ?? '',
      raceName: bet['race_name'] ?? bet['raceName'] ?? '',
      date: bet['date'] ?? '',
      circuit: bet['circuit'] ?? '',
      hasSprint: bet['has_sprint'] ?? bet['hasSprint'] ?? false,
      poleman: bet['poleman'] ?? '',
      top10: List<String>.from(bet['top10'] ?? []),
      dnf: bet['dnf'] ?? '',
      fastestLap: bet['fastest_lap'] ?? bet['fastestLap'] ?? '',
      sprintTop10: bet['sprint_top10'] != null
          ? List<String>.from(bet['sprint_top10'])
          : null,
    );
  }

  // Método para obtener una apuesta específica
  Future<Map<String, dynamic>?> getBet(int betId) async {
    try {
      final response = await _authenticatedRequest(
        'GET',
        '$betsEndpoint$betId/',
      );
      return response;
    } catch (e) {
      return null;
    }
  }

  // Método para verificar si existe una apuesta para una temporada y ronda específica
  Future<bool> hasBetForRace(String season, String round) async {
    try {
      Logger.info(
          '[ApiService.hasBetForRace] Checking bet for season=$season round=$round');
      final response = await _authenticatedRequest(
        'GET',
        betsEndpoint,
        queryParams: {
          'season': season,
          'round': round,
        },
      );

      if (response != null) {
        if (response is List) {
          Logger.info(
              '[ApiService.hasBetForRace] Response is list with ${response.length} items');
          return response.isNotEmpty;
        } else if (response is Map<String, dynamic>) {
          if (response.containsKey('bets') && response['bets'] is List) {
            final List<dynamic> bets = response['bets'];
            Logger.info('[ApiService.hasBetForRace] Found ${bets.length} bets');
            return bets.isNotEmpty;
          } else if (response.containsKey('results') &&
              response['results'] is List) {
            final List<dynamic> results = response['results'];
            Logger.info(
                '[ApiService.hasBetForRace] Found ${results.length} results');
            return results.isNotEmpty;
          } else if (response.containsKey('exists')) {
            final exists = response['exists'] as bool? ?? false;
            Logger.info(
                '[ApiService.hasBetForRace] Direct exists field: $exists');
            return exists;
          }
        }
      }

      Logger.info(
          '[ApiService.hasBetForRace] No bet found for season=$season round=$round');
      return false;
    } catch (e) {
      Logger.error('[ApiService.hasBetForRace] Error: ${e.toString()}');
      return false;
    }
  }

  // Método para comparar resultados de una apuesta
  Future<Map<String, dynamic>?> compareBetResults(int betId) async {
    try {
      final response = await _authenticatedRequest(
        'GET',
        '$betsEndpoint$betId/compare_results/',
      );
      return response;
    } catch (e) {
      return null;
    }
  }

  // Método para actualizar resultados de carrera (Admin)
  Future<Map<String, dynamic>> updateRaceResults({
    required String season,
    required String round,
    required String realPoleman,
    required List<String> realTop10,
    required List<String> realDnf,
    required String realFastestLap,
    List<String>? realSprintTop10,
  }) async {
    try {
      final resultsData = {
        'season': season,
        'round': round,
        'real_poleman': realPoleman,
        'real_top10': realTop10,
        'real_dnf': realDnf,
        'real_fastest_lap': realFastestLap,
      };

      if (realSprintTop10 != null) {
        resultsData['real_sprint_top10'] = realSprintTop10;
      } else {
        resultsData['real_sprint_top10'] = [];
      }

      final response = await _authenticatedRequest(
        'POST',
        updateRaceResultsEndpoint,
        body: resultsData,
      );

      if (response != null) {
        return {'success': true, 'data': response};
      } else {
        return {
          'success': false,
          'error': 'No se pudieron actualizar los resultados'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Métodos para torneos
  Future<List<Tournament>> getTournaments() async {
    try {
      final response = await _authenticatedRequest(
        'GET',
        tournamentsEndpoint,
      );

      List<Tournament> tournaments = [];

      if (response is List) {
        tournaments = response
            .map((tournamentData) => Tournament.fromJson(tournamentData))
            .toList();
      } else if (response is Map<String, dynamic>) {
        if (response.containsKey('tournaments') &&
            response['tournaments'] is List) {
          final List<dynamic> tournamentsData = response['tournaments'];
          tournaments = tournamentsData
              .map((tournamentData) => Tournament.fromJson(tournamentData))
              .toList();
        } else if (response.containsKey('results') &&
            response['results'] is List) {
          final List<dynamic> results = response['results'];
          tournaments = results
              .map((tournamentData) => Tournament.fromJson(tournamentData))
              .toList();
        }
      }

      return tournaments;
    } catch (e) {
      return [];
    }
  }

  // Método para crear torneo
  Future<Map<String, dynamic>> createTournament(String name) async {
    try {
      final response = await _authenticatedRequest(
        'POST',
        tournamentsEndpoint,
        body: {'name': name},
      );

      if (response != null && response is Map<String, dynamic>) {
        return {'success': true, 'tournament': response};
      } else {
        return {'success': false, 'error': 'Formato de respuesta inválido'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Método para unirse a un torneo
  Future<Map<String, dynamic>> joinTournament(String inviteCode) async {
    try {
      final response = await _authenticatedRequest(
        'POST',
        joinTournamentEndpoint,
        body: {'inviteCode': inviteCode},
      );

      // Si la respuesta es exitosa
      if (response != null && response['success'] == true) {
        return {'success': true, 'result': response};
      }

      // Si hay un error específico en la respuesta
      if (response != null && response['error'] != null) {
        return {
          'success': false,
          'error': response['error'],
          'detail': response['detail'] ?? 'Error al unirse al torneo'
        };
      }

      // Si la respuesta no tiene el formato esperado
      return {
        'success': false,
        'error': 'Formato de respuesta inválido',
        'detail': 'El servidor no devolvió una respuesta válida'
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión',
        'detail': e.toString()
      };
    }
  }

  // Método para solicitar restablecimiento de contraseña
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final resetUrl = '$baseUrl$passwordResetEndpoint';

      final response = await http.post(
        Uri.parse(resetUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Se ha enviado un correo para restablecer tu contraseña'
        };
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': false,
          'error': data['error'] ?? 'Error al enviar el correo',
          'detail': data['detail'] ??
              'Ha ocurrido un error al enviar el correo. Por favor, inténtalo de nuevo más tarde.'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión',
        'detail': e.toString()
      };
    }
  }

  // Método para confirmar restablecimiento de contraseña
  Future<Map<String, dynamic>> confirmPasswordReset(
    String uid,
    String token,
    String newPassword,
  ) async {
    try {
      final confirmUrl = '$baseUrl$passwordResetConfirmEndpoint';

      final response = await http.post(
        Uri.parse(confirmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'uid': uid,
          'token': token,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Contraseña restablecida correctamente'
        };
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': false,
          'error': data['error'] ?? 'Error al restablecer la contraseña',
          'detail': data['detail'] ??
              'El enlace puede haber expirado o ser inválido. Por favor, solicita un nuevo enlace.'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión',
        'detail': e.toString()
      };
    }
  }

  // Método para obtener las apuestas de la última carrera de un torneo
  Future<List<BetResult>> getTournamentLastRaceBets(int tournamentId) async {
    try {
      final response = await _authenticatedRequest(
        'GET',
        '$tournamentsEndpoint$tournamentId/last_race_bets/',
      );

      List<BetResult> results = [];

      if (response is List) {
        results = response.map((data) => BetResult.fromJson(data)).toList();
      } else if (response is Map<String, dynamic>) {
        if (response.containsKey('results') && response['results'] is List) {
          final List<dynamic> resultsData = response['results'];
          results =
              resultsData.map((data) => BetResult.fromJson(data)).toList();
        }
      }

      return results;
    } catch (e) {
      // En caso de error, retornar lista vacía
      return [];
    }
  }

  // Método para obtener la clasificación de un torneo
  Future<Map<String, dynamic>> getTournamentStandings(int tournamentId) async {
    try {
      final response = await _authenticatedRequest(
        'GET',
        '$tournamentsEndpoint$tournamentId/standings/',
      );

      if (response is Map<String, dynamic>) {
        return response;
      }

      return {};
    } catch (e) {
      return {};
    }
  }

  // Método para obtener las predicciones de una carrera específica en un torneo
  Future<Map<String, dynamic>> getTournamentRacePredictions(
      int tournamentId, int season, int round) async {
    try {
      final response = await _authenticatedRequest(
        'GET',
        '$tournamentsEndpoint$tournamentId/race-predictions/',
        queryParams: {
          'season': season.toString(),
          'round': round.toString(),
        },
      );

      if (response is Map<String, dynamic>) {
        return response;
      }

      return {};
    } catch (e) {
      return {};
    }
  }

  // Método para obtener las sanciones de un torneo
  Future<List<Sanction>> getTournamentSanctions(int tournamentId) async {
    try {
      final response = await _authenticatedRequest(
        'GET',
        '$tournamentsEndpoint$tournamentId/sanctions/',
      );

      List<Sanction> sanctions = [];

      if (response is List) {
        sanctions = response.map((data) => Sanction.fromJson(data)).toList();
      } else if (response is Map<String, dynamic>) {
        if (response.containsKey('results') && response['results'] is List) {
          final List<dynamic> resultsData = response['results'];
          sanctions =
              resultsData.map((data) => Sanction.fromJson(data)).toList();
        } else if (response.containsKey('sanctions') &&
            response['sanctions'] is List) {
          final List<dynamic> sanctionsData = response['sanctions'];
          sanctions =
              sanctionsData.map((data) => Sanction.fromJson(data)).toList();
        }
      }

      return sanctions;
    } catch (e) {
      return [];
    }
  }

  // Método para aplicar una sanción en un torneo
  Future<Map<String, dynamic>> applyTournamentSanction(
      int tournamentId, String username, int points, String reason) async {
    try {
      final response = await _authenticatedRequest(
        'POST',
        '$tournamentsEndpoint$tournamentId/sanctions/',
        body: {'username': username, 'points': points, 'reason': reason},
      );

      if (response is Map<String, dynamic>) {
        if (response.containsKey('id')) {
          return {
            'success': true,
            'sanction': Sanction.fromJson(response),
          };
        } else if (response.containsKey('success') &&
            response['success'] == true) {
          return {'success': true, 'sanction': response['sanction']};
        }
      }

      return {'success': false, 'error': 'Formato de respuesta inválido'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Método para eliminar una sanción
  Future<bool> deleteTournamentSanction(
      int tournamentId, int sanctionId) async {
    try {
      final response = await _authenticatedRequest(
        'DELETE',
        '$tournamentsEndpoint$tournamentId/sanctions/$sanctionId/',
      );

      // Si es una petición DELETE exitosa, la respuesta puede ser null o vacía con código 204
      return response == null || (response is Map && response.isEmpty);
    } catch (e) {
      return false;
    }
  }
}
