import 'dart:convert';
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
      final response = await http.post(
        Uri.parse('$baseUrl$registerEndpoint'),
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
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$loginEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data['access'] != null && data['refresh'] != null) {
          await _saveTokens(data['access'], data['refresh']);

          // Obtener información del usuario después de iniciar sesión
          try {
            await _loadUserProfile();
            return {'success': true};
          } catch (e) {
            // Si falla la carga del perfil, aún así consideramos el login exitoso
            return {
              'success': true,
              'warning': 'Login exitoso pero no se pudo cargar el perfil'
            };
          }
        } else {
          return {
            'success': false,
            'error': 'Respuesta incompleta del servidor'
          };
        }
      } else if (response.statusCode == 401) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': false,
          'error': data['detail'] ?? 'Credenciales inválidas'
        };
      } else {
        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          return {
            'success': false,
            'error': data['detail'] ?? 'Error al iniciar sesión'
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Error del servidor (${response.statusCode})'
          };
        }
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
        if (data['access'] != null) {
          await _saveTokens(data['access'], null);
          return true;
        }
      }

      // Si llegamos aquí, el refresh token no es válido
      await _clearTokens();
      return false;
    } catch (e) {
      // En caso de error, limpiamos los tokens para forzar un nuevo login
      await _clearTokens();
      return false;
    }
  }

  Future<void> _saveTokens(String? accessToken, String? refreshToken) async {
    final prefs = await _storage;
    if (accessToken != null) {
      await prefs.setString('access_token', accessToken);
      _accessToken = accessToken;

      // Extraer y guardar el ID del usuario del token JWT
      try {
        final decodedToken = JwtDecoder.decode(accessToken);
        if (decodedToken.containsKey('user_id')) {
          await prefs.setString('user_id', decodedToken['user_id'].toString());
        }
      } catch (e) {
        // Ignorar errores al decodificar el token
      }
    }
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
      _refreshToken = refreshToken;
    }
  }

  Future<void> _loadTokens() async {
    final prefs = await _storage;
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<void> _clearTokens() async {
    final prefs = await _storage;
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    _accessToken = null;
    _refreshToken = null;
    currentUser = null;
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // -------------------------------------------------
  // 4. AUTHENTICATED REQUEST HELPER
  // -------------------------------------------------
  Future<dynamic> _authenticatedRequest(
    String endpoint,
    String method, {
    dynamic body,
    bool requiresAuth = true,
    int retryCount = 0,
  }) async {
    try {
      if (requiresAuth) {
        final token = await _getAccessToken();
        if (token == null) {
          throw Exception('No hay sesión activa');
        }
      }

      final headers = await _getAuthHeaders();
      http.Response response;

      final uri = Uri.parse('$baseUrl$endpoint');

      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PATCH':
          response = await http.patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw Exception('Método HTTP no soportado: $method');
      }

      // Manejar respuesta según el código de estado
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Respuesta exitosa
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else if (response.statusCode == 401 && requiresAuth && retryCount < 1) {
        // Token expirado, intentar refrescar
        final refreshed = await _refreshAccessTokenFromServer();
        if (refreshed) {
          // Reintentar con el nuevo token
          return _authenticatedRequest(
            endpoint,
            method,
            body: body,
            requiresAuth: requiresAuth,
            retryCount: retryCount + 1,
          );
        } else {
          throw Exception('Sesión expirada');
        }
      } else {
        // Otros errores
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData is Map) {
            final errorMessage = errorData['detail'] ??
                errorData['error'] ??
                'Error del servidor (${response.statusCode})';
            throw Exception(errorMessage);
          }
        } catch (e) {
          // Si no podemos decodificar la respuesta, usamos el código de estado
          throw Exception('Error del servidor (${response.statusCode})');
        }
        throw Exception('Error del servidor (${response.statusCode})');
      }
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Error en formato de respuesta: ${e.message}');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error inesperado: ${e.toString()}');
    }
  }

  // -------------------------------------------------
  // 5. USER PROFILE
  // -------------------------------------------------
  Future<void> _loadUserProfile() async {
    try {
      final response = await _authenticatedRequest(
        profileEndpoint,
        'GET',
      );

      if (response['success'] && response['profile'] != null) {
        final profileData = response['profile'];
        currentUser = UserModel(
          id: profileData['id'].toString(),
          username: profileData['username'] ?? '',
          email: profileData['email'] ?? '',
          password: '',
          points: profileData['points'] ?? 0,
        );
      }
    } catch (e) {
      // Si falla, no establecemos el currentUser
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _authenticatedRequest(
        profileEndpoint,
        'GET',
      );

      if (response['success']) {
        return response;
      } else {
        final error = response['error'] ?? 'Error al obtener el perfil';
        return {
          'success': false,
          'error': error,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    String? username,
    String? email,
  }) async {
    try {
      final body = {
        if (username != null) 'username': username,
        if (email != null) 'email': email,
      };

      final response = await _authenticatedRequest(
        profileEndpoint,
        'PATCH',
        body: body,
      );

      if (response['success']) {
        // Actualizar el usuario actual si la respuesta es exitosa
        await _loadUserProfile();
        return response;
      } else {
        final error = response['error'] ?? 'Error al actualizar el perfil';
        return {
          'success': false,
          'error': error,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // -------------------------------------------------
  // 6. RACES
  // -------------------------------------------------
  Future<List<Race>> getRaces() async {
    try {
      final response = await _authenticatedRequest(
        racesEndpoint,
        'GET',
      );

      if (response['success']) {
        final List<dynamic> jsonList = response['races'];
        return jsonList.map((raceJson) => Race.fromJson(raceJson)).toList();
      } else {
        throw Exception('Error al obtener carreras: ${response['error']}');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // -------------------------------------------------
  // 7. DRIVERS
  // -------------------------------------------------
  Future<List<String>> getDrivers({String? season}) async {
    try {
      final endpoint =
          season != null ? '$driversEndpoint?season=$season' : driversEndpoint;

      final response = await _authenticatedRequest(
        endpoint,
        'GET',
      );

      if (response['success']) {
        final List<dynamic> driversList = response['drivers'];
        final List<String> pilotNames =
            driversList.map((driver) => driver.toString()).toList();
        return pilotNames;
      } else {
        throw Exception('Error al obtener drivers: ${response['error']}');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // -------------------------------------------------
  // 8. BETS
  // -------------------------------------------------
  Future<List<BetResult>> getUserBetResults() async {
    try {
      final response = await _authenticatedRequest(
        betsEndpoint,
        'GET',
      );

      if (response['success']) {
        final List<dynamic> bets = response['bets'] ?? [];
        return bets.map((betData) => BetResult.fromJson(betData)).toList();
      } else {
        throw Exception('Error al obtener apuestas: ${response['error']}');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
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
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Usuario no autenticado');

      final requestBody = {
        'user': userId,
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
        if (hasSprint && sprintTop10 != null) 'sprint_top10': sprintTop10,
      };

      final response = await _authenticatedRequest(
        betsEndpoint,
        'POST',
        body: requestBody,
      );

      if (response['success']) {
        return true;
      } else {
        final error = response['error'] ?? 'Error desconocido';
        throw Exception('Error al crear apuesta: $error');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // -------------------------------------------------
  // 9. TOURNAMENTS
  // -------------------------------------------------
  Future<List<Tournament>> getTournaments() async {
    try {
      final response = await _authenticatedRequest(
        tournamentsEndpoint,
        'GET',
      );

      if (response['success']) {
        final List<dynamic> jsonList = response['tournaments'];
        final tournaments =
            jsonList.map((json) => Tournament.fromJson(json)).toList();
        return tournaments;
      } else {
        throw Exception('Error al obtener torneos: ${response['error']}');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<Tournament> createTournament(String name) async {
    try {
      final response = await _authenticatedRequest(
        tournamentsEndpoint,
        'POST',
        body: {'name': name},
      );

      if (response['success']) {
        return Tournament.fromJson(response['tournament']);
      } else {
        final error = response['error'] ?? 'Error desconocido';
        throw Exception('Error al crear torneo: $error');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<bool> joinTournament(String inviteCode) async {
    try {
      final response = await _authenticatedRequest(
        '$tournamentsEndpoint/join/',
        'POST',
        body: {'inviteCode': inviteCode},
      );

      if (response['success']) {
        return true;
      } else {
        throw Exception(response['error'] ?? 'Error al unirse al torneo');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getTournamentLeaderboard(
      int tournamentId) async {
    try {
      final response = await _authenticatedRequest(
        '$tournamentsEndpoint/$tournamentId/leaderboard/',
        'GET',
      );

      if (response['success']) {
        return response;
      } else {
        throw Exception(
            response['error'] ?? 'Error al obtener la clasificación');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // -------------------------------------------------
  // 10. SESSION MANAGEMENT
  // -------------------------------------------------
  Future<void> logout() async {
    await _clearTokens();
  }

  Future<bool> isLoggedIn() async {
    final token = await _getAccessToken();
    if (token == null) return false;

    try {
      // Verificar si el token está expirado
      final isExpired = JwtDecoder.isExpired(token);
      if (isExpired) {
        // Intentar refrescar el token
        return await _refreshAccessTokenFromServer();
      }
      return true;
    } catch (e) {
      // Si hay error al decodificar, consideramos que no hay sesión válida
      return false;
    }
  }

  Future<String?> getCurrentUserId() async {
    try {
      final prefs = await _storage;
      final userId = prefs.getString('user_id');

      if (userId == null) {
        // Intentar extraer del token
        final token = await _getAccessToken();
        if (token != null) {
          try {
            final decodedToken = JwtDecoder.decode(token);
            if (decodedToken.containsKey('user_id')) {
              final id = decodedToken['user_id'].toString();
              await prefs.setString('user_id', id);
              return id;
            }
          } catch (e) {
            // Ignorar errores al decodificar
          }
        }
      }

      return userId;
    } catch (e) {
      return null;
    }
  }
}
