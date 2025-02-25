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

  /// Ajusta la URL base de tu backend Django.
  /// Usa "10.0.2.2" si corres la app en un emulador Android local.
  static const String baseUrl =
      'https://f1prodedjango-production.up.railway.app/api';

  /// Variable para almacenar el usuario logueado
  UserModel? currentUser;

  String? _accessToken;
  String? _refreshToken;

  // Token Storage Methods
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  Future<bool> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    return _accessToken != null;
  }

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    _accessToken = null;
    _refreshToken = null;
  }

  // Token Refresh
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access'];
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // -------------------------------------------------
  // 1. REGISTER (CREACIÓN DE USUARIO)
  // -------------------------------------------------
  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'password_confirm': password,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Usuario creado exitosamente',
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'errors': data['errors'] ?? {'detail': 'Error en el registro'},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'errors': {'detail': 'Error de conexión: $e'},
      };
    }
  }

  // -------------------------------------------------
  // 2. LOGIN
  // -------------------------------------------------
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        await _saveTokens(data['access'], data['refresh']);

        // Decodificar el token para obtener el user_id
        final decodedToken = JwtDecoder.decode(data['access']);
        final userId = decodedToken['user_id'].toString();

        // Guardar el user_id
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);

        return {
          'success': true,
          'message': 'Login exitoso',
        };
      } else {
        return {
          'success': false,
          'error': data['detail'] ?? 'Credenciales inválidas',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // -------------------------------------------------
  // 3. OBTENER CARRERAS
  // -------------------------------------------------
  /// Llama al endpoint en Django que devuelve las próximas carreras (JSON).
  Future<List<Race>> getRaces() async {
    try {
      final response = await _authenticatedRequest(
        'GET',
        '/f1/upcoming-races/',
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((raceJson) => Race.fromJson(raceJson)).toList();
      } else {
        throw Exception('Error al obtener carreras: ${response.statusCode}');
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
        'GET',
        '/f1/drivers/',
      );

      if (response.statusCode == 200) {
        // Decodificar la respuesta usando UTF-8
        final List<dynamic> driversList =
            jsonDecode(utf8.decode(response.bodyBytes));

        // Convertir cada elemento a String
        final List<String> pilotNames =
            driversList.map((driver) => driver.toString()).toList();

        return pilotNames;
      } else {
        throw Exception('Error al obtener drivers: ${response.statusCode}');
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
      final response = await _authenticatedRequest('GET', '/bets/');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> bets = data['bets'] ?? [];

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
        throw Exception('Error al obtener apuestas: ${response.statusCode}');
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
        'POST',
        '/bets/',
        body: requestBody,
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Error desconocido';
        throw Exception('Error al crear apuesta: $error');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<Tournament>> getTournaments() async {
    try {
      final response = await _authenticatedRequest(
        'GET',
        '/tournaments/',
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final tournaments = jsonList.map((json) {
          try {
            return Tournament.fromJson(json);
          } catch (e) {
            rethrow;
          }
        }).toList();

        return tournaments;
      } else {
        throw Exception('Error al obtener torneos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Tournament> createTournament(String name) async {
    try {
      final response = await _authenticatedRequest(
        'POST',
        '/tournaments/',
        body: {'name': name},
      );

      if (response.statusCode == 201) {
        return Tournament.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Error desconocido';
        throw Exception('Error al crear torneo: $error');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<bool> joinTournament(String inviteCode) async {
    try {
      final response = await _authenticatedRequest(
        'POST',
        '/tournaments/join/',
        body: {'inviteCode': inviteCode},
      );

      final data = jsonDecode(response.body);
      if (!data['success']) {
        throw Exception(data['error'] ?? 'Error al unirse al torneo');
      }
      return data['success'];
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    _accessToken = null;
    _refreshToken = null;
    currentUser = null;
  }

  // Authenticated Request Helper
  Future<http.Response> _authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    if (_accessToken == null) {
      await _loadTokens();
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_accessToken',
      'Accept': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers':
          'Origin, Content-Type, Accept, Authorization, X-Request-With',
    };

    late http.Response response;

    try {
      switch (method.toUpperCase()) {
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
        // Añade otros métodos según necesites
      }

      if (response.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          return _authenticatedRequest(method, endpoint, body: body);
        }
      }

      return response;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _authenticatedRequest(
        'GET',
        '/users/profile/',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'profile': data['profile'],
        };
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': false,
          'error': error['detail'] ?? 'Error al obtener el perfil',
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
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) {}
      return userId;
    } catch (e) {
      return null;
    }
  }
}
