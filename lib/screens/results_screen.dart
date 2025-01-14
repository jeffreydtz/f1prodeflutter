import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Aquí podrías obtener la info real de los resultados
    // y los puntos del usuario desde tu backend.
    // Para simplificar, se muestran datos mock.
    final String lastPoleman = 'Verstappen';
    final List<String> lastTop10 = [
      'Verstappen',
      'Hamilton',
      'Leclerc',
      'Russell',
      'Sainz',
      'Perez',
      'Alonso',
      'Norris',
      'Gasly',
      'Ocon',
    ];
    final List<String> lastDnfs = ['Stroll', 'Magnussen'];
    final int userPoints = 25;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Última Carrera',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 20),
            Text(
              'Pole: $lastPoleman',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text('Top 10:',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            ...lastTop10.map(
              (pilot) => Text(
                pilot,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            const Text('DNFs:',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            Text(
              lastDnfs.join(', '),
              style: const TextStyle(color: Colors.white),
            ),
            const Divider(color: Colors.white54, thickness: 1, height: 30),
            Text(
              'Tus puntos en esta carrera: $userPoints',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            // Aquí podrías mostrar la tabla de posiciones general, etc.
          ],
        ),
      ),
    );
  }
}
