import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tournament.dart';

class TournamentDetailsScreen extends StatelessWidget {
  final Tournament tournament;

  const TournamentDetailsScreen({Key? key, required this.tournament})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tournament.name),
      ),
      body: ListView(
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
                        '${tournament.userPosition}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${tournament.userPoints} pts',
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
                          tournament.inviteCode,
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
                              ClipboardData(text: tournament.inviteCode));
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
                        '${tournament.participants.length} participantes',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...tournament.participants
                      .asMap()
                      .entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: entry.value.userId ==
                                        tournament
                                            .participants[
                                                tournament.userPosition - 1]
                                            .userId
                                    ? Colors.red.withOpacity(0.2)
                                    : null,
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
                                        color: _getPositionColor(entry.key + 1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${entry.key + 1}',
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
                                        entry.value.username,
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    Text(
                                      '${entry.value.points} pts',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ],
              ),
            ),
          ),
        ],
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
