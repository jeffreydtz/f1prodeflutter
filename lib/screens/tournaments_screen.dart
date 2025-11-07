import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';
import '../models/tournament.dart';
import '../widgets/tournament_card.dart';
import 'tournament_details_screen.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/web_navbar.dart';
import '../widgets/f1_widgets.dart';
import '../theme/f1_theme.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({Key? key}) : super(key: key);

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  final ApiService apiService = ApiService();
  List<Tournament> tournaments = [];
  bool isLoading = true;
  String? error;
  int _selectedIndex = 2; // Tournaments tab is selected

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
      if (mounted) {
        setState(() {
          tournaments = data
            ..sort((a, b) => b.userPoints.compareTo(a.userPoints));
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          error = e.toString();
        });
        F1Theme.showError(context, 'Error al cargar los torneos');
      }
    }
  }

  Future<void> _createTournament() async {
    if (_tournamentNameController.text.isEmpty) {
      F1Theme.showError(context, 'Ingresa un nombre para el torneo');
      return;
    }

    try {
      final response =
          await apiService.createTournament(_tournamentNameController.text);

      if (response['success'] == true && response['tournament'] != null) {
        final tournamentData = response['tournament'];
        final newTournament = Tournament.fromJson(tournamentData);

        if (mounted) {
          setState(() {
            tournaments.add(newTournament);
          });
        }
        _tournamentNameController.clear();
        F1Theme.showSuccess(context, 'Torneo creado exitosamente');
      }
    } catch (e) {
      F1Theme.showError(context, 'Error al crear el torneo');
    }
  }

  Future<void> _joinTournament() async {
    if (_inviteCodeController.text.isEmpty) {
      F1Theme.showError(context, 'Ingresa un código de invitación');
      return;
    }

    try {
      final response =
          await apiService.joinTournament(_inviteCodeController.text);

      if (response['success'] == true) {
        _fetchTournaments();
        _inviteCodeController.clear();
        F1Theme.showSuccess(context, 'Te has unido al torneo exitosamente');
      } else {
        F1Theme.showError(context, 'Error: ${response['error'] ?? 'No se pudo unir al torneo'}');
      }
    } catch (e) {
      F1Theme.showError(context, 'Error al unirse al torneo');
    }
  }

  void _showTournamentActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Qué deseas hacer?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.white),
              title: const Text('Crear un nuevo torneo',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showCreateTournamentDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add, color: Colors.white),
              title: const Text('Unirse a un torneo',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showJoinTournamentDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTournamentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Crear Nuevo Torneo',
            style: TextStyle(color: Colors.white)),
        content: TextField(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createTournament();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 17, 0),
            ),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showJoinTournamentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Unirse a un Torneo',
            style: TextStyle(color: Colors.white)),
        content: TextField(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _joinTournament();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 17, 0),
            ),
            child: const Text('Unirse'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveLayout.isWeb(context);

    return Scaffold(
      appBar: isWeb
          ? WebNavbar(
              title: 'Torneos',
              onRefresh: _fetchTournaments,
              showBackButton: Navigator.canPop(context),
              onBackPressed: () => Navigator.of(context).pop(),
              currentIndex: _selectedIndex,
            )
          : AppBar(
              title: const Text('Torneos'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchTournaments,
                ),
              ],
            ),
      body: _buildBody(),
      bottomNavigationBar: isWeb
          ? null
          : F1BottomNavigation(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
                switch (index) {
                  case 0:
                    Navigator.pushNamed(context, '/home');
                    break;
                  case 1:
                    Navigator.pushNamed(context, '/results');
                    break;
                  case 2:
                    // Ya estamos en torneos
                    break;
                  case 3:
                    Navigator.pushNamed(context, '/profile');
                    break;
                }
              },
              items: const [
                F1BottomNavItem(
                  icon: CupertinoIcons.house_fill,
                  label: 'Inicio',
                ),
                F1BottomNavItem(
                  icon: CupertinoIcons.list_bullet_below_rectangle,
                  label: 'Resultados',
                ),
                F1BottomNavItem(
                  icon: CupertinoIcons.person_3_fill,
                  label: 'Torneos',
                ),
                F1BottomNavItem(
                  icon: CupertinoIcons.person_fill,
                  label: 'Perfil',
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTournamentActionSheet(context),
        backgroundColor: const Color.fromARGB(255, 255, 17, 0),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 255, 17, 0),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTournaments,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return _buildTournamentsList();
  }

  Widget _buildTournamentsList() {
    final isWeb = ResponsiveLayout.isWeb(context);

    if (tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              color: Colors.grey,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay torneos disponibles',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchTournaments,
              child: const Text('Actualizar'),
            ),
          ],
        ),
      );
    }

    if (isWeb) {
      // Layout para web: rejilla de tarjetas
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 1.6,
          ),
          itemCount: tournaments.length,
          itemBuilder: (context, index) =>
              _buildTournamentCard(tournaments[index]),
        ),
      );
    } else {
      // Layout para móvil: lista vertical
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: tournaments.length,
          itemBuilder: (context, index) =>
              _buildTournamentCard(tournaments[index]),
        ),
      );
    }
  }

  Widget _buildTournamentCard(Tournament tournament) {
    return TournamentCard(
      name: tournament.name,
      inviteCode: tournament.inviteCode,
      participantsCount: tournament.participants.length,
      position: tournament.userPosition,
      points: tournament.userPoints,
      isCreator: tournament.isCreator,
      tournamentId: tournament.id,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TournamentDetailsScreen(
              tournament: tournament,
            ),
          ),
        ).then((_) => _fetchTournaments());
      },
    );
  }
}
