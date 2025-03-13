import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/foundation.dart';

import '../models/betresult.dart';
import '../models/user.dart';
import '../models/race.dart';
import '../models/bet.dart';
import '../models/tournament.dart';

class ApiService {
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// URL base del backend Django
  static const String baseUrl =
      'https://f1prodedjango-production.up.railway.app/api';

  /// Variable para almacenar el usuario logueado
  UserModel? currentUser;

  String? _accessToken;
  String? _refreshToken;

  // Cache para evitar llamadas repetidas
  Map<String, dynamic> _cache = {};
  Map<String, DateTime> _cacheTimestamps = {};
  // Aumentar la duración del caché a 30 minutos
  static const Duration _cacheDuration = Duration(minutes: 30);

  // Endpoints
  static const String loginEndpoint = '/token/';
  static const String refreshEndpoint = '/token/refresh/';
  static const String registerEndpoint = '/users/register/';
  static const String profileEndpoint = '/users/profile/';
  static const String racesEndpoint = '/f1/races/';
  static const String driversEndpoint = '/f1/drivers/';
  static const String betsEndpoint = '/bets/';
  static const String tournamentsEndpoint = '/tournaments/';
  static const String passwordResetEndpoint = '/users/password-reset/';
  static const String passwordResetConfirmEndpoint =
      '/users/password-reset-confirm/';

  final _storage = SharedPreferences.getInstance();

  // -------------------------------------------------
  // 1. REGISTER (CREACIÓN DE USUARIO)
  // -------------------------------------------------
  Future<Map<String, dynamic>> register(
      String username, String email, String password, String passwordConfirm,
      {String? avatarBase64}) async {
    try {
      // Imprimir la URL para depuración
      final registerUrl = '$baseUrl$registerEndpoint';

      final Map<String, dynamic> requestBody = {
        'username': username,
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm,
      };

      // Añadir avatar si se proporciona
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
        return {'success': true, 'user': data['user']};
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
            password: '',
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
                password: '',
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
        final prefs = await _storage;
        _accessToken = prefs.getString('access_token');

        // Verificar si el token está por expirar
        if (_accessToken != null) {
          try {
            final decodedToken = JwtDecoder.decode(_accessToken!);
            final expiration =
                DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
            final now = DateTime.now();

            // Si el token expira en menos de 5 minutos, refrescarlo
            if (expiration.difference(now).inMinutes < 5) {
              await _refreshAccessTokenFromServer();
            }
          } catch (e) {
            // Si hay un error al decodificar, intentar refrescar de todas formas
            await _refreshAccessTokenFromServer();
          }
        }
      } catch (e) {
        // Error accediendo a SharedPreferences, puede ocurrir en web móvil
        // Intentar retornar el token en memoria si existe
      }
    }
    return _accessToken;
  }

  Future<String?> _getRefreshToken() async {
    if (_refreshToken == null) {
      try {
        final prefs = await _storage;
        _refreshToken = prefs.getString('refresh_token');
      } catch (e) {
        // Error accediendo a SharedPreferences
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
      final prefs = await _storage;

      // Actualizar en memoria primero para garantizar disponibilidad
      if (accessToken != null) {
        _accessToken = accessToken;
      }
      if (refreshToken != null) {
        _refreshToken = refreshToken;
      }

      // Luego intentar guardar en persistencia
      if (accessToken != null) {
        await prefs.setString('access_token', accessToken);

        // Extraer y guardar más información del usuario del token JWT
        try {
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
        await prefs.setString('refresh_token', refreshToken);
      }
    } catch (e) {
      // Error guardando tokens, pero ya están en memoria
    }
  }

  Future<void> _loadTokens() async {
    try {
      final prefs = await _storage;
      _accessToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');

      // Intentar cargar datos del usuario desde SharedPreferences
      if (_accessToken != null) {
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
            password: '',
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
    }
  }

  Future<void> _clearTokens() async {
    try {
      final prefs = await _storage;
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_id');
    } catch (e) {
      // Error borrando tokens
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
      throw Exception('No hay token de acceso disponible');
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
              throw Exception(
                  'El servidor devolvió una página HTML en lugar de JSON. Código de estado: ${response.statusCode}');
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
        // Depurar la respuesta
        debugPrint('Response from profile endpoint: $response');

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

        debugPrint('Safe profile data: $safeProfileData');

        // Actualizar el currentUser con los datos del perfil
        try {
          currentUser = UserModel(
            id: safeProfileData['id'],
            username: safeProfileData['username'],
            email: safeProfileData['email'],
            password: '',
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

          debugPrint('Updated currentUser: ${currentUser?.username}');
        } catch (storageError) {
          debugPrint('Error saving user data: $storageError');
          // Continuar incluso si hay errores al guardar
        }

        // Guardar en caché
        _saveToCache(cacheKey, safeProfileData);
        return safeProfileData;
      } else {
        debugPrint('Invalid response from profile endpoint: $response');
      }
    } catch (e) {
      debugPrint('Error loading profile from server: $e');
      // Si hay error al cargar desde el servidor, continuamos con los datos en caché
    }

    // Si no hay respuesta válida del servidor, intentar usar datos en caché
    final cachedData = _getFromCache(cacheKey);
    if (cachedData != null && cachedData is Map<String, dynamic>) {
      debugPrint('Using cached profile data');

      // Intentar actualizar currentUser con los datos de caché
      try {
        currentUser = UserModel(
          id: cachedData['id'],
          username: cachedData['username'],
          email: cachedData['email'],
          password: '',
          points: cachedData['points'],
          avatar: cachedData['avatar'],
        );
      } catch (e) {
        debugPrint('Error setting currentUser from cache: $e');
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

      debugPrint(
          'SharedPreferences data - username: $username, userId: $userId');

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
          password: '',
          points: points,
          avatar: avatar,
        );

        // También guardar en caché
        _saveToCache(cacheKey, userData);

        debugPrint('Using SharedPreferences profile data');
        return userData;
      }
    } catch (e) {
      debugPrint('Error loading profile from SharedPreferences: $e');
    }

    // Si no hay datos almacenados, intentar extraer información del token JWT
    try {
      final token = await _getAccessToken();
      if (token != null) {
        final decodedToken = JwtDecoder.decode(token);
        final userId = decodedToken['user_id']?.toString();
        final username = decodedToken['username']?.toString();
        final email = decodedToken['email']?.toString();

        debugPrint('JWT token data - username: $username, userId: $userId');

        if (userId != null && username != null) {
          final userData = {
            'id': userId,
            'username': username,
            'email': email ?? '',
            'points': 0,
            'total_points': 0,
            'races_played': 0,
            'poles_guessed': 0,
            'avatar': null,
          };

          // Actualizar currentUser
          currentUser = UserModel(
            id: userId,
            username: username,
            email: email ?? '',
            password: '',
            points: 0,
            avatar: null,
          );

          // También guardar en SharedPreferences
          try {
            final prefs = await _storage;
            await prefs.setString('user_id', userId);
            await prefs.setString('username', username);
            if (email != null) await prefs.setString('email', email);
          } catch (e) {
            debugPrint('Error saving JWT data to SharedPreferences: $e');
          }

          debugPrint('Using JWT token data for profile');
          return userData;
        }
      }
    } catch (e) {
      debugPrint('Error extracting data from JWT: $e');
    }

    // Si todo lo demás falla, usar datos por defecto
    debugPrint('Using default profile data');
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
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      // Intentar cargar el perfil
      final profileData = await _loadUserProfile();
      return profileData;
    } catch (e) {
      rethrow;
    }
  }

  // Método para actualizar el perfil del usuario
  Future<Map<String, dynamic>> updateUserProfile(
      Map<String, dynamic> body) async {
    try {
      final response = await _authenticatedRequest(
        'PATCH',
        profileEndpoint,
        body: body,
      );

      if (response is Map<String, dynamic>) {
        // Si la respuesta contiene el perfil actualizado, actualizar el usuario actual
        if (response.containsKey('profile') &&
            response['profile'] is Map<String, dynamic>) {
          final profileData = response['profile'];

          // Actualizar el currentUser con los datos del perfil
          currentUser = UserModel(
            id: profileData['id']?.toString() ?? '',
            username: profileData['username'] ?? 'Usuario',
            email: profileData['email'] ?? '',
            password: '',
            points: profileData['points'] ?? 0,
            avatar: profileData['avatar'],
          );

          // Actualizar la caché
          _saveToCache('user_profile', profileData);
        }

        return {'success': true, 'profile': response};
      } else {
        throw Exception('Formato de respuesta inválido');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
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
        if (currentUser == null && profile != null) {
          currentUser = UserModel(
            id: profile['id'],
            username: profile['username'],
            email: profile['email'] ?? '',
            password: '',
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

  // Métodos públicos para inicialización
  Future<void> initializeApp() async {
    try {
      await loadStoredTokens();
      final token = await getStoredAccessToken();
      if (token != null) {
        try {
          await loadUserProfile();
        } catch (e) {
          // Si hay error al cargar perfil, intentar una vez más
          try {
            await Future.delayed(Duration(milliseconds: 500));
            await loadUserProfile();
          } catch (e) {
            // Error persistente al cargar el perfil
          }
        }
      }
    } catch (e) {
      // Error en la inicialización, pero la app puede continuar
    }
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
        'field_type': fieldType,
        'value': value,
      };

      if (currentUserId != null) {
        requestBody['current_user_id'] = currentUserId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/users/check-availability/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data['success'] == true) {
          return data['available'] == true;
        }
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

  // Método para obtener razas/carreras
  Future<List<Race>> getRaces() async {
    try {
      final response = await _authenticatedRequest(
        'GET',
        racesEndpoint,
      );

      List<Race> results = [];

      if (response is List) {
        results = response.map((raceData) => Race.fromJson(raceData)).toList();
      } else if (response is Map<String, dynamic>) {
        if (response.containsKey('races') && response['races'] is List) {
          final List<dynamic> races = response['races'];
          results = races.map((raceData) => Race.fromJson(raceData)).toList();
        } else if (response.containsKey('results') &&
            response['results'] is List) {
          final List<dynamic> responseResults = response['results'];
          results = responseResults
              .map((raceData) => Race.fromJson(raceData))
              .toList();
        }
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  // Método para obtener conductores/pilotos
  Future<List<String>> getDrivers() async {
    try {
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
      return [];
    }
  }

  // Método para obtener resultados de apuestas del usuario
  Future<List<BetResult>> getUserBetResults() async {
    try {
      final response = await _authenticatedRequest(
        'GET',
        betsEndpoint,
      );

      List<BetResult> results = [];

      if (response is List) {
        results =
            response.map((betData) => BetResult.fromJson(betData)).toList();
      } else if (response is Map<String, dynamic>) {
        if (response.containsKey('bets') && response['bets'] is List) {
          final List<dynamic> bets = response['bets'];
          results = bets.map((betData) => BetResult.fromJson(betData)).toList();
        } else if (response.containsKey('results') &&
            response['results'] is List) {
          final List<dynamic> responseResults = response['results'];
          results = responseResults
              .map((betData) => BetResult.fromJson(betData))
              .toList();
        }
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  // Método para crear una apuesta
  Future<Map<String, dynamic>> createBet(Map<String, dynamic> bet) async {
    try {
      final response = await _authenticatedRequest(
        'POST',
        betsEndpoint,
        body: bet,
      );

      if (response != null) {
        if (response is Map<String, dynamic>) {
          if (response.containsKey('success') && response['success'] == true) {
            return {'success': true, 'bet': response};
          }
          if (response.containsKey('id')) {
            return {'success': true, 'bet': response};
          }
          if (response.containsKey('error')) {
            return {'success': false, 'error': response['error']};
          }
        }
        return {'success': true, 'bet': response};
      }
      return {'success': false, 'error': 'No se pudo crear la apuesta'};
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
        '$tournamentsEndpoint' + 'join/',
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
          // URL correcta para GitHub Pages con el subdirectorio y formato hash
          'frontend_url':
              'https://jeffreydtz.github.io/f1prode-flutter-webapp/#',
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
}
