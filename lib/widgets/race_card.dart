import 'package:flutter/material.dart';

class RaceCard extends StatelessWidget {
  final String raceName;
  final String date;
  final String circuit;
  final String season;
  final String round;
  final VoidCallback onBetPressed;
  final Function(String, String) onViewResults;
  final bool hasPrediction;
  final bool raceCompleted;

  const RaceCard({
    Key? key,
    required this.raceName,
    required this.date,
    required this.circuit,
    required this.season,
    required this.round,
    required this.onBetPressed,
    required this.onViewResults,
    this.hasPrediction = false,
    this.raceCompleted = false,
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
        trailing: (hasPrediction || raceCompleted)
            ? ElevatedButton(
                onPressed: () => onViewResults(season, round),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                child: const Text(
                  'Ver Resultados',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : ElevatedButton(
                onPressed: onBetPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 20, 3),
                ),
                child: const Text(
                  'Predecir',
                  style: TextStyle(color: Colors.white),
                ),
              ),
      ),
    );
  }
}
