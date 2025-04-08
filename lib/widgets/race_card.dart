import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/race.dart';

class RaceCard extends StatelessWidget {
  final Race race;
  final VoidCallback onPredict;
  final VoidCallback onViewResults;

  const RaceCard({
    Key? key,
    required this.race,
    required this.onPredict,
    required this.onViewResults,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final raceDate = DateTime.parse(race.date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color.fromARGB(255, 30, 30, 30),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              race.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Circuito: ${race.circuit}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Fecha: ${DateFormat('dd/MM/yyyy').format(raceDate)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: race.hasBet ? onViewResults : onPredict,
                style: ElevatedButton.styleFrom(
                  backgroundColor: race.hasBet
                      ? Colors.green
                      : const Color.fromARGB(255, 255, 17, 0),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  race.hasBet ? 'Ver Predicción' : 'Predecir',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
