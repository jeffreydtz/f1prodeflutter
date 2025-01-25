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
    setState(() => _isLoading = true);
    try {
      final results = await apiService.getUserBetResults();
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar resultados: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchResults,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 255, 17, 0),
              ),
            )
          : _results.isEmpty
              ? const Center(
                  child: Text(
                    'No hay resultados disponibles',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final betRes = _results[index];
                    return _buildBetResultCard(betRes);
                  },
                ),
    );
  }

  Widget _buildBetResultCard(BetResult betRes) {
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
                        color: Color.fromARGB(255, 234, 198, 16),
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
              Text(
                betRes.dnfUser,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),

            const SizedBox(height: 12),

            // FASTEST LAP
            _buildSectionTitle('Tu Apuesta de Vuelta Rápida'),
            const SizedBox(height: 8),
            if (betRes.isComplete && betRes.fastestLapReal != null)
              _buildFastestLapComparison(
                  betRes.fastestLapUser, betRes.fastestLapReal!)
            else
              Text(
                betRes.fastestLapUser,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),

            if (betRes.isComplete) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white54, thickness: 1, height: 20),
              // PUNTOS
              _buildSectionTitle('Puntaje Obtenido'),
              Text(
                'Puntos en esta carrera: ${betRes.points ?? 0}',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Apostado:',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              ...userTop10.asMap().entries.map((entry) {
                final index = entry.key;
                final pilot = entry.value;
                final correct =
                    index < realTop10.length && pilot == realTop10[index];
                return Text(
                  '${index + 1}. $pilot',
                  style: TextStyle(
                    color: correct ? Colors.green : Colors.red,
                    fontSize: 16,
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Real:',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              ...realTop10.asMap().entries.map((entry) => Text(
                    '${entry.key + 1}. ${entry.value}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDnfComparison(String userDnf, String realDnf) {
    final correct = userDnf == realDnf;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Apostado:',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                userDnf,
                style: TextStyle(
                  color: correct ? Colors.green : Colors.red,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Real:',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                realDnf,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFastestLapComparison(
      String userFastestLap, String realFastestLap) {
    final correct = userFastestLap == realFastestLap;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Apostado:',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                userFastestLap,
                style: TextStyle(
                  color: correct ? Colors.green : Colors.red,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Real:',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                realFastestLap,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
