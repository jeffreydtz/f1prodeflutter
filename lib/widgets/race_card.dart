import 'package:flutter/material.dart';

class RaceCard extends StatelessWidget {
  final String raceName;
  final String date;
  final String circuit;
  final String season;
  final String round;
  final VoidCallback onBetPressed;

  const RaceCard({
    Key? key,
    required this.raceName,
    required this.date,
    required this.circuit,
    required this.season,
    required this.round,
    required this.onBetPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: ListTile(
        title: Text(
          raceName,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$date - $circuit',
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: ElevatedButton(
          onPressed: onBetPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 20, 3),
          ),
          child: const Text(
            'Apostar',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
