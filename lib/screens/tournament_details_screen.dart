import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tournament.dart';
import '../models/betresult.dart';
import '../models/sanction.dart';
import '../services/api_service.dart';
import 'tournament_race_screen.dart';
import '../theme/f1_theme.dart';

class TournamentDetailsScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentDetailsScreen({Key? key, required this.tournament})
      : super(key: key);

  @override
  State<TournamentDetailsScreen> createState() =>
      _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService apiService = ApiService();
  List<BetResult> _lastRaceBets = [];
  List<Sanction> _sanctions = [];
  bool _isLoadingBets = false;
  bool _isLoadingStandings = false;
  bool _isLoadingSanctions = false;
  Map<String, dynamic> _tournamentStandings = {};
  List<dynamic> _races = [];

  // Controladores para el formulario de sanciones
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: widget.tournament.isCreator ? 4 : 3, vsync: this);
    _fetchTournamentStandings();
    if (widget.tournament.lastRace != null) {
      _fetchLastRaceBets();
    }
    if (widget.tournament.isCreator) {
      _fetchTournamentSanctions();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _pointsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchTournamentStandings() async {
    setState(() => _isLoadingStandings = true);
    try {
      final data =
          await apiService.getTournamentStandings(widget.tournament.id);
      if (mounted) {
        setState(() {
          _tournamentStandings = data;
          if (data.containsKey('races') && data['races'] is List) {
            _races = data['races'];
          }
          _isLoadingStandings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        F1Theme.showError(context, 'Error al cargar la clasificación: ${e.toString()}');
      }
      setState(() => _isLoadingStandings = false);
    }
  }

  Future<void> _fetchLastRaceBets() async {
    setState(() => _isLoadingBets = true);
    try {
      final bets =
          await apiService.getTournamentLastRaceBets(widget.tournament.id);
      if (mounted) {
        setState(() {
          _lastRaceBets = bets;
          _isLoadingBets = false;
        });
      }
    } catch (e) {
      if (mounted) {
        F1Theme.showError(context, 'Error al cargar las predicciones: ${e.toString()}');
      }
      setState(() => _isLoadingBets = false);
    }
  }

  Future<void> _fetchTournamentSanctions() async {
    setState(() => _isLoadingSanctions = true);
    try {
      final sanctions =
          await apiService.getTournamentSanctions(widget.tournament.id);
      if (mounted) {
        setState(() {
          _sanctions = sanctions;
          _isLoadingSanctions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        F1Theme.showError(context, 'Error al cargar las sanciones: ${e.toString()}');
      }
      setState(() => _isLoadingSanctions = false);
    }
  }

  Future<void> _applyTournamentSanction() async {
    // Validar que todos los campos estén completos
    if (_usernameController.text.isEmpty ||
        _pointsController.text.isEmpty ||
        _reasonController.text.isEmpty) {
      F1Theme.showError(context, 'Todos los campos son obligatorios');
      return;
    }

    // Validar que los puntos sean un número válido
    int? points = int.tryParse(_pointsController.text);
    if (points == null || points <= 0) {
      F1Theme.showError(context, 'Los puntos deben ser un número positivo');
      return;
    }

    try {
      final result = await apiService.applyTournamentSanction(
        widget.tournament.id,
        _usernameController.text,
        points,
        _reasonController.text,
      );

      if (result['success'] == true) {
        // Limpiar el formulario
        _usernameController.clear();
        _pointsController.clear();
        _reasonController.clear();

        // Actualizar la lista de sanciones y la clasificación
        _fetchTournamentSanctions();
        _fetchTournamentStandings();

        F1Theme.showSuccess(context, 'Sanción aplicada correctamente');
      } else {
        F1Theme.showError(context, 'Error al aplicar la sanción: ${result['error']}');
      }
    } catch (e) {
      F1Theme.showError(context, 'Error al aplicar la sanción: ${e.toString()}');
    }
  }

  Future<void> _deleteTournamentSanction(int sanctionId) async {
    try {
      final result = await apiService.deleteTournamentSanction(
        widget.tournament.id,
        sanctionId,
      );

      if (result) {
        // Actualizar la lista de sanciones y la clasificación
        _fetchTournamentSanctions();
        _fetchTournamentStandings();

        F1Theme.showSuccess(context, 'Sanción eliminada correctamente');
      } else {
        F1Theme.showError(context, 'Error al eliminar la sanción');
      }
    } catch (e) {
      F1Theme.showError(context, 'Error al eliminar la sanción: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tournament.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Tabla General'),
            const Tab(text: 'Última Carrera'),
            const Tab(text: 'Historial'),
            if (widget.tournament.isCreator) const Tab(text: 'Sanciones'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverallStandings(),
          _buildLatestRaceResults(),
          _buildRacesHistory(),
          if (widget.tournament.isCreator) _buildSanctionsTab(),
        ],
      ),
    );
  }

  Widget _buildOverallStandings() {
    if (_isLoadingStandings) {
      return const Center(child: CircularProgressIndicator());
    }

    // Usar los datos del nuevo endpoint si están disponibles, sino usar los datos del torneo
    var participants = _tournamentStandings.containsKey('participants') &&
            _tournamentStandings['participants'] is List
        ? (_tournamentStandings['participants'] as List)
            .map((p) => Participant.fromJson(p))
            .toList()
        : widget.tournament.participants;

    // Ordenar participantes por puntos (de mayor a menor)
    participants = List.from(participants)
      ..sort((a, b) => b.points.compareTo(a.points));

    // Obtener el ApiService para conseguir el usuario actual
    final apiService = ApiService();
    final currentUser = apiService.getCurrentUser();

    // Buscar la posición del usuario actual en la lista ordenada
    int userPosition = 0;
    int userPoints = 0;

    if (currentUser != null) {
      // Buscar al usuario actual por su username
      for (int i = 0; i < participants.length; i++) {
        if (participants[i].username == currentUser.username) {
          userPosition = i + 1;
          userPoints = participants[i].points;
          break;
        }
      }
    }

    // Si no encontramos al usuario por username, usar el método anterior como respaldo
    if (userPosition == 0) {
      // Determinar el ID del usuario actual
      final userIdToFind = widget.tournament.participants.isNotEmpty
          ? widget.tournament.participants[widget.tournament.userPosition - 1]
              .userId
          : -1;

      // Encontrar la posición real del usuario en la lista ordenada
      for (int i = 0; i < participants.length; i++) {
        if (participants[i].userId == userIdToFind) {
          userPosition = i + 1;
          userPoints = participants[i].points;
          break;
        }
      }
    }

    // Si todavía no encontramos al usuario, mostrar mensaje de debug
    if (userPosition == 0 && participants.isNotEmpty) {
      debugPrint(
          '⚠️ No se pudo encontrar al usuario actual en la lista de participantes');
      debugPrint('Username: ${currentUser?.username}');
      debugPrint(
          'Participantes disponibles: ${participants.map((p) => p.username).join(', ')}');

      // Como último recurso, usar la primera posición
      userPosition = 1;
      userPoints = participants.first.points;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tu posición actual - Versión mejorada
        Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: const Color.fromARGB(255, 255, 17, 0).withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                const Text(
                  'Tu Posición Actual',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getPositionColor(userPosition),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$userPosition°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tus Puntos',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$userPoints',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (participants.isNotEmpty &&
                    userPosition > 0 &&
                    userPosition <= participants.length) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),

                  // Información sobre la diferencia de puntos con el líder o el siguiente
                  _buildPointsDifference(
                      participants, userPosition, userPoints),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Código de invitación
        Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Código de Invitación',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _tournamentStandings['invitation_code'] ??
                            widget.tournament.inviteCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                            text: _tournamentStandings['invitation_code'] ??
                                widget.tournament.inviteCode));
                        F1Theme.showSuccess(context, 'Código copiado al portapapeles');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Lista de participantes ordenada
        Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tabla de Posiciones',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${participants.length} participantes',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...participants.asMap().entries.map(
                      (entry) => _buildParticipantRow(
                        entry.key,
                        entry.value,
                        currentUser != null &&
                            participants[entry.key].username ==
                                currentUser.username,
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Método para construir la información sobre la diferencia de puntos
  Widget _buildPointsDifference(
      List<Participant> participants, int userPosition, int userPoints) {
    if (participants.isEmpty) return const SizedBox.shrink();

    String message = '';
    int difference = 0;
    Color messageColor = Colors.white70;

    // Si el usuario no es el primero, muestra diferencia con el líder
    if (userPosition > 1) {
      final leaderPoints = participants.isNotEmpty ? participants[0].points : 0;
      difference = leaderPoints - userPoints;
      message = 'A $difference puntos del líder';
      messageColor = Colors.orange;

      // También muestra cuántos puntos faltan para avanzar una posición
      if (userPosition > 1 && userPosition <= participants.length) {
        final aheadPosition =
            userPosition - 2; // Índice de la posición anterior
        if (aheadPosition >= 0 && aheadPosition < participants.length) {
          final aheadPoints = participants[aheadPosition].points;
          final pointsToAdvance = aheadPoints - userPoints;
          if (pointsToAdvance > 0) {
            message += ' • Necesitas $pointsToAdvance puntos para avanzar';
          }
        }
      }
    } else {
      // Si el usuario es el primero, muestra ventaja sobre el segundo
      if (participants.length > 1) {
        final secondPoints = participants[1].points;
        difference = userPoints - secondPoints;
        message = '$difference puntos de ventaja sobre el segundo';
        messageColor = Colors.green;
      }
    }

    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: messageColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildLatestRaceResults() {
    if (widget.tournament.lastRace == null) {
      return const Center(
        child: Text(
          'No hay carreras registradas en este torneo',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.tournament.lastRace!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.tournament.lastRace!.date,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoadingBets)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 255, 17, 0),
                    ),
                  )
                else if (_lastRaceBets.isEmpty)
                  const Center(
                    child: Text(
                      'No hay predicciones disponibles para esta carrera',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  ...widget.tournament.participants.asMap().entries.map(
                        (entry) => _buildParticipantPrediction(
                          entry.key,
                          entry.value,
                          _lastRaceBets.firstWhere(
                            (bet) =>
                                bet.userId == entry.value.userId.toString(),
                            orElse: () => BetResult(
                              raceName: '',
                              date: '',
                              circuit: '',
                              hasSprint: false,
                              season: '',
                              round: '',
                              isComplete: false,
                              userId: entry.value.userId.toString(),
                              polemanUser: '',
                              top10User: [],
                              dnfUser: '',
                              fastestLapUser: '',
                              points: 0,
                              pointsBreakdown: [],
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRacesHistory() {
    if (_isLoadingStandings) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_races.isEmpty) {
      return const Center(
        child: Text(
          'No hay carreras registradas en este torneo',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _races.length,
      itemBuilder: (context, index) {
        final race = _races[index];
        final bool isCompleted = race['is_completed'] ?? false;

        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TournamentRaceScreen(
                    tournamentId: widget.tournament.id,
                    season: race['season'] ?? 2025,
                    round: race['round'] ?? 1,
                    raceName: race['name'] ?? 'Carrera',
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          race['name'] ?? 'Carrera',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green
                              : const Color.fromARGB(255, 255, 17, 0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isCompleted ? 'Completada' : 'Próxima',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    race['circuit'] ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    race['date'] ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (isCompleted && race.containsKey('user_points'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Text(
                            'Tus puntos: ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '${race['user_points'] ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSanctionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Formulario para aplicar sanciones
        Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aplicar Nueva Sanción',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: F1Theme.mediumGrey,
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pointsController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Puntos a descontar',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: F1Theme.mediumGrey,
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: F1Theme.mediumGrey,
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyTournamentSanction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'APLICAR SANCIÓN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Lista de sanciones aplicadas
        Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sanciones Aplicadas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoadingSanctions)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Colors.red,
                    ),
                  )
                else if (_sanctions.isEmpty)
                  const Center(
                    child: Text(
                      'No hay sanciones aplicadas',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sanctions.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: Colors.white24,
                    ),
                    itemBuilder: (context, index) {
                      final sanction = _sanctions[index];
                      return ListTile(
                        title: Text(
                          sanction.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Puntos: -${sanction.points}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Motivo: ${sanction.reason}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Fecha: ${sanction.createdAt}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteConfirmation(sanction),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(Sanction sanction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Eliminar Sanción',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro que deseas eliminar la sanción aplicada a ${sanction.username}? Se revertirán los puntos descontados.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTournamentSanction(sanction.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantRow(
      int index, Participant participant, bool isCurrentUser) {
    // Verificar si el participante tiene sanciones
    final bool hasSanctions =
        participant.sanctions != null && participant.sanctions!.count > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.red.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getPositionColor(index + 1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          participant.username,
                          style: const TextStyle(color: Colors.white),
                        ),
                        if (hasSanctions)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Tooltip(
                              message:
                                  'Penalización: -${participant.sanctions!.totalPoints} puntos',
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (hasSanctions)
                      Text(
                        'Sanciones: ${participant.sanctions!.count} (-${participant.sanctions!.totalPoints} pts)',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Text(
                '${participant.points} pts',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantPrediction(
    int index,
    Participant participant,
    BetResult bet,
  ) {
    final bool isCurrentUser = participant.userId ==
        widget
            .tournament.participants[widget.tournament.userPosition - 1].userId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.red.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ExpansionTile(
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getPositionColor(index + 1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  participant.username,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              Text(
                '${participant.lastRacePoints ?? 0} pts',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          children: [
            if (bet.raceName.isNotEmpty) ...[
              ListTile(
                title: const Text(
                  'Pole Position',
                  style: TextStyle(color: Colors.white70),
                ),
                subtitle: Text(
                  bet.polemanUser,
                  style: TextStyle(
                    color: bet.polemanReal != null
                        ? (bet.polemanUser == bet.polemanReal
                            ? Colors.green
                            : Colors.red)
                        : Colors.white,
                  ),
                ),
                trailing: bet.polemanReal != null
                    ? Text(
                        bet.polemanReal!,
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const Divider(color: Colors.white24),
              ListTile(
                title: const Text(
                  'Top 10',
                  style: TextStyle(color: Colors.white70),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: bet.top10User.asMap().entries.map((entry) {
                    final index = entry.key;
                    final pilot = entry.value;
                    final isCorrect = bet.top10Real != null &&
                        index < bet.top10Real!.length &&
                        pilot == bet.top10Real![index];
                    return Text(
                      '${index + 1}. $pilot',
                      style: TextStyle(
                        color: bet.top10Real != null
                            ? (isCorrect ? Colors.green : Colors.red)
                            : Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(color: Colors.white24),
              ListTile(
                title: const Text(
                  'DNF',
                  style: TextStyle(color: Colors.white70),
                ),
                subtitle: Text(
                  bet.dnfUser,
                  style: TextStyle(
                    color: bet.dnfReal != null
                        ? (bet.dnfUser == bet.dnfReal
                            ? Colors.green
                            : Colors.red)
                        : Colors.white,
                  ),
                ),
                trailing: bet.dnfReal != null
                    ? Text(
                        bet.dnfReal!,
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const Divider(color: Colors.white24),
              ListTile(
                title: const Text(
                  'Vuelta Rápida',
                  style: TextStyle(color: Colors.white70),
                ),
                subtitle: Text(
                  bet.fastestLapUser,
                  style: TextStyle(
                    color: bet.fastestLapReal != null
                        ? (bet.fastestLapUser == bet.fastestLapReal
                            ? Colors.green
                            : Colors.red)
                        : Colors.white,
                  ),
                ),
                trailing: bet.fastestLapReal != null
                    ? Text(
                        bet.fastestLapReal!,
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
            ] else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No hay predicción para esta carrera',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown;
      default:
        return Colors.grey[700]!;
    }
  }
}
