import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/tournament.dart';
import '../widgets/tournament_card.dart';
import 'tournament_details_screen.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({Key? key}) : super(key: key);

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  final ApiService apiService = ApiService();
  List<Tournament> tournaments = [];
  bool _loading = true;

  final TextEditingController _tournamentNameController =
      TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTournaments();
  }

  Future<void> _fetchTournaments() async {
    try {
      final data = await apiService.getTournaments();
      setState(() {
        tournaments = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cargar los torneos'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createTournament() async {
    if (_tournamentNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un nombre para el torneo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final newTournament =
          await apiService.createTournament(_tournamentNameController.text);
      setState(() {
        tournaments.add(newTournament);
      });
      _tournamentNameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Torneo creado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al crear el torneo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _joinTournament() async {
    if (_inviteCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un código de invitación'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final joined =
          await apiService.joinTournament(_inviteCodeController.text);
      if (joined) {
        _fetchTournaments();
        _inviteCodeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Te has unido al torneo exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al unirse al torneo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Torneos'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 255, 17, 1)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crear Torneo
                  const Text(
                    'Crear Nuevo Torneo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tournamentNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nombre del Torneo',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createTournament,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 17, 0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Crear Torneo'),
                    ),
                  ),

                  const Divider(
                      color: Colors.white54, thickness: 1, height: 30),

                  // Unirse a Torneo
                  const Text(
                    'Unirse a un Torneo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inviteCodeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Código de Invitación',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _joinTournament,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 17, 0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Unirse a Torneo'),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Lista de torneos
                  const Text(
                    'Mis Torneos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (tournaments.isEmpty)
                    const Center(
                      child: Text(
                        'No estás participando en ningún torneo',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  else
                    ...tournaments.map(
                      (t) => TournamentCard(
                        name: t.name,
                        inviteCode: t.inviteCode,
                        participantsCount: t.participants.length,
                        position: t.userPosition,
                        points: t.userPoints,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TournamentDetailsScreen(tournament: t),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
