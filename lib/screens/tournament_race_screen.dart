import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../services/api_service.dart';

class TournamentRaceScreen extends StatefulWidget {
  final int tournamentId;
  final int season;
  final int round;
  final String raceName;

  const TournamentRaceScreen({
    Key? key,
    required this.tournamentId,
    required this.season,
    required this.round,
    required this.raceName,
  }) : super(key: key);

  @override
  State<TournamentRaceScreen> createState() => _TournamentRaceScreenState();
}

class _TournamentRaceScreenState extends State<TournamentRaceScreen> {
  final ApiService apiService = ApiService();
  TournamentRace? raceData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchRacePredictions();
  }

  Future<void> _fetchRacePredictions() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await apiService.getTournamentRacePredictions(
        widget.tournamentId,
        widget.season,
        widget.round,
      );

      if (response.containsKey('race')) {
        setState(() {
          raceData = TournamentRace.fromJson(response['race']);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'No se encontraron datos para esta carrera';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error al cargar datos: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.raceName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRacePredictions,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchRacePredictions,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _buildRaceContent(),
    );
  }

  Widget _buildRaceContent() {
    if (raceData == null) {
      return const Center(
        child: Text(
          'No hay datos disponibles para esta carrera',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRaceHeader(),
            const SizedBox(height: 24),
            // Si la carrera está completada o todos han predicho, mostramos todas las predicciones
            if (raceData!.isCompleted || _haveAllPredicted())
              _buildAllPredictions()
            else
              _buildPredictionStatus(),
            // Si hay resultados, los mostramos
            if (raceData!.isCompleted && raceData!.results != null)
              _buildRaceResults(),
          ],
        ),
      ),
    );
  }

  bool _haveAllPredicted() {
    if (raceData == null) return false;
    return !raceData!.predictions.any((pred) => !pred.hasPredicted);
  }

  Widget _buildRaceHeader() {
    return Card(
      color: Colors.grey[900],
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
                    raceData!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
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
                    color: raceData!.isCompleted
                        ? Colors.green
                        : const Color.fromARGB(255, 255, 17, 0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    raceData!.isCompleted ? 'Completada' : 'Próxima',
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
              raceData!.circuit,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              raceData!.date,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionStatus() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado de Predicciones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Las predicciones se mostrarán cuando todos hayan participado o cuando la carrera haya finalizado.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ...raceData!.predictions
                .map((pred) => _buildPredictionStatusRow(pred)),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionStatusRow(RacePrediction prediction) {
    // Buscar si hay predicción del usuario actual
    final isCurrentUser =
        prediction.userId == int.parse(apiService.currentUser?.id ?? '0');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (prediction.avatar != null && prediction.avatar!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                prediction.avatar!,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const CircleAvatar(
                  radius: 15,
                  child: Icon(Icons.person, size: 20),
                ),
              ),
            )
          else
            const CircleAvatar(
              radius: 15,
              child: Icon(Icons.person, size: 20),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              prediction.username,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: prediction.hasPredicted ? Colors.green : Colors.grey[700],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              prediction.hasPredicted ? 'Predicción realizada' : 'Pendiente',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllPredictions() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Predicciones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...raceData!.predictions
                .map((pred) => _buildFullPredictionCard(pred)),
          ],
        ),
      ),
    );
  }

  Widget _buildFullPredictionCard(RacePrediction prediction) {
    // Encontrar si es el usuario actual
    final isCurrentUser =
        prediction.userId == int.parse(apiService.currentUser?.id ?? '0');

    if (!prediction.hasPredicted || prediction.prediction == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          leading: prediction.avatar != null && prediction.avatar!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    prediction.avatar!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const CircleAvatar(
                      radius: 20,
                      child: Icon(Icons.person, size: 24),
                    ),
                  ),
                )
              : const CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.person, size: 24),
                ),
          title: Text(
            prediction.username,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: const Text(
            'No realizó predicción',
            style: TextStyle(color: Colors.white70),
          ),
          tileColor: Colors.grey[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    // Si hay predicción, mostrarla
    final predictionData = prediction.prediction!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        collapsedBackgroundColor: Colors.grey[800],
        backgroundColor: Colors.grey[800],
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        leading: prediction.avatar != null && prediction.avatar!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  prediction.avatar!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const CircleAvatar(
                    radius: 20,
                    child: Icon(Icons.person, size: 24),
                  ),
                ),
              )
            : const CircleAvatar(
                radius: 20,
                child: Icon(Icons.person, size: 24),
              ),
        title: Text(
          prediction.username,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          'Puntos: ${predictionData['points'] ?? '0'}',
          style: const TextStyle(color: Colors.white70),
        ),
        children: [
          if (predictionData.containsKey('poleman') &&
              predictionData['poleman'] != null)
            ListTile(
              title: const Text('Pole Position',
                  style: TextStyle(color: Colors.white70)),
              subtitle: Text(
                predictionData['poleman'],
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          if (predictionData.containsKey('top10') &&
              predictionData['top10'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child:
                      Text('Top 10', style: TextStyle(color: Colors.white70)),
                ),
                ...List.generate(
                  (predictionData['top10'] as List).length,
                  (index) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color.fromARGB(255, 255, 17, 0),
                      child: Text('${index + 1}'),
                    ),
                    title: Text(
                      predictionData['top10'][index],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          if (predictionData.containsKey('dnfs') &&
              predictionData['dnfs'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Text('No Finalizarán',
                      style: TextStyle(color: Colors.white70)),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (predictionData['dnfs'] as List)
                      .map((driver) => Chip(
                            label: Text(driver),
                            backgroundColor: Colors.grey[700],
                            labelStyle: const TextStyle(color: Colors.white),
                          ))
                      .toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRaceResults() {
    final results = raceData!.results!;

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(top: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resultados Oficiales',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (results.containsKey('poleman') && results['poleman'] != null)
              ListTile(
                title: const Text('Pole Position',
                    style: TextStyle(color: Colors.white70)),
                subtitle: Text(
                  results['poleman'],
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            if (results.containsKey('top10') && results['top10'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child:
                        Text('Top 10', style: TextStyle(color: Colors.white70)),
                  ),
                  ...List.generate(
                    (results['top10'] as List).length,
                    (index) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color.fromARGB(255, 255, 17, 0),
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        results['top10'][index],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            if (results.containsKey('dnfs') && results['dnfs'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: Text('No Finalizaron',
                        style: TextStyle(color: Colors.white70)),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (results['dnfs'] as List)
                        .map((driver) => Chip(
                              label: Text(driver),
                              backgroundColor: Colors.grey[700],
                              labelStyle: const TextStyle(color: Colors.white),
                            ))
                        .toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
