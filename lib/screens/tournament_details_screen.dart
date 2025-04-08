import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tournament.dart';
import '../models/betresult.dart';
import '../services/api_service.dart';
import 'tournament_race_screen.dart';

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
  bool _isLoadingBets = false;
  bool _isLoadingStandings = false;
  Map<String, dynamic> _tournamentStandings = {};
  List<dynamic> _races = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTournamentStandings();
    if (widget.tournament.lastRace != null) {
      _fetchLastRaceBets();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar la clasificación: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar las predicciones: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoadingBets = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tournament.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tabla General'),
            Tab(text: 'Última Carrera'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverallStandings(),
          _buildLatestRaceResults(),
          _buildRacesHistory(),
        ],
      ),
    );
  }

  Widget _buildOverallStandings() {
    if (_isLoadingStandings) {
      return const Center(child: CircularProgressIndicator());
    }

    // Usar los datos del nuevo endpoint si están disponibles, sino usar los datos del torneo
    final participants = _tournamentStandings.containsKey('participants') &&
            _tournamentStandings['participants'] is List
        ? (_tournamentStandings['participants'] as List)
            .map((p) => Participant.fromJson(p))
            .toList()
        : widget.tournament.participants;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tu posición actual
        Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Tu Posición Actual',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_tournamentStandings['user_position'] ?? widget.tournament.userPosition}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${_tournamentStandings['user_points'] ?? widget.tournament.userPoints} pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Código copiado al portapapeles'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Lista de participantes
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
                    (entry) => _buildParticipantRow(entry.key, entry.value)),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildParticipantRow(int index, Participant participant) {
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
                child: Text(
                  participant.username,
                  style: const TextStyle(color: Colors.white),
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
