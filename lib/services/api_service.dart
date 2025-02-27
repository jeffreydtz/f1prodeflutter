import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../utils/logger.dart';

import '../models/betresult.dart';
import '../models/user.dart';
import '../models/race.dart';
import '../models/bet.dart';
import '../models/tournament.dart';

class ApiService {
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    Logger.info('ApiService inicializado');
  }

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
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Endpoints
  static const String loginEndpoint = '/token/';
  static const String refreshEndpoint = '/token/refresh/';
  static const String registerEndpoint = '/users/register/';
  static const String profileEndpoint = '/users/profile/';
  static const String racesEndpoint = '/f1/races/';
  static const String driversEndpoint = '/f1/drivers/';
  static const String betsEndpoint = '/bets/';
  static const String tournamentsEndpoint = '/tournaments/';

  final _storage = SharedPreferences.getInstance();

  // -------------------------------------------------
  // 1. REGISTER (CREACIÓN DE USUARIO)
  // -------------------------------------------------
  Future<Map<String, dynamic>> register(
      String username, 
      String email,
      String password, 
      String passwordConfirm,
      {String? avatarBase64}) async {
    
      // Imprimir la URL para depuración
      final registerUrl = '$baseUrl$registerEndpoint';
      print('Intentando registro con URL: $registerUrl');

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

      // Imprimir el código de estado para depuración
      print('Código de estado de respuesta registro: ${response.statusCode}');

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 201) {
        print('Registro exitoso: ${data['user']}');
        return {'success': true, 'user': data['user']};
      } else {
        print('Error en registro: $data');
        return {'success': false, 'errors': data};
      }
    } on http.ClientException catch (e) {
      print('Error de conexión en registro: ${e.message}');
      return {'success': false, 'error': 'Error de conexión: ${e.message}'};
    } on FormatException catch (e) {
      print('Error en formato de respuesta registro: ${e.message}');
      return {
        'success': false,
        'error': 'Error en formato de respuesta: ${e.message}'
      };
    } catch (e) {
      print('Error inesperado en registro: ${e.toString()}');
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
      Logger.info('Iniciando login: $username en $loginUrl');

      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      Logger.info(
          'Código de estado de respuesta login: ${response.statusCode}');

      if (response.statusCode == 200) {
        Logger.info('Login exitoso, procesando datos');

        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // Guardar tokens
        final String accessToken = data['access'];
        final String refreshToken = data['refresh'];

        Logger.info(
            'Guardando tokens - Access: ${accessToken.isNotEmpty ? "presente" : "ausente"}, Refresh: ${refreshToken.isNotEmpty ? "presente" : "ausente"}');

        _accessToken = accessToken;
        _refreshToken = refreshToken;

        // Decodificar token para obtener user_id
        String userId = '0';
        try {
          Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
          Logger.info('Token decodificado: $decodedToken');

          if (decodedToken.containsKey('user_id')) {
            userId = decodedToken['user_id'].toString();
            Logger.info('ID de usuario extraído del token: $userId');
          } else {
            Logger.warning('El token no contiene user_id');
          }
        } catch (e) {
          Logger.error('Error al extraer ID del token: $e');
        }

        // Guardar tokens en SharedPreferences
        await _saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        // Inicializar usuario
        currentUser = UserModel(
          id: userId,
          username: username,
          email: '',
          password: '',
          points: 0,
        );

        Logger.info('Usuario establecido con nombre: $username y ID: $userId');

        // Guardar en caché
        _saveToCache('user_profile', {
          'id': userId,
          'username': username,
          'email': '',
          'points': 0,
        });

        // Cargar perfil detallado después del login
        Logger.info('Cargando perfil detallado después de login');
        try {
          await _loadUserProfile();
          Logger.info('Perfil cargado: ${currentUser?.username}');
        } catch (profileError) {
          Logger.error(
              'Error al cargar perfil completo: $profileError - Continuando con datos básicos');
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

        print('Error en login: $errorMessage');
        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      print('Error general en login: ${e.toString()}');
      return {'success': false, 'error': 'Error de conexión: ${e.toString()}'};
    }
  }

  // -------------------------------------------------
  // 3. TOKEN MANAGEMENT
  // -------------------------------------------------
  Future<String?> _getAccessToken() async {
    if (_accessToken == null) {
      final prefs = await _storage;
      _accessToken = prefs.getString('access_token');
    }
    return _accessToken;
  }

  Future<String?> _getRefreshToken() async {
    if (_refreshToken == null) {
      final prefs = await _storage;
      _refreshToken = prefs.getString('refresh_token');
    }
    return _refreshToken;
  }

  Future<bool> _refreshAccessTokenFromServer() async {
    try {
      print('Iniciando proceso de renovación de token');
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) {
        print('No hay refresh token disponible');
        return false;
      }

      print('Intentando refrescar token con URL: $baseUrl$refreshEndpoint');
      print('Refresh token: ${refreshToken.substring(0, 10)}...');

      final response = await http.post(
        Uri.parse('$baseUrl$refreshEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': refreshToken}),
      );

      print('Código de estado de respuesta refresh: ${response.statusCode}');
      print('Respuesta completa: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('Token recibido: ${data['access'].substring(0, 10)}...');

        await _saveTokens(
          accessToken: data['access'],
          refreshToken: refreshToken, // Mantener el mismo refresh token
        );
        print('Token refrescado exitosamente');
        return true;
      } else {
        print('Error al refrescar token: ${response.body}');
        print('Limpiando tokens debido a error de refresh');
        await _clearTokens();
        return false;
      }
    } catch (e) {
      print('Error en refresh token: ${e.toString()}');
      print('Limpiando tokens debido a excepción');
      await _clearTokens();
      return false;
    }
  }

  Future<void> _saveTokens({String? accessToken, String? refreshToken}) async {
    print(
        'Guardando tokens - Access: ${accessToken != null ? 'presente' : 'null'}, Refresh: ${refreshToken != null ? 'presente' : 'null'}');

    final prefs = await _storage;
    if (accessToken != null) {
      await prefs.setString('access_token', accessToken);
      _accessToken = accessToken;

      // Extraer y guardar el ID del usuario del token JWT
      try {
        final decodedToken = JwtDecoder.decode(accessToken);
        print('Token decodificado: $decodedToken');

        if (decodedToken.containsKey('user_id')) {
          final userId = decodedToken['user_id'].toString();
          await prefs.setString('user_id', userId);
          print('ID de usuario guardado: $userId');
        } else {
          print('El token no contiene user_id');
        }
      } catch (e) {
        // Ignorar errores al decodificar el token
        print('Error al decodificar token: ${e.toString()}');
      }
    }
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
      _refreshToken = refreshToken;
      print('Refresh token guardado');
    }
  }

  Future<void> _loadTokens() async {
    final prefs = await _storage;
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<void> _clearTokens() async {
    print('Limpiando tokens de sesión');

    final prefs = await _storage;
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    _accessToken = null;
    _refreshToken = null;
    currentUser = null;

    print('Tokens limpiados correctamente');
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAccessToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    print('Headers de autenticación: $headers');
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
  }) async {
    print('Iniciando solicitud autenticada: $method $endpoint');

    final url = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );
    print('URL completa: $url');

    // Verificar si hay token de acceso
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      print('No hay token de acceso disponible para la solicitud');
      throw Exception('No hay token de acceso disponible');
    }

    // Obtener headers con token
    final headers = await _getAuthHeaders();
    print('Headers para solicitud: $headers');

    http.Response response;
    try {
      // Realizar la solicitud según el método
      switch (method.toUpperCase()) {
        case 'GET':
          print('Ejecutando solicitud GET');
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          print('Ejecutando solicitud POST con body: $body');
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          print('Ejecutando solicitud PUT con body: $body');
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PATCH':
          print('Ejecutando solicitud PATCH con body: $body');
          response = await http.patch(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          print('Ejecutando solicitud DELETE');
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Método HTTP no soportado: $method');
      }

      print('Respuesta recibida: ${response.statusCode}');

      // Si el token expiró (401), intentar refrescarlo y reintentar
      if (response.statusCode == 401) {
        print('Token expirado (401), intentando refrescar');
        final refreshed = await _refreshAccessTokenFromServer();

        if (refreshed) {
          print('Token refrescado exitosamente, reintentando solicitud');
          // Obtener nuevos headers con el token refrescado
          final newHeaders = await _getAuthHeaders();
          print('Nuevos headers para reintento: $newHeaders');

          // Reintentar la solicitud con el nuevo token
          switch (method.toUpperCase()) {
            case 'GET':
              print('Reintentando solicitud GET');
              response = await http.get(url, headers: newHeaders);
              break;
            case 'POST':
              print('Reintentando solicitud POST');
              response = await http.post(
                url,
                headers: newHeaders,
                body: body != null ? jsonEncode(body) : null,
              );
              break;
            case 'PUT':
              print('Reintentando solicitud PUT');
              response = await http.put(
                url,
                headers: newHeaders,
                body: body != null ? jsonEncode(body) : null,
              );
              break;
            case 'PATCH':
              print('Reintentando solicitud PATCH');
              response = await http.patch(
                url,
                headers: newHeaders,
                body: body != null ? jsonEncode(body) : null,
              );
              break;
            case 'DELETE':
              print('Reintentando solicitud DELETE');
              response = await http.delete(url, headers: newHeaders);
              break;
            default:
              throw Exception('Método HTTP no soportado: $method');
          }
          print('Respuesta del reintento: ${response.statusCode}');
        } else {
          print(
              'No se pudo refrescar el token, la solicitud falló definitivamente');
        }
      }

      // Procesar la respuesta
      print('Procesando respuesta HTTP: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Respuesta exitosa
        if (response.body.isEmpty) {
          print('Respuesta vacía pero exitosa');
          return {'success': true};
        }

        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          print('Respuesta decodificada exitosamente');
          return data;
        } catch (e) {
          print('Error al decodificar respuesta: ${e.toString()}');

          // Verificar si la respuesta es HTML (comienza con <!DOCTYPE html>)
          final responseBody = utf8.decode(response.bodyBytes);
          if (responseBody.trim().startsWith('<!DOCTYPE html>') ||
              responseBody.trim().startsWith('<html>')) {
            print('La respuesta es HTML, posiblemente una página de error');
            throw Exception(
                'El servidor devolvió una página HTML en lugar de JSON. Posible error en la URL o en el servidor.');
          }

          throw Exception('Error al procesar la respuesta del servidor');
        }
      } else {
        // Error en la respuesta
        print('Error en respuesta HTTP: ${response.statusCode}');
        try {
          // Intentar decodificar como JSON
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          print('Datos de error: $errorData');

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
            print(
                'La respuesta de error es HTML, posiblemente una página de error');

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
      print('Error de conexión en solicitud autenticada: ${e.toString()}');
      throw Exception('Error de conexión: ${e.toString()}');
    } catch (e) {
      print('Error general en solicitud autenticada: ${e.toString()}');
      throw Exception('Error en solicitud: ${e.toString()}');
    }
  }

  // -------------------------------------------------
  // 5. USER PROFILE
  // -------------------------------------------------
  Future<Map<String, dynamic>> _loadUserProfile() async {
    const cacheKey = 'user_profile';

    // Verificar si hay datos en caché
    final cachedData = _getFromCache(cacheKey);
    if (cachedData != null) {
      print('Usando perfil de usuario en caché: ${cachedData['username']}');

      // Asegurarse de que currentUser esté actualizado con los datos en caché
      if (cachedData is Map<String, dynamic>) {
        currentUser = UserModel(
          id: cachedData['id']?.toString() ?? '',
          username: cachedData['username'] ?? 'Usuario',
          email: cachedData['email'] ?? '',
          password: '',
          points: cachedData['points'] ?? 0,
          avatar: cachedData['avatar'],
        );
        print(
            'Usuario actual actualizado desde caché: ${currentUser?.username}');
      }

      return cachedData;
    }

    print('Cargando perfil de usuario desde: $baseUrl$profileEndpoint');
    try {
      final response = await _authenticatedRequest(
        'GET',
        profileEndpoint,
      );

      final profileData = response;
      if (profileData != null && profileData is Map<String, dynamic>) {
        print('Perfil cargado exitosamente: ${profileData['username']}');

        // Asegurar que los campos necesarios existan
        final Map<String, dynamic> safeProfileData = {
          'id': profileData['id'] ?? 0,
          'username': profileData['username'] ?? 'Usuario',
          'email': profileData['email'] ?? '',
          'points': profileData['points'] ?? 0,
          'total_points':
              profileData['total_points'] ?? profileData['points'] ?? 0,
          'races_played': profileData['races_played'] ?? 0,
          'poles_guessed': profileData['poles_guessed'] ?? 0,
          'avatar': profileData['avatar'],
        };

        // Actualizar el currentUser con los datos del perfil
        currentUser = UserModel(
          id: safeProfileData['id'].toString(),
          username: safeProfileData['username'],
          email: safeProfileData['email'],
          password: '',
          points: safeProfileData['points'],
          avatar: safeProfileData['avatar'],
        );

        print('Usuario actual actualizado: ${currentUser?.username}');

        // Guardar en caché
        _saveToCache(cacheKey, safeProfileData);
        return safeProfileData;
      } else {
        print('Respuesta de perfil no contiene datos: $profileData');

        // Intentar obtener el ID del usuario del token
        String userId = '0';
        try {
          final token = await _getAccessToken();
          if (token != null) {
            final decodedToken = JwtDecoder.decode(token);
            if (decodedToken.containsKey('user_id')) {
              userId = decodedToken['user_id'].toString();
              print('ID de usuario extraído del token: $userId');
            }
          }
        } catch (e) {
          print('Error al extraer ID del token: $e');
        }

        // Crear un perfil por defecto si no hay datos
        final Map<String, dynamic> defaultProfile = {
          'id': userId,
          'username': 'Usuario',
          'email': '',
          'points': 0,
          'total_points': 0,
          'races_played': 0,
          'poles_guessed': 0,
          'avatar': null,
        };

        // Actualizar el currentUser con datos por defecto
        if (currentUser == null) {
          currentUser = UserModel(
            id: userId,
            username: 'Usuario',
            email: '',
            password: '',
            points: 0,
            avatar: null,
          );
        }

        print('Usando perfil por defecto debido a respuesta vacía');
        return defaultProfile;
      }
    } catch (e) {
      print('Error al cargar perfil: ${e.toString()}');

      // Intentar obtener el ID del usuario del token
      String userId = '0';
      try {
        final token = await _getAccessToken();
        if (token != null) {
          final decodedToken = JwtDecoder.decode(token);
          if (decodedToken.containsKey('user_id')) {
            userId = decodedToken['user_id'].toString();
            print('ID de usuario extraído del token: $userId');
          }
        }
      } catch (e) {
        print('Error al extraer ID del token: $e');
      }

      // Si hay un error, intentar usar el currentUser si existe
      if (currentUser != null) {
        print(
            'Usando currentUser existente como respaldo: ${currentUser!.username}');
        final Map<String, dynamic> fallbackProfile = {
          'id': currentUser!.id,
          'username': currentUser!.username,
          'email': currentUser!.email,
          'points': currentUser!.points,
          'total_points': currentUser!.points,
          'races_played': 0,
          'poles_guessed': 0,
          'avatar': currentUser!.avatar,
        };
        return fallbackProfile;
      }

      // Si no hay currentUser, crear uno por defecto
      print('Creando perfil por defecto debido a error');
      final Map<String, dynamic> defaultProfile = {
        'id': userId,
        'username': 'Usuario',
        'email': '',
        'points': 0,
        'total_points': 0,
        'races_played': 0,
        'poles_guessed': 0,
        'avatar': null,
      };

      // Actualizar el currentUser con datos por defecto
      currentUser = UserModel(
        id: userId,
        username: 'Usuario',
        email: '',
        password: '',
        points: 0,
        avatar: null,
      );

      return defaultProfile;
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      // Intentar cargar el perfil
      final profileData = await _loadUserProfile();
      return profileData;
    } catch (e) {
      print('Error al obtener perfil: ${e.toString()}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(
      Map<String, dynamic> body) async {
    try {
      print('Actualizando perfil de usuario con datos: $body');
      final response = await _authenticatedRequest(
        'PATCH',
        profileEndpoint,
        body: body,
      );

      print('Respuesta de actualización de perfil: $response');

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

          print(
              'Usuario actual actualizado después de edición: ${currentUser?.username}');

          // Actualizar la caché
          _saveToCache('user_profile', profileData);
        }

        return response;
      } else {
        throw Exception('Formato de respuesta inválido');
      }
    } catch (e) {
      print('Error al actualizar perfil: ${e.toString()}');
      rethrow;
    }
  }

  // -------------------------------------------------
  // 6. RACES
  // -------------------------------------------------
  Future<List<Race>> getRaces() async {
    const cacheKey = 'races';

    // Verificar si hay datos en caché
    final cachedData = _getFromCache(cacheKey);
    if (cachedData != null) {
      print('Usando datos de carreras en caché');
      return cachedData;
    }

    try {
      print('Solicitando carreras del servidor (no en caché)');

      // Intentar con el endpoint original
      try {
        final response = await _authenticatedRequest(
          'GET',
          racesEndpoint,
        );

        print('Respuesta de carreras: $response');

        List<Race> results = [];

        if (response is List) {
          print('Respuesta es una lista con ${response.length} elementos');
          results =
              response.map((raceData) => Race.fromJson(raceData)).toList();
        } else if (response is Map<String, dynamic>) {
          print('Respuesta es un objeto: ${response.keys}');
          // Intentar encontrar una propiedad que contenga la lista de carreras
          if (response.containsKey('races') && response['races'] is List) {
            final List<dynamic> races = response['races'];
            print(
                'Encontrada lista de carreras en propiedad "races" con ${races.length} elementos');
            results = races.map((raceData) => Race.fromJson(raceData)).toList();
          } else if (response.containsKey('results') &&
              response['results'] is List) {
            final List<dynamic> responseResults = response['results'];
            print(
                'Encontrada lista de carreras en propiedad "results" con ${responseResults.length} elementos');
            results = responseResults
                .map((raceData) => Race.fromJson(raceData))
                .toList();
          } else {
            // Si no hay carreras, devolver una lista vacía
            print('No se encontró una lista de carreras en la respuesta');
          }
        } else {
          print('Formato de respuesta inesperado: ${response.runtimeType}');
          throw Exception('Formato de respuesta inválido');
        }

        if (results.isNotEmpty) {
          // Guardar en caché solo si hay resultados
          print('Guardando ${results.length} carreras en caché');
          _saveToCache(cacheKey, results);
          return results;
        } else {
          throw Exception('No se encontraron carreras en la respuesta');
        }
      } catch (e) {
        // Si falla con el endpoint original, intentar con un endpoint alternativo
        print(
            'Error con endpoint original: $e. Intentando endpoint alternativo...');

        try {
          // Intentar con un endpoint alternativo
          final alternativeEndpoint = '/f1/races/list/';
          final response = await _authenticatedRequest(
            'GET',
            alternativeEndpoint,
          );

          print('Respuesta de carreras (endpoint alternativo): $response');

          List<Race> results = [];

          if (response is List) {
            print('Respuesta es una lista con ${response.length} elementos');
            results =
                response.map((raceData) => Race.fromJson(raceData)).toList();
          } else if (response is Map<String, dynamic>) {
            print('Respuesta es un objeto: ${response.keys}');
            // Intentar encontrar una propiedad que contenga la lista de carreras
            if (response.containsKey('races') && response['races'] is List) {
              final List<dynamic> races = response['races'];
              print(
                  'Encontrada lista de carreras en propiedad "races" con ${races.length} elementos');
              results =
                  races.map((raceData) => Race.fromJson(raceData)).toList();
            } else if (response.containsKey('results') &&
                response['results'] is List) {
              final List<dynamic> responseResults = response['results'];
              print(
                  'Encontrada lista de carreras en propiedad "results" con ${responseResults.length} elementos');
              results = responseResults
                  .map((raceData) => Race.fromJson(raceData))
                  .toList();
            } else {
              // Si no hay carreras, devolver una lista vacía
              print('No se encontró una lista de carreras en la respuesta');
            }
          } else {
            print('Formato de respuesta inesperado: ${response.runtimeType}');
            throw Exception('Formato de respuesta inválido');
          }

          if (results.isNotEmpty) {
            // Guardar en caché solo si hay resultados
            print(
                'Guardando ${results.length} carreras en caché (endpoint alternativo)');
            _saveToCache(cacheKey, results);
            return results;
          } else {
            throw Exception(
                'No se encontraron carreras en la respuesta alternativa');
          }
        } catch (e2) {
          // Si falla con el segundo endpoint, intentar con un tercer endpoint
          print(
              'Error con segundo endpoint: $e2. Intentando tercer endpoint...');

          try {
            // Intentar con un tercer endpoint
            final thirdEndpoint = '/races/';
            final response = await _authenticatedRequest(
              'GET',
              thirdEndpoint,
            );

            print('Respuesta de carreras (tercer endpoint): $response');

            List<Race> results = [];

            if (response is List) {
              print('Respuesta es una lista con ${response.length} elementos');
              results =
                  response.map((raceData) => Race.fromJson(raceData)).toList();
            } else if (response is Map<String, dynamic>) {
              print('Respuesta es un objeto: ${response.keys}');
              // Intentar encontrar una propiedad que contenga la lista de carreras
              if (response.containsKey('races') && response['races'] is List) {
                final List<dynamic> races = response['races'];
                print(
                    'Encontrada lista de carreras en propiedad "races" con ${races.length} elementos');
                results =
                    races.map((raceData) => Race.fromJson(raceData)).toList();
              } else if (response.containsKey('results') &&
                  response['results'] is List) {
                final List<dynamic> responseResults = response['results'];
                print(
                    'Encontrada lista de carreras en propiedad "results" con ${responseResults.length} elementos');
                results = responseResults
                    .map((raceData) => Race.fromJson(raceData))
                    .toList();
              } else {
                // Si no hay carreras, devolver una lista vacía
                print('No se encontró una lista de carreras en la respuesta');
              }
            } else {
              print('Formato de respuesta inesperado: ${response.runtimeType}');
              throw Exception('Formato de respuesta inválido');
            }

            if (results.isNotEmpty) {
              // Guardar en caché solo si hay resultados
              print(
                  'Guardando ${results.length} carreras en caché (tercer endpoint)');
              _saveToCache(cacheKey, results);
              return results;
            } else {
              throw Exception(
                  'No se encontraron carreras en la tercera respuesta');
            }
          } catch (e3) {
            print(
                'Error con tercer endpoint: $e3. Todos los intentos fallaron. Usando datos predeterminados.');

            // Crear datos de carreras predeterminados como último recurso
            final defaultRaces = _getDefaultRaces();
            print('Usando ${defaultRaces.length} carreras predeterminadas');

            // Guardar en caché los datos predeterminados
            _saveToCache(cacheKey, defaultRaces);
            return defaultRaces;
          }
        }
      }
    } catch (e) {
      print('Error al obtener carreras: ${e.toString()}');

      // Crear datos de carreras predeterminados como último recurso
      final defaultRaces = _getDefaultRaces();
      print(
          'Usando ${defaultRaces.length} carreras predeterminadas debido a error general');

      // Guardar en caché los datos predeterminados
      _saveToCache(cacheKey, defaultRaces);
      return defaultRaces;
    }
  }

  // Método para obtener datos de carreras predeterminados
  List<Race> _getDefaultRaces() {
    print('Generando datos de carreras predeterminados');

    // Crear carreras actualizadas para 2024
    return [
      Race(
        season: '2024',
        round: '1',
        name: 'Bahrain Grand Prix',
        date: '2024-03-02',
        circuit: 'Bahrain International Circuit',
        hasSprint: false,
        completed: true, // Ya pasó
      ),
      Race(
        season: '2024',
        round: '2',
        name: 'Saudi Arabian Grand Prix',
        date: '2024-03-09',
        circuit: 'Jeddah Corniche Circuit',
        hasSprint: false,
        completed: true, // Ya pasó
      ),
      Race(
        season: '2024',
        round: '3',
        name: 'Australian Grand Prix',
        date: '2024-03-24',
        circuit: 'Albert Park Circuit',
        hasSprint: false,
        completed: true, // Ya pasó
      ),
      Race(
        season: '2024',
        round: '4',
        name: 'Japanese Grand Prix',
        date: '2024-04-07',
        circuit: 'Suzuka International Racing Course',
        hasSprint: false,
        completed: true, // Ya pasó
      ),
      Race(
        season: '2024',
        round: '5',
        name: 'Chinese Grand Prix',
        date: '2024-04-21',
        circuit: 'Shanghai International Circuit',
        hasSprint: true,
        completed: true, // Ya pasó
      ),
      Race(
        season: '2024',
        round: '6',
        name: 'Miami Grand Prix',
        date: '2024-05-05',
        circuit: 'Miami International Autodrome',
        hasSprint: true,
        completed: true, // Ya pasó
      ),
      Race(
        season: '2024',
        round: '7',
        name: 'Emilia Romagna Grand Prix',
        date: '2024-05-19',
        circuit: 'Autodromo Enzo e Dino Ferrari',
        hasSprint: false,
        completed: _isDatePassed('2024-05-19'), // Verificar si la fecha ya pasó
      ),
      Race(
        season: '2024',
        round: '8',
        name: 'Monaco Grand Prix',
        date: '2024-05-26',
        circuit: 'Circuit de Monaco',
        hasSprint: false,
        completed: _isDatePassed('2024-05-26'), // Verificar si la fecha ya pasó
      ),
      Race(
        season: '2024',
        round: '9',
        name: 'Canadian Grand Prix',
        date: '2024-06-09',
        circuit: 'Circuit Gilles Villeneuve',
        hasSprint: false,
        completed: _isDatePassed('2024-06-09'),
      ),
      Race(
        season: '2024',
        round: '10',
        name: 'Spanish Grand Prix',
        date: '2024-06-23',
        circuit: 'Circuit de Barcelona-Catalunya',
        hasSprint: false,
        completed: _isDatePassed('2024-06-23'),
      ),
      Race(
        season: '2024',
        round: '11',
        name: 'Austrian Grand Prix',
        date: '2024-06-30',
        circuit: 'Red Bull Ring',
        hasSprint: true,
        completed: _isDatePassed('2024-06-30'),
      ),
      Race(
        season: '2024',
        round: '12',
        name: 'British Grand Prix',
        date: '2024-07-07',
        circuit: 'Silverstone Circuit',
        hasSprint: false,
        completed: _isDatePassed('2024-07-07'),
      ),
      Race(
        season: '2024',
        round: '13',
        name: 'Hungarian Grand Prix',
        date: '2024-07-21',
        circuit: 'Hungaroring',
        hasSprint: false,
        completed: _isDatePassed('2024-07-21'),
      ),
      Race(
        season: '2024',
        round: '14',
        name: 'Belgian Grand Prix',
        date: '2024-07-28',
        circuit: 'Circuit de Spa-Francorchamps',
        hasSprint: false,
        completed: _isDatePassed('2024-07-28'),
      ),
    ];
  }

  // Método auxiliar para verificar si una fecha ya pasó
  bool _isDatePassed(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      return date.isBefore(now);
    } catch (e) {
      print('Error al parsear fecha: $e');
      return false;
    }
  }

  // -------------------------------------------------
  // 7. DRIVERS
  // -------------------------------------------------
  Future<List<String>> getDrivers() async {
    final endpoint = driversEndpoint;
    try {
      final response = await _authenticatedRequest(
        'GET',
        endpoint,
      );

      print('Respuesta de pilotos: $response');

      if (response is List) {
        print('Respuesta es una lista con ${response.length} elementos');
        return response.map((driver) => driver.toString()).toList();
      } else if (response is Map<String, dynamic>) {
        print('Respuesta es un objeto: ${response.keys}');
        // Intentar encontrar una propiedad que contenga la lista de pilotos
        if (response.containsKey('drivers') && response['drivers'] is List) {
          final List<dynamic> drivers = response['drivers'];
          print(
              'Encontrada lista de pilotos en propiedad "drivers" con ${drivers.length} elementos');
          return drivers.map((driver) => driver.toString()).toList();
        } else if (response.containsKey('results') &&
            response['results'] is List) {
          final List<dynamic> results = response['results'];
          print(
              'Encontrada lista de pilotos en propiedad "results" con ${results.length} elementos');
          return results.map((driver) => driver.toString()).toList();
        } else {
          // Si no hay pilotos, devolver una lista vacía
          print('No se encontró una lista de pilotos en la respuesta');
          return [];
        }
      } else {
        print('Formato de respuesta inesperado: ${response.runtimeType}');
        throw Exception('Formato de respuesta inválido');
      }
    } catch (e) {
      print('Error al obtener pilotos: ${e.toString()}');
      rethrow;
    }
  }

  // -------------------------------------------------
  // 8. BETS
  // -------------------------------------------------
  Future<List<BetResult>> getUserBetResults() async {
    const cacheKey = 'user_bets';

    // Verificar si hay datos en caché
    final cachedData = _getFromCache(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      print('Solicitando apuestas del servidor (no en caché)');

      // Intentar con el endpoint original
      try {
        final response = await _authenticatedRequest(
          'GET',
          betsEndpoint,
        );

        print('Respuesta de apuestas: $response');

        List<BetResult> results = [];

        if (response is List) {
          print('Respuesta es una lista con ${response.length} elementos');
          results =
              response.map((betData) => BetResult.fromJson(betData)).toList();
        } else if (response is Map<String, dynamic>) {
          print('Respuesta es un objeto: ${response.keys}');

          // Verificar si la respuesta contiene una URL a la lista de apuestas
          if (response.containsKey('bets') && response['bets'] is String) {
            final String betsUrl = response['bets'];
            print('Encontrada URL de apuestas: $betsUrl');

            // Extraer el path de la URL
            Uri uri = Uri.parse(betsUrl);
            String path = uri.path;
            if (path.startsWith('/api')) {
              path = path.substring(4); // Eliminar '/api' del inicio
            }

            print('Solicitando apuestas desde path: $path');

            // Hacer una nueva solicitud a la URL de apuestas
            try {
              final betsResponse = await _authenticatedRequest(
                'GET',
                path,
              );

              print('Respuesta de URL de apuestas: $betsResponse');

              if (betsResponse is List) {
                print(
                    'Respuesta de URL es una lista con ${betsResponse.length} elementos');
                results = betsResponse
                    .map((betData) => BetResult.fromJson(betData))
                    .toList();
              } else if (betsResponse is Map<String, dynamic> &&
                  betsResponse.containsKey('results') &&
                  betsResponse['results'] is List) {
                final List<dynamic> betsResults = betsResponse['results'];
                print(
                    'Encontrada lista de apuestas en results con ${betsResults.length} elementos');
                results = betsResults
                    .map((betData) => BetResult.fromJson(betData))
                    .toList();
              } else {
                print('No se pudo obtener lista de apuestas de la URL');
              }
            } catch (e) {
              print('Error al obtener apuestas desde URL: $e');
            }
          }
          // Intentar encontrar una propiedad que contenga la lista de apuestas
          else if (response.containsKey('bets') && response['bets'] is List) {
            final List<dynamic> bets = response['bets'];
            print(
                'Encontrada lista de apuestas en propiedad "bets" con ${bets.length} elementos');
            results =
                bets.map((betData) => BetResult.fromJson(betData)).toList();
          } else if (response.containsKey('results') &&
              response['results'] is List) {
            final List<dynamic> responseResults = response['results'];
            print(
                'Encontrada lista de apuestas en propiedad "results" con ${responseResults.length} elementos');
            results = responseResults
                .map((betData) => BetResult.fromJson(betData))
                .toList();
          } else {
            // Si no hay apuestas, devolver una lista vacía
            print('No se encontró una lista de apuestas en la respuesta');
          }
        } else {
          print('Formato de respuesta inesperado: ${response.runtimeType}');
          throw Exception('Formato de respuesta inválido');
        }

        // Guardar en caché
        _saveToCache(cacheKey, results);
        return results;
      } catch (e) {
        // Si falla con el endpoint original, intentar con un endpoint alternativo
        print(
            'Error con endpoint original de apuestas: $e. Intentando endpoint alternativo...');

        // Intentar con un endpoint alternativo
        final alternativeEndpoint = '/bets/list/';
        final response = await _authenticatedRequest(
          'GET',
          alternativeEndpoint,
        );

        print('Respuesta de apuestas (endpoint alternativo): $response');

        List<BetResult> results = [];

        if (response is List) {
          print('Respuesta es una lista con ${response.length} elementos');
          results =
              response.map((betData) => BetResult.fromJson(betData)).toList();
        } else if (response is Map<String, dynamic>) {
          print('Respuesta es un objeto: ${response.keys}');
          // Intentar encontrar una propiedad que contenga la lista de apuestas
          if (response.containsKey('bets') && response['bets'] is List) {
            final List<dynamic> bets = response['bets'];
            print(
                'Encontrada lista de apuestas en propiedad "bets" con ${bets.length} elementos');
            results =
                bets.map((betData) => BetResult.fromJson(betData)).toList();
          } else if (response.containsKey('results') &&
              response['results'] is List) {
            final List<dynamic> responseResults = response['results'];
            print(
                'Encontrada lista de apuestas en propiedad "results" con ${responseResults.length} elementos');
            results = responseResults
                .map((betData) => BetResult.fromJson(betData))
                .toList();
          } else {
            // Si no hay apuestas, devolver una lista vacía
            print('No se encontró una lista de apuestas en la respuesta');
          }
        } else {
          print('Formato de respuesta inesperado: ${response.runtimeType}');
          throw Exception('Formato de respuesta inválido');
        }

        // Guardar en caché
        _saveToCache(cacheKey, results);
        return results;
      }
    } catch (e) {
      print('Error al obtener resultados de apuestas: ${e.toString()}');
      // En caso de error, devolver una lista vacía para evitar que la app se rompa
      return [];
    }
  }

  Future<bool> createBet({
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
      final requestBody = {
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
        requestBody['sprint_top10'] = sprintTop10;
      }

      final response = await _authenticatedRequest(
        'POST',
        betsEndpoint,
        body: requestBody,
      );

      return response != null;
    } catch (e) {
      print('Error al crear apuesta: ${e.toString()}');
      rethrow;
    }
  }

  // -------------------------------------------------
  // 9. TOURNAMENTS
  // -------------------------------------------------
  Future<List<Tournament>> getTournaments() async {
    const cacheKey = 'tournaments';

    // Verificar si hay datos en caché
    final cachedData = _getFromCache(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      print('Solicitando torneos del servidor (no en caché)');
      final response = await _authenticatedRequest(
        'GET',
        tournamentsEndpoint,
      );

      print('Respuesta de torneos: $response');

      List<Tournament> results = [];

      if (response is List) {
        print('Respuesta es una lista con ${response.length} elementos');
        results = response
            .map((tournamentData) => Tournament.fromJson(tournamentData))
            .toList();
      } else if (response is Map<String, dynamic>) {
        print('Respuesta es un objeto: ${response.keys}');
        // Intentar encontrar una propiedad que contenga la lista de torneos
        if (response.containsKey('tournaments') &&
            response['tournaments'] is List) {
          final List<dynamic> tournaments = response['tournaments'];
          print(
              'Encontrada lista de torneos en propiedad "tournaments" con ${tournaments.length} elementos');
          results = tournaments
              .map((tournamentData) => Tournament.fromJson(tournamentData))
              .toList();
        } else if (response.containsKey('results') &&
            response['results'] is List) {
          final List<dynamic> responseResults = response['results'];
          print(
              'Encontrada lista de torneos en propiedad "results" con ${responseResults.length} elementos');
          results = responseResults
              .map((tournamentData) => Tournament.fromJson(tournamentData))
              .toList();
        } else {
          // Si no hay torneos, devolver una lista vacía
          print('No se encontró una lista de torneos en la respuesta');
        }
      } else {
        print('Formato de respuesta inesperado: ${response.runtimeType}');
        throw Exception('Formato de respuesta inválido');
      }

      // Guardar en caché
      _saveToCache(cacheKey, results);
      return results;
    } catch (e) {
      print('Error al obtener torneos: ${e.toString()}');
      rethrow;
    }
  }

  Future<Tournament> createTournament(String name) async {
    try {
      final response = await _authenticatedRequest(
        'POST',
        tournamentsEndpoint,
        body: {'name': name},
      );

      if (response is Map<String, dynamic>) {
        return Tournament.fromJson(response);
      } else {
        throw Exception('Formato de respuesta inválido');
      }
    } catch (e) {
      print('Error al crear torneo: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> joinTournament(String inviteCode) async {
    try {
      final response = await _authenticatedRequest(
        'POST',
        'tournaments/join',
        body: {'inviteCode': inviteCode},
      );

      return response != null;
    } catch (e) {
      print('Error al unirse al torneo: ${e.toString()}');
      rethrow;
    }
  }

  Future<Tournament> getTournamentLeaderboard(int tournamentId) async {
    try {
      final response = await _authenticatedRequest(
        'GET',
        '$tournamentsEndpoint/$tournamentId/leaderboard/',
      );

      if (response is Map<String, dynamic>) {
        return Tournament.fromJson(response);
      } else {
        throw Exception('Formato de respuesta inválido');
      }
    } catch (e) {
      print('Error al obtener tabla de posiciones: ${e.toString()}');
      rethrow;
    }
  }

  // -------------------------------------------------
  // 10. SESSION MANAGEMENT
  // -------------------------------------------------
  Future<void> logout() async {
    print('Iniciando proceso de logout');
    await _clearTokens();
    clearCache(); // Limpiar caché al cerrar sesión
    print('Logout completado');
  }

  Future<bool> isLoggedIn() async {
    print('Verificando si el usuario está logueado...');
    final token = await _getAccessToken();
    if (token == null) {
      print('No hay token de acceso disponible');
      return false;
    }

    try {
      // Verificar si el token está expirado
      final isExpired = JwtDecoder.isExpired(token);
      print('Token de acceso expirado: $isExpired');
      print('Token: ${token.substring(0, 10)}...');

      if (isExpired) {
        // Intentar refrescar el token
        print('Intentando refrescar token expirado');
        return await _refreshAccessTokenFromServer();
      }
      print('Token de acceso válido');
      return true;
    } catch (e) {
      // Si hay error al decodificar, consideramos que no hay sesión válida
      print('Error al verificar token: ${e.toString()}');
      return false;
    }
  }

  Future<String?> getCurrentUserId() async {
    try {
      final prefs = await _storage;
      final userId = prefs.getString('user_id');

      if (userId == null) {
        print('No hay ID de usuario almacenado, intentando extraer del token');
        // Intentar extraer del token
        final token = await _getAccessToken();
        if (token != null) {
          try {
            final decodedToken = JwtDecoder.decode(token);
            print('Token decodificado: $decodedToken');

            if (decodedToken.containsKey('user_id')) {
              final id = decodedToken['user_id'].toString();
              await prefs.setString('user_id', id);
              print('ID de usuario extraído del token: $id');
              return id;
            } else {
              print('El token no contiene user_id');
            }
          } catch (e) {
            // Ignorar errores al decodificar
            print(
                'Error al decodificar token para obtener user_id: ${e.toString()}');
          }
        } else {
          print('No hay token de acceso disponible');
        }
      } else {
        print('ID de usuario encontrado en almacenamiento: $userId');
      }

      return userId;
    } catch (e) {
      print('Error al obtener ID de usuario: ${e.toString()}');
      return null;
    }
  }

  // Método para limpiar la caché
  void clearCache() {
    print('Limpiando caché de datos');
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // Método para verificar si un dato en caché es válido
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final timestamp = _cacheTimestamps[key]!;
    final now = DateTime.now();
    return now.difference(timestamp) < _cacheDuration;
  }

  // Método para guardar datos en caché
  void _saveToCache(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    print('Datos guardados en caché: $key');
  }

  // Método para obtener datos de caché
  dynamic _getFromCache(String key) {
    if (_isCacheValid(key)) {
      print('Usando datos en caché para: $key');
      return _cache[key];
    }
    return null;
  }

  // Método para obtener el usuario actual
  UserModel? getCurrentUser() {
    if (currentUser == null) {
      print('getCurrentUser: No hay usuario actual en memoria');
      // Intentar cargar el perfil de forma asíncrona si no está disponible
      _loadUserProfile().then((profile) {
        // El perfil ya se actualiza en _loadUserProfile
        print('Perfil cargado asíncronamente: ${currentUser?.username}');
      }).catchError((e) {
        print('Error al cargar perfil asíncronamente: $e');
      });
    } else {
      print(
          'getCurrentUser: Devolviendo usuario en memoria: ${currentUser?.username}');
    }

    return currentUser;
  }

  Future<bool> checkAvailability(String fieldType, String value,
      {String? currentUserId}) async {
    try {
      print('Verificando disponibilidad de $fieldType: $value');

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

      print(
          'Respuesta de verificación de disponibilidad: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('Datos de disponibilidad: $data');

        if (data['success'] == true) {
          return data['available'] == true;
        }
      }

      // En caso de error, asumimos que está disponible para evitar bloquear al usuario
      return true;
    } catch (e) {
      print('Error al verificar disponibilidad: ${e.toString()}');
      // En caso de error, asumimos que está disponible para evitar bloquear al usuario
      return true;
    }
  }
}
