import 'dart:convert';
import 'package:http/http.dart' as http;

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

  // -------------------------------------------------
  // 1. REGISTER (CREACIÓN DE USUARIO)
  // -------------------------------------------------
  /// Envía username, email, password a /users/register/
  /// Retorna true si se creó el usuario (código 201), false si ocurrió error.
  Future<bool> register(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/users/register/');
    final body = {
      'username': username,
      'email': email,
      'password': password,
    };

    try {
      final response = await http.post(url, body: body);

      if (response.statusCode == 201) {
        // Suponiendo que el backend crea el usuario y puede retornar algún mensaje
        // o incluso la info del nuevo user en JSON.
        // Si quieres, puedes parsear 'response.body' para guardarlo en 'currentUser'.
        // Por ahora, retornamos true al crearse con éxito:
        return true;
      } else {
        // Maneja error según la respuesta del servidor
        print('Error en registro: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception en register: $e');
      return false;
    }
  }

  // -------------------------------------------------
  // 2. LOGIN
  // -------------------------------------------------
  /// Ejemplo de método que envía email y password a un endpoint de login
  /// (POST /users/login/). Ajusta según tu lógica real en Django.
  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/users/login/');
    final body = {
      'email': email,
      'password': password,
    };

    try {
      final response = await http.post(url, body: body);
      if (response.statusCode == 200) {
        // Supongamos que el servidor devuelve algo tipo:
        // { "id": "user1", "username": "UsuarioF1", "email": "..." }
        final data = jsonDecode(response.body);

        currentUser = UserModel(
          id: data['id'],
          email: data['email'],
          username: data['username'],
          // Normalmente no devuelves password. Ajusta si lo necesitas.
          password: password,
        );
        return true;
      } else {
        // Manejo de error por status != 200
        print('Error en login: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception en login: $e');
      return false;
    }
  }

  // -------------------------------------------------
  // 3. OBTENER CARRERAS
  // -------------------------------------------------
  /// Llama al endpoint en Django que devuelve las próximas carreras (JSON).
  Future<List<Race>> getRaces() async {
    final url = Uri.parse('$baseUrl/f1/upcoming-races/');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        final mrData = jsonBody['MRData'] as Map<String, dynamic>;
        final raceTable = mrData['RaceTable'] as Map<String, dynamic>;
        final List<dynamic> racesList = raceTable['Races'];

        return racesList.map((raceJson) => Race.fromJson(raceJson)).toList();
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
    final url = Uri.parse('$baseUrl/f1/drivers/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        final mrData = jsonBody['MRData'] as Map<String, dynamic>;
        final driverTable = mrData['DriverTable'] as Map<String, dynamic>;
        final List<dynamic> driversList = driverTable['Drivers'];

        final List<String> pilotNames = driversList.map((driverJson) {
          final Map<String, dynamic> d = driverJson as Map<String, dynamic>;
          final givenName = d['givenName'] ?? '';
          final familyName = d['familyName'] ?? '';
          return '$givenName $familyName';
        }).toList();

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
  Future<List<BetResult>> getUserBetResults(String userId) async {
    final url = Uri.parse('$baseUrl/bets/results/?user_id=$userId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        final List<dynamic> results = jsonBody['results'];
        return results.map((item) => BetResult.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener resultados: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // -------------------------------------------------
  // EJEMPLOS COMENTADOS (APUESTAS/TORNEOS) ...
  // -------------------------------------------------
  // Future<bool> createBet(Bet bet) async { ... }
  // Future<List<Tournament>> getTournaments() async { ... }
  // Future<Tournament> createTournament(String name) async { ... }
  // Future<bool> joinTournament(String code) async { ... }
}
