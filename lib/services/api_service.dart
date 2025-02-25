import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

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
      String username, String email, String password) async {
    try {
      // Imprimir la URL para depuración
      final registerUrl = '$baseUrl$registerEndpoint';
      print('Intentando registro con URL: $registerUrl');

      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
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
    try {
      final loginUrl = '$baseUrl$loginEndpoint';
      print('Intentando login con URL: $loginUrl');
      print('Método: POST');
      print('Credenciales: username=$username, password=***');

      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('Código de estado de respuesta login: ${response.statusCode}');
      print('Respuesta completa: ${response.body}');
      print('Headers de respuesta: ${response.headers}');

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        print('Login exitoso, guardando tokens');
        await _saveTokens(
          accessToken: data['access'],
          refreshToken: data['refresh'],
        );

        // Cargar el perfil del usuario inmediatamente después de iniciar sesión
        try {
          print('Cargando perfil después de login');
          await _loadUserProfile();
          print(
              'Perfil cargado exitosamente después de login: ${currentUser?.username}');
        } catch (profileError) {
          print('Error al cargar perfil después de login: $profileError');
          // Continuar aunque haya error al cargar el perfil
        }

        print('Login completado para usuario: $username');
        return {'success': true};
      } else {
        print('Error en login: $data');
        if (data.containsKey('detail')) {
          return {'success': false, 'message': data['detail']};
        } else if (data.containsKey('non_field_errors')) {
          return {'success': false, 'message': data['non_field_errors'][0]};
        } else {
          return {
            'success': false,
            'message': 'Error de autenticación: ${response.statusCode}'
          };
        }
      }
    } on SocketException catch (e) {
      print('Error de conexión en login: ${e.toString()}');
      return {
        'success': false,
        'message':
            'No se pudo conectar al servidor. Verifica tu conexión a internet.'
      };
    } on FormatException catch (e) {
      print('Error de formato en login: ${e.toString()}');
      return {
        'success': false,
        'message': 'Error en el formato de la respuesta del servidor.'
      };
    } catch (e) {
      print('Error general en login: ${e.toString()}');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
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
          throw Exception('Error al procesar la respuesta del servidor');
        }
      } else {
        // Error en la respuesta
        print('Error en respuesta HTTP: ${response.statusCode}');
        try {
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
      print('Usando perfil de usuario en caché');

      // Asegurarse de que currentUser esté actualizado con los datos en caché
      if (currentUser == null && cachedData is Map<String, dynamic>) {
        currentUser = UserModel(
          id: cachedData['id']?.toString() ?? '',
          username: cachedData['username'] ?? 'Usuario',
          email: cachedData['email'] ?? '',
          password: '',
          points: cachedData['points'] ?? 0,
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

        // Actualizar el currentUser con los datos del perfil
        currentUser = UserModel(
          id: profileData['id']?.toString() ?? '',
          username: profileData['username'] ?? 'Usuario',
          email: profileData['email'] ?? '',
          password: '',
          points: profileData['points'] ?? 0,
        );

        print('Usuario actual actualizado: ${currentUser?.username}');

        // Guardar en caché
        _saveToCache(cacheKey, profileData);
        return profileData;
      } else {
        print('Respuesta de perfil no contiene datos: $profileData');
        throw Exception('No se pudo cargar el perfil');
      }
    } catch (e) {
      print('Error al cargar perfil: ${e.toString()}');
      rethrow;
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
      return cachedData;
    }

    try {
      print('Solicitando carreras del servidor (no en caché)');
      final response = await _authenticatedRequest(
        'GET',
        racesEndpoint,
      );

      print('Respuesta de carreras: $response');

      List<Race> results = [];

      if (response is List) {
        print('Respuesta es una lista con ${response.length} elementos');
        results = response.map((raceData) => Race.fromJson(raceData)).toList();
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

      // Guardar en caché
      _saveToCache(cacheKey, results);
      return results;
    } catch (e) {
      print('Error al obtener carreras: ${e.toString()}');
      rethrow;
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
        // Intentar encontrar una propiedad que contenga la lista de apuestas
        if (response.containsKey('bets') && response['bets'] is List) {
          final List<dynamic> bets = response['bets'];
          print(
              'Encontrada lista de apuestas en propiedad "bets" con ${bets.length} elementos');
          results = bets.map((betData) => BetResult.fromJson(betData)).toList();
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
      print('Error al obtener resultados de apuestas: ${e.toString()}');
      rethrow;
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
        '$tournamentsEndpoint/join/',
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
