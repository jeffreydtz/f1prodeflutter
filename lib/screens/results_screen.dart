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

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    try {
      // Suponiendo que conoces el userId
      final userId = 'user1';
      final fetchedResults = await apiService.getUserBetResults(userId);
      setState(() {
        _results = fetchedResults;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching results: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const Center(
                  child: Text('No hay resultados',
                      style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final betRes = _results[index];
                    return _buildResultItem(betRes);
                  },
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
            Text(
              betRes.raceName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Fecha: ${betRes.date}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Divider(color: Colors.white54, thickness: 1, height: 20),

            // POLE
            _buildSectionTitle('Pole Position'),
            _buildItemWithDetail(
              title: 'Apostado: ${betRes.polemanUser}',
              detail: 'Real: ${betRes.polemanReal}',
              icon: Icons.flag,
            ),
            const SizedBox(height: 12),

            // TOP 10
            _buildSectionTitle('Top 10 Final'),
            const SizedBox(height: 8),
            _buildTop10Comparison(betRes.top10User, betRes.top10Real),

            const SizedBox(height: 12),

            // DNF
            _buildSectionTitle('DNFs'),
            const SizedBox(height: 8),
            _buildDnfComparison(betRes.dnfUser, betRes.dnfReal),

            const SizedBox(height: 12),
            const Divider(color: Colors.white54, thickness: 1, height: 20),

            // PUNTOS
            _buildSectionTitle('Puntaje Obtenido'),
            Text(
              'Puntos en esta carrera: ${betRes.points}',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 10),

            // Detalle de puntuación
            if (betRes.pointsBreakdown.isNotEmpty) ...[
              const Text(
                'Desglose de puntos:',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              ...betRes.pointsBreakdown.map((line) => Text(
                    '- $line',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ))
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

  Widget _buildItemWithDetail(
      {required String title, required String detail, IconData? icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) Icon(icon, color: Colors.amber, size: 30),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                detail,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        )
      ],
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
