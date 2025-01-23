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
  static const String baseUrl = 'http://127.0.0.1:8000/api';

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
        Uri.parse('$baseUrl/users/token/refresh/'),
        body: jsonEncode({'refresh': _refreshToken}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveTokens(data['access'], _refreshToken!);
        return true;
      }
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  // -------------------------------------------------
  // 1. REGISTER (CREACIÓN DE USUARIO)
  // -------------------------------------------------
  /// Envía username, email, password a /users/register/
  /// Retorna true si se creó el usuario (código 201), false si ocurrió error.
  Future<bool> register(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/users/register/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error en registro: $e');
      return false;
    }
  }

  // -------------------------------------------------
  // 2. LOGIN
  // -------------------------------------------------
  /// Ejemplo de método que envía email y password a un endpoint de login
  /// (POST /users/token/). Ajusta según tu lógica real en Django.
  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/users/token/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveTokens(data['access'], data['refresh']);

        // Decodificar el token para obtener el user_id
        final decodedToken = JwtDecoder.decode(data['access']);
        final userId = decodedToken['user_id'].toString();

        // Guardar el user_id
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);

        return true;
      }
      return false;
    } catch (e) {
      print('Error en login: $e');
      return false;
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
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((raceJson) => Race.fromJson(raceJson)).toList();
      } else {
        print('Error status: ${response.statusCode}');
        print('Error body: ${response.body}');
        throw Exception('Error al obtener carreras: ${response.statusCode}');
      }
    } catch (e) {
      print('Error detallado: $e');
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
        // Decodificar la respuesta como una lista de strings directamente
        final List<dynamic> driversList = jsonDecode(response.body);

        // Convertir cada elemento a String
        final List<String> pilotNames =
            driversList.map((driver) => driver.toString()).toList();

        return pilotNames;
      } else {
        print('Error status: ${response.statusCode}');
        print('Error body: ${response.body}');
        throw Exception('Error al obtener drivers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error detallado: $e');
      throw Exception('Error de conexión (drivers): $e');
    }
  }

  // -------------------------------------------------
  // 5. OBTENER RESULTADOS DE APUESTAS
  // -------------------------------------------------
  /// Llama a /bets/results/?user_id=... y devuelve una lista de BetResult
  Future<List<BetResult>> getUserBetResults(String userId) async {
    try {
      print('Fetching results for user: $userId');
      final response = await _authenticatedRequest(
        'GET',
        '/bets/results/?user_id=$userId',
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        final List<dynamic> results = jsonBody['results'];
        return results.map((item) => BetResult.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener resultados: ${response.statusCode}');
      }
    } catch (e) {
      print('Error detallado: $e');
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
    required String poleman,
    required List<String> top10,
    required String dnf,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      print('User ID: $userId');
      print('Sending bet to: /bets/');
      print('Request body: ${jsonEncode({
            'user': userId.toString(), // Convertir a String explícitamente
            'season': season,
            'round': round,
            'race_name': raceName,
            'date': date,
            'circuit': circuit,
            'poleman': poleman,
            'top10': top10,
            'dnf': dnf,
          })}');

      final response = await _authenticatedRequest(
        'POST',
        '/bets/',
        body: {
          'user': userId.toString(), // Convertir a String explícitamente
          'season': season,
          'round': round,
          'race_name': raceName,
          'date': date,
          'circuit': circuit,
          'poleman': poleman,
          'top10': top10,
          'dnf': dnf,
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return true;
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Error desconocido';
        throw Exception('Error al crear apuesta: $error');
      }
    } catch (e) {
      print('Error detallado: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<Tournament>> getTournaments() async {
    try {
      final response = await _authenticatedRequest(
        'GET',
        '/tournaments/',
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final tournaments = jsonList.map((json) {
          try {
            return Tournament.fromJson(json);
          } catch (e) {
            print('Error parsing tournament: $e');
            print('JSON data: $json');
            rethrow;
          }
        }).toList();

        print('Parsed tournaments: ${tournaments.length}');
        return tournaments;
      } else {
        throw Exception('Error al obtener torneos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getTournaments: $e');
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
    };

    late http.Response response;

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
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _authenticatedRequest(
        'GET',
        '/users/profile/',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener perfil: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) {
        print('No se encontró ID de usuario en SharedPreferences');
      }
      return userId;
    } catch (e) {
      print('Error al obtener ID de usuario: $e');
      return null;
    }
  }
}
