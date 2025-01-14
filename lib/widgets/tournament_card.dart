import 'package:flutter/material.dart';

class TournamentCard extends StatelessWidget {
  final String name;
  final String inviteCode;
  final int participantsCount;
  final VoidCallback onTap;

  const TournamentCard({
    Key? key,
    required this.name,
    required this.inviteCode,
    required this.participantsCount,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: ListTile(
        onTap: onTap,
        title: Text(
          name,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Código: $inviteCode',
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: Text(
          '$participantsCount participantes',
          style: const TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}
