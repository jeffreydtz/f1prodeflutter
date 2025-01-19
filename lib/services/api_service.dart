import 'dart:convert';
import 'package:http/http.dart' as http;

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

  UserModel? currentUser;

  /// LOGIN
  /// Ejemplo de método que envía email y password a un endpoint de login.
  /// Ajusta según tu lógica real en Django.
  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/users/login/');
    final body = {
      'email': email,
      'password': password,
    };

    try {
      final response = await http.post(url, body: body);
      if (response.statusCode == 200) {
        // Supongamos que el servidor devuelve algo así:
        // { "id": "user1", "username": "UsuarioF1", "email": "...", ... }
        final data = jsonDecode(response.body);
        currentUser = UserModel(
          id: data['id'],
          email: data['email'],
          username: data['username'],
          // Ojo: normalmente no devuelves el password. Ajusta a tu gusto.
          password: password,
        );
        return true;
      } else {
        // Manejo de error por status != 200
        return false;
      }
    } catch (e) {
      // Manejo de errores de conexión
      return false;
    }
  }

  /// OBTENER CARRERAS
  /// Llama al endpoint en Django que devuelve las próximas carreras (JSON).
  Future<List<Race>> getRaces() async {
    final url = Uri.parse('$baseUrl/f1/upcoming-races/');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // Decodificamos la respuesta
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);

        // Accedemos a la clave "MRData"
        final mrData = jsonBody['MRData'] as Map<String, dynamic>;

        // Dentro de MRData, accedemos a "RaceTable"
        final raceTable = mrData['RaceTable'] as Map<String, dynamic>;

        // Dentro de "RaceTable", accedemos a la lista "Races"
        final List<dynamic> racesList = raceTable['Races'];

        // Ahora sí mapeamos la lista de carreras a objetos Race
        return racesList.map((raceJson) => Race.fromJson(raceJson)).toList();
      } else {
        throw Exception('Error al obtener carreras: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  //Get drivers
  Future<List<String>> getDrivers() async {
    final url = Uri.parse('$baseUrl/f1/drivers/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // Decodifica la respuesta
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);

        // Accede a MRData -> DriverTable -> Drivers
        final mrData = jsonBody['MRData'] as Map<String, dynamic>;
        final driverTable = mrData['DriverTable'] as Map<String, dynamic>;
        final List<dynamic> driversList = driverTable['Drivers'];

        // Extraer el nombre con la lógica que quieras:
        // Ejemplo: "driverId" o "givenName familyName"
        // Devuelvo una lista de strings (pilotos)
        final List<String> pilotNames = driversList.map((driverJson) {
          final Map<String, dynamic> d = driverJson as Map<String, dynamic>;
          final givenName = d['givenName'] ?? '';
          final familyName = d['familyName'] ?? '';
          // Combino en un solo string, o uso el "driverId" si prefieres
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

  /// CREAR APUESTA
  /// Envía los datos de la apuesta a tu backend
  // Future<bool> createBet(Bet bet) async {
  //   final url = Uri.parse('$baseUrl/bets/');
  //   // Ajusta el body al formato que tu Django espera (probablemente JSON).
  //   final body = jsonEncode({
  //     'user': bet.userId,
  //     'season': bet.season,
  //     'round_number': bet.roundNumber,
  //     'predicted_winner': bet.predictedWinner,
  //     // otros campos...
  //   });

  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: body,
  //     );
  //     if (response.statusCode == 201 || response.statusCode == 200) {
  //       return true;
  //     } else {
  //       // Manejo de error si la creación no fue exitosa
  //       return false;
  //     }
  //   } catch (e) {
  //     throw Exception('Error al crear apuesta: $e');
  //   }
  // }

  /// OBTENER TORNEOS
  /// Llama a un endpoint para obtener la lista de torneos.
  // Future<List<Tournament>> getTournaments() async {
  //   final url = Uri.parse('$baseUrl/tournaments/');
  //   try {
  //     final response = await http.get(url);
  //     if (response.statusCode == 200) {
  //       final List<dynamic> data = jsonDecode(response.body);
  //       return data.map((item) => Tournament.fromJson(item)).toList();
  //     } else {
  //       throw Exception('Error al obtener torneos: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     throw Exception('Error de conexión: $e');
  //   }
  // }

  /// CREAR TORNEO
  // Future<Tournament> createTournament(String name) async {
  //   final url = Uri.parse('$baseUrl/tournaments/');
  //   final body = jsonEncode({
  //     'name': name,
  //     // si tu backend requiere algún otro campo, agrégalo acá
  //   });

  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: body,
  //     );
  //     if (response.statusCode == 201 || response.statusCode == 200) {
  //       final Map<String, dynamic> data = jsonDecode(response.body);
  //       return Tournament.fromJson(data);
  //     } else {
  //       throw Exception('Error al crear torneo: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     throw Exception('Error de conexión: $e');
  //   }
  // }

  /// UNIRSE A TORNEO
  // Future<bool> joinTournament(String code) async {
  //   final url = Uri.parse('$baseUrl/tournaments/join/');
  //   final body = jsonEncode({
  //     'invite_code': code,
  //     // posiblemente tu userID
  //     'user_id': currentUser?.id ?? 'user1',
  //   });

  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: body,
  //     );
  //     if (response.statusCode == 200) {
  //       return true;
  //     } else {
  //       return false;
  //     }
  //   } catch (e) {
  //     throw Exception('Error al unirse a torneo: $e');
  //   }
  // }
}
