import 'package:flutter/material.dart';

class TournamentCard extends StatelessWidget {
  final String name;
  final String inviteCode;
  final int participantsCount;
  final int position;
  final int points;
  final VoidCallback onTap;

  const TournamentCard({
    Key? key,
    required this.name,
    required this.inviteCode,
    required this.participantsCount,
    required this.position,
    required this.points,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Posición: $position°',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '$points pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$participantsCount participantes',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
