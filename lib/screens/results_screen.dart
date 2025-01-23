import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/betresult.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({Key? key}) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ApiService apiService = ApiService();
  List<BetResult> _results = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userId = await apiService.getCurrentUserId();
      if (userId == null) throw Exception('Usuario no autenticado');
      final fetchedResults = await apiService.getUserBetResults(userId);

      if (mounted) {
        setState(() {
          _results = fetchedResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 255, 17, 0),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis Resultados'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchResults,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Resultados'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _results.length,
        itemBuilder: (context, index) => _buildResultItem(_results[index]),
      ),
    );
  }

  Widget _buildResultItem(BetResult betRes) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    betRes.raceName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!betRes.isComplete)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Pendiente',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Fecha: ${betRes.date}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Divider(color: Colors.white54, thickness: 1, height: 20),

            // POLE
            _buildSectionTitle('Tu Apuesta de Pole Position'),
            Text(
              betRes.polemanUser,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (betRes.isComplete && betRes.polemanReal != null) ...[
              const SizedBox(height: 4),
              Text(
                'Resultado: ${betRes.polemanReal}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 12),

            // TOP 10
            _buildSectionTitle('Tu Apuesta del Top 10'),
            const SizedBox(height: 8),
            if (betRes.isComplete && betRes.top10Real != null)
              _buildTop10Comparison(betRes.top10User, betRes.top10Real!)
            else
              _buildTop10List(betRes.top10User),

            const SizedBox(height: 12),

            // DNF
            _buildSectionTitle('Tu Apuesta de DNFs'),
            const SizedBox(height: 8),
            if (betRes.isComplete && betRes.dnfReal != null)
              _buildDnfComparison(betRes.dnfUser, betRes.dnfReal!)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: betRes.dnfUser
                    .map((pilot) => Text(
                          pilot,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ))
                    .toList(),
              ),

            if (betRes.isComplete) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white54, thickness: 1, height: 20),
              // PUNTOS
              _buildSectionTitle('Puntaje Obtenido'),
              Text(
                'Puntos en esta carrera: ${betRes.points ?? 0}',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              if (betRes.pointsBreakdown.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Desglose de puntos:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...betRes.pointsBreakdown.map((line) => Text(
                      '- $line',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    )),
              ],
            ],
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
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTop10List(List<String> top10) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: top10.asMap().entries.map((entry) {
        final index = entry.key;
        final pilot = entry.value;
        return Text(
          '${index + 1}. $pilot',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        );
      }).toList(),
    );
  }

  Widget _buildTop10Comparison(List<String> userTop10, List<String> realTop10) {
    // Ejemplo: una columna con 2 secciones: "Tu predicción" vs "Resultado final".
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Predicción
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Apostado:',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              ...userTop10.asMap().entries.map((entry) {
                final index = entry.key;
                final pilot = entry.value;
                return Text(
                  '${index + 1}. $pilot',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                );
              }),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Resultado real
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Real:',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              ...realTop10.asMap().entries.map((entry) {
                final index = entry.key;
                final pilot = entry.value;
                return Text(
                  '${index + 1}. $pilot',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDnfComparison(List<String> userDnf, List<String> realDnf) {
    if (realDnf.isEmpty && userDnf.isEmpty) {
      return const Text('No hubo DNFs',
          style: TextStyle(color: Colors.white, fontSize: 16));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Apostado
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Apostado:',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              userDnf.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: userDnf
                          .map((pilot) => Text(pilot,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16)))
                          .toList(),
                    )
                  : const Text('Ningún DNF apostado',
                      style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Real
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Real:',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              realDnf.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: realDnf
                          .map((pilot) => Text(pilot,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16)))
                          .toList(),
                    )
                  : const Text('Nadie abandonó',
                      style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ],
    );
  }
}
