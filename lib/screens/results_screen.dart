import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/betresult.dart';

class ResultsScreen extends StatefulWidget {
  final String? initialRaceId;

  const ResultsScreen({Key? key, this.initialRaceId}) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ApiService apiService = ApiService();
  List<BetResult> _results = [];
  bool _isLoading = true;
  String? _expandedRaceId;

  @override
  void initState() {
    super.initState();
    _fetchResults();
    _expandedRaceId = widget.initialRaceId;
  }

  Future<void> _fetchResults() async {
    setState(() => _isLoading = true);
    try {
      final results = await apiService.getUserBetResults();
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
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
        title: const Text('Predicciones'),
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
    final String raceId = '${betRes.season}_${betRes.round}';
    final bool isExpanded = _expandedRaceId == raceId;

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              betRes.raceName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (betRes.isComplete)
                  Text(
                    '${betRes.points} pts',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Pendiente',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _expandedRaceId = isExpanded ? null : raceId;
              });
            },
          ),
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white54),
                  Text(
                    'Fecha: ${betRes.date}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  betRes.isComplete
                      ? _buildCompletedRaceView(betRes)
                      : _buildPendingRaceView(betRes),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingRaceView(BetResult bet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              const Icon(
                Icons.timer_outlined,
                color: Colors.amber,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Carrera pendiente',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Los resultados estarán disponibles cuando finalice la carrera',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Tus Predicciones'),
        const SizedBox(height: 16),
        ListTile(
          title: const Text(
            'Pole Position',
            style: TextStyle(color: Colors.white70),
          ),
          subtitle: Text(
            bet.polemanUser,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        ListTile(
          title: const Text(
            'DNF',
            style: TextStyle(color: Colors.white70),
          ),
          subtitle: Text(
            bet.dnfUser,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        ListTile(
          title: const Text(
            'Vuelta Rápida',
            style: TextStyle(color: Colors.white70),
          ),
          subtitle: Text(
            bet.fastestLapUser,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        _buildSectionTitle('Tu Top 10'),
        const SizedBox(height: 8),
        _buildTop10List(bet.top10User),
      ],
    );
  }

  Widget _buildCompletedRaceView(BetResult bet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // POLE
        _buildSectionTitle('Pole Position'),
        _buildComparisonRow(
          prediction: bet.polemanUser,
          result: bet.polemanReal,
        ),
        const SizedBox(height: 16),

        // TOP 10
        _buildSectionTitle('Top 10'),
        const SizedBox(height: 8),
        if (bet.top10Real != null)
          _buildTop10Comparison(bet.top10User, bet.top10Real!)
        else
          _buildTop10List(bet.top10User),

        const SizedBox(height: 16),

        // DNF
        _buildSectionTitle('DNF'),
        _buildComparisonRow(
          prediction: bet.dnfUser,
          result: bet.dnfReal,
        ),
        const SizedBox(height: 16),

        // FASTEST LAP
        _buildSectionTitle('Vuelta Rápida'),
        _buildComparisonRow(
          prediction: bet.fastestLapUser,
          result: bet.fastestLapReal,
        ),

        if (bet.pointsBreakdown.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Divider(color: Colors.white54),
          _buildSectionTitle('Desglose de Puntos'),
          const SizedBox(height: 8),
          ...bet.pointsBreakdown.map((point) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  point,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildComparisonRow({
    required String prediction,
    required String? result,
  }) {
    final bool isCorrect = result != null && prediction == result;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu predicción:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  prediction,
                  style: TextStyle(
                    color: result != null
                        ? (isCorrect ? Colors.green : Colors.red)
                        : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (result != null) ...[
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resultado:',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    result,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
              const Text('Predecido:',
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
}
