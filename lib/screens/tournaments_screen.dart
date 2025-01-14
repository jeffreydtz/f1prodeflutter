import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/tournament.dart';
import '../widgets/tournament_card.dart';

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
    final data = await apiService.getTournaments();
    setState(() {
      tournaments = data;
      _loading = false;
    });
  }

  Future<void> _createTournament() async {
    if (_tournamentNameController.text.isEmpty) return;
    final newTournament =
        await apiService.createTournament(_tournamentNameController.text);
    setState(() {
      tournaments.add(newTournament);
    });
    _tournamentNameController.clear();
  }

  Future<void> _joinTournament() async {
    if (_inviteCodeController.text.isEmpty) return;
    final joined = await apiService.joinTournament(_inviteCodeController.text);
    if (joined) {
      // Se volvió a obtener la lista actualizada
      _fetchTournaments();
    }
    _inviteCodeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Torneos'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Crear Torneo
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
                  ElevatedButton(
                    onPressed: _createTournament,
                    child: const Text('Crear Torneo'),
                  ),
                  const Divider(
                      color: Colors.white54, thickness: 1, height: 30),
                  // Unirse a Torneo
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
                  ElevatedButton(
                    onPressed: _joinTournament,
                    child: const Text('Unirse a Torneo'),
                  ),
                  const SizedBox(height: 20),
                  // Lista de torneos
                  const Text(
                    'Mis Torneos',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  ...tournaments.map(
                    (t) => TournamentCard(
                      name: t.name,
                      inviteCode: t.inviteCode,
                      participantsCount: t.participants.length,
                      onTap: () {
                        // Aquí podrías mostrar la pantalla de detalles/ranking del torneo
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailsScreen(tournament: t)));
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
