import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Datos mock de la última carrera
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Última Carrera',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Pole Position'),
            _buildItemWithDetail(
              title: lastPoleman,
              detail: 'Piloto que inició en la pole.',
              icon: Icons.flag,
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Top 10 Final'),
            ...lastTop10.asMap().entries.map((entry) {
              final index = entry.key;
              final pilot = entry.value;

              return ListTile(
                leading: index < 3
                    ? Icon(
                        index == 0
                            ? Icons.emoji_events
                            : index == 1
                                ? Icons.emoji_events
                                : Icons.emoji_events,
                        color: index == 0
                            ? Colors.amber
                            : index == 1
                                ? Colors.grey
                                : Colors.brown,
                        size: 30,
                      )
                    : CircleAvatar(
                        backgroundColor: Colors.grey[800],
                        child: Text(
                          (index + 1).toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                title: Text(
                  pilot,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            _buildSectionTitle('DNFs'),
            if (lastDnfs.isNotEmpty)
              ...lastDnfs.map(
                (pilot) => ListTile(
                  leading: const Icon(Icons.car_crash, color: Colors.red),
                  title: Text(
                    pilot,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              )
            else
              const Text(
                'Ningún piloto abandonó.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            const Divider(color: Colors.white54, thickness: 1, height: 30),
            _buildSectionTitle('Puntaje Obtenido'),
            Text(
              'Tus puntos en esta carrera: $userPoints',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 10),
            const Text(
              'Puntuacion:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '- Acierto en la pole: +10 puntos',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Text(
              '- Acertaste 5 posiciones en el Top 10: +15 puntos',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Text(
              '- Predicción correcta de DNF: +5 puntos',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildItemWithDetail(
      {required String title, required String detail, IconData? icon}) {
    return Row(
      children: [
        if (icon != null) Icon(icon, color: Colors.amber, size: 30),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              detail,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}
