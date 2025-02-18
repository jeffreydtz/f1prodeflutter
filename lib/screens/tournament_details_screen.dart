import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tournament.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverallStandings(),
          _buildLatestRaceResults(),
        ],
      ),
    );
  }

  Widget _buildOverallStandings() {
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
                      '${widget.tournament.userPosition}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${widget.tournament.userPoints} pts',
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
                        Clipboard.setData(
                            ClipboardData(text: widget.tournament.inviteCode));
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
                      '${widget.tournament.participants.length} participantes',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...widget.tournament.participants.asMap().entries.map(
                    (entry) => _buildParticipantRow(entry.key, entry.value)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLatestRaceResults() {
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
                      widget.tournament.lastRace?.name ?? 'Sin carreras',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.tournament.lastRace?.date ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...widget.tournament.participants.asMap().entries.map(
                    (entry) => _buildLatestRaceRow(entry.key, entry.value)),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildLatestRaceRow(int index, Participant participant) {
    final bool isCurrentUser = participant.userId ==
        widget
            .tournament.participants[widget.tournament.userPosition - 1].userId;
    final lastRacePoints = participant.lastRacePoints ?? 0;

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
                '$lastRacePoints pts',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
