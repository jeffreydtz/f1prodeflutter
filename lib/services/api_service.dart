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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 201) {
        return {'success': true};
      } else {
        return {'success': false, 'errors': data};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: ${e.toString()}'};
    }
  }

  // -------------------------------------------------
  // 2. LOGIN
  // -------------------------------------------------
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$loginEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['access'] != null) {
        final prefs = await _storage;
        await prefs.setString('access_token', data['access']);
        await prefs.setString('refresh_token', data['refresh']);
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': data['detail'] ?? 'Error al iniciar sesión'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: ${e.toString()}'};
    }
  }

  // -------------------------------------------------
  // 3. REFRESH TOKEN
  // -------------------------------------------------
  Future<bool> _refreshAccessTokenFromServer() async {
    try {
      final prefs = await _storage;
      final refreshToken = prefs.getString('refresh_token');

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
        await _saveTokens(data['access'], refreshToken);
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // -------------------------------------------------
  // 4. AUTHENTICATED REQUEST HELPER
  // -------------------------------------------------
  Future<dynamic> _authenticatedRequest(String endpoint, String method,
      {dynamic body}) async {
    try {
      final headers = await _getAuthHeaders();
      var response;

      switch (method) {
        case 'GET':
          response = await http.get(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
          );
          break;
        case 'POST':
          response = await http.post(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        // Añadir otros métodos según sea necesario
      }

      if (response.statusCode == 401) {
        // Token expirado, intentar refrescar
        final refreshed = await _refreshAccessTokenFromServer();
        if (refreshed) {
          // Reintentar con el nuevo token
          return _authenticatedRequest(endpoint, method, body: body);
        } else {
          throw Exception('Sesión expirada');
        }
      }

      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      throw Exception('Error en la solicitud: ${e.toString()}');
    }
  }

  // -------------------------------------------------
  // 5. TOKEN MANAGEMENT
  // -------------------------------------------------
  Future<String?> _getAccessToken() async {
    final prefs = await _storage;
    return prefs.getString('access_token');
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await _storage;
    return prefs.getString('refresh_token');
  }

  Future<bool> _refreshAccessToken() async {
    try {
      final refreshToken = await _getRefreshToken();

      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl$refreshEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await _storage;
        await prefs.setString('access_token', data['access']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveTokens(String? accessToken, String? refreshToken) async {
    final prefs = await _storage;
    if (accessToken != null) {
      await prefs.setString('access_token', accessToken);
      _accessToken = accessToken;
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
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // -------------------------------------------------
  // 3. OBTENER CARRERAS
  // -------------------------------------------------
  /// Llama al endpoint en Django que devuelve las próximas carreras (JSON).
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
      throw Exception('Error de conexión: $e');
    }
  }

  // -------------------------------------------------
  // 4. OBTENER DRIVERS
  // -------------------------------------------------
  /// Llama a /f1/drivers/ (JSON) y devuelve una lista de nombres de piloto
  Future<List<String>> getDrivers() async {
    try {
      final response = await _authenticatedRequest(
        driversEndpoint,
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
      throw Exception('Error de conexión (drivers): $e');
    }
  }

  // -------------------------------------------------
  // 5. OBTENER RESULTADOS DE APUESTAS
  // -------------------------------------------------
  /// Llama a /bets/results/?user_id=... y devuelve una lista de BetResult
  Future<List<BetResult>> getUserBetResults() async {
    try {
      final response = await _authenticatedRequest(
        betsEndpoint,
        'GET',
      );

      if (response['success']) {
        final List<dynamic> bets = response['bets'] ?? [];
        return bets.map((betData) {
          final bet = betData['bet'];
          final results = betData['results'];

          return BetResult(
            raceName: bet['race_name'] ?? '',
            date: bet['date'] ?? '',
            circuit: bet['circuit'] ?? '',
            hasSprint: bet['has_sprint'] ?? false,
            season: bet['season'] ?? '',
            round: bet['round'] ?? '',
            isComplete: bet['is_complete'] ?? false,
            polemanUser: bet['poleman'] ?? '',
            polemanReal: results?['comparison']?['poleman_real'],
            top10User: List<String>.from(bet['top10'] ?? []),
            top10Real: results?['comparison']?['top10_real'] != null
                ? List<String>.from(results['comparison']['top10_real'])
                : null,
            dnfUser: bet['dnf'] ?? '',
            dnfReal: results?['comparison']?['dnf_real'],
            fastestLapUser: bet['fastest_lap'] ?? '',
            fastestLapReal: results?['comparison']?['fastest_lap_real'],
            sprintTop10User: bet['sprint_top10'] != null
                ? List<String>.from(bet['sprint_top10'])
                : null,
            sprintTop10Real: results?['comparison']?['sprint_top10_real'] !=
                    null
                ? List<String>.from(results['comparison']['sprint_top10_real'])
                : null,
            points: results?['points']?['total'] ?? bet['points'] ?? 0,
            pointsBreakdown: results?['points']?['breakdown'] != null
                ? List<String>.from(results['points']['breakdown'])
                : [],
          );
        }).toList();
      } else {
        throw Exception('Error al obtener apuestas: ${response['error']}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // -------------------------------------------------
  // EJEMPLOS COMENTADOS (APUESTAS/TORNEOS) ...
  // -------------------------------------------------
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
        if (hasSprint) 'sprint_top10': sprintTop10,
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
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<Tournament>> getTournaments() async {
    try {
      final response = await _authenticatedRequest(
        tournamentsEndpoint,
        'GET',
      );

      if (response['success']) {
        final List<dynamic> jsonList = response['tournaments'];
        final tournaments = jsonList.map((json) {
          try {
            return Tournament.fromJson(json);
          } catch (e) {
            rethrow;
          }
        }).toList();

        return tournaments;
      } else {
        throw Exception('Error al obtener torneos: ${response['error']}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
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
      throw Exception('Error de conexión: $e');
    }
  }

  Future<bool> joinTournament(String inviteCode) async {
    try {
      final response = await _authenticatedRequest(
        '/tournaments/join/',
        'POST',
        body: {'inviteCode': inviteCode},
      );

      if (!response['success']) {
        throw Exception(response['error'] ?? 'Error al unirse al torneo');
      }
      return response['success'];
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await _storage;
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    _accessToken = null;
    _refreshToken = null;
    currentUser = null;
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _authenticatedRequest(
        profileEndpoint,
        'GET',
      );

      if (response['success']) {
        return {
          'success': true,
          'profile': response['profile'],
        };
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
        'error': 'Error de conexión: $e',
      };
    }
  }

  Future<String?> getCurrentUserId() async {
    try {
      final prefs = await _storage;
      final userId = prefs.getString('user_id');
      if (userId == null) {}
      return userId;
    } catch (e) {
      return null;
    }
  }
}
