import '../models/user.dart';
import '../models/race.dart';
import '../models/bet.dart';
import '../models/tournament.dart';

class ApiService {
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Aquí podrías manejar la URL base de tu API, tokens, etc.
  // Por ahora, usaremos datos MOCK para simular.

  // MOCK de carreras
  List<Race> mockRaces = [
    Race(
        id: '1',
        name: 'Gran Premio de Baréin',
        date: '2024-03-10',
        circuit: 'Circuito de Sakhir'),
    Race(
        id: '2',
        name: 'Gran Premio de Arabia Saudí',
        date: '2024-03-17',
        circuit: 'Jeddah Corniche Circuit'),
    Race(
        id: '3',
        name: 'Gran Premio de Australia',
        date: '2024-03-31',
        circuit: 'Albert Park'),
  ];

  // MOCK de torneos
  List<Tournament> mockTournaments = [
    Tournament(
      id: 't1',
      name: 'Torneo F1 Amigos',
      inviteCode: 'AMIGOS123',
      participants: ['user1', 'user2'],
    ),
  ];

  // MOCK de usuario logueado (simplificado)
  UserModel? currentUser;

  // Ejemplo de login
  Future<bool> login(String email, String password) async {
    // Simular un endpoint de login
    await Future.delayed(const Duration(seconds: 1));
    // Comprobación simplificada (cualquier pass, con el mail user@)
    if (email.isNotEmpty && password.isNotEmpty) {
      currentUser = UserModel(
        id: 'user1',
        email: email,
        username: 'UsuarioF1',
        password: password,
      );
      return true;
    }
    return false;
  }

  // Obtener carreras
  Future<List<Race>> getRaces() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return mockRaces;
  }

  // Crear apuesta
  Future<bool> createBet(Bet bet) async {
    // Llamada POST a tu backend
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // Obtener torneos
  Future<List<Tournament>> getTournaments() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return mockTournaments;
  }

  // Crear torneo
  Future<Tournament> createTournament(String name) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Generar código de invitación fake
    final newTournament = Tournament(
      id: 't${mockTournaments.length + 1}',
      name: name,
      inviteCode: 'INVITE${mockTournaments.length + 1}',
      participants: [currentUser?.id ?? 'user1'],
    );
    mockTournaments.add(newTournament);
    return newTournament;
  }

  // Unirse a torneo
  Future<bool> joinTournament(String code) async {
    await Future.delayed(const Duration(milliseconds: 500));
    for (var t in mockTournaments) {
      if (t.inviteCode == code) {
        t.participants.add(currentUser?.id ?? 'user1');
        return true;
      }
    }
    return false;
  }
}
