import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';
import '../models/betresult.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/web_navbar.dart';
import '../widgets/f1_widgets.dart';

class ResultsScreen extends StatefulWidget {
  final String? initialRaceId;

  const ResultsScreen({Key? key, this.initialRaceId}) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  List<BetResult> _results = [];
  bool _isLoading = true;
  String? _expandedRaceId;
  late TabController _tabController;
  bool _hasError = false;
  String? _errorMessage;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchResults();
    _expandedRaceId = widget.initialRaceId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchResults() async {
    setState(() => _isLoading = true);
    try {
      final results = await apiService.getUserBetResults();
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveLayout.isWeb(context);

    return Scaffold(
      appBar: isWeb
          ? WebNavbar(
              title: 'Resultados',
              currentIndex: _selectedIndex,
              onRefresh: _fetchResults,
              showBackButton: Navigator.canPop(context),
              onBackPressed: () => Navigator.of(context).pop(),
            )
          : AppBar(
              title: const Text('Resultados'),
              leading: Navigator.canPop(context)
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : null,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchResults,
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'En curso'),
                  Tab(text: 'Completadas'),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: const Color.fromARGB(255, 255, 17, 0),
              ),
            ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 255, 17, 0),
              ),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? 'Error desconocido',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _fetchResults,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 255, 17, 0),
                        ),
                        child: const Text(
                          'Reintentar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : _results.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay predicciones disponibles',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : Column(
                      children: [
                        // Si es web, mostrar tabs manualmente ya que no están en AppBar
                        if (isWeb)
                          TabBar(
                            controller: _tabController,
                            tabs: const [
                              Tab(text: 'En curso'),
                              Tab(text: 'Completadas'),
                            ],
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white70,
                            indicatorColor:
                                const Color.fromARGB(255, 255, 17, 0),
                          ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildPredictionsList(
                                  false), // Predicciones en curso
                              _buildPredictionsList(
                                  true), // Predicciones completadas
                            ],
                          ),
                        ),
                      ],
                    ),
      bottomNavigationBar: !isWeb
          ? F1BottomNavigation(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
                switch (index) {
                  case 0:
                    Navigator.pushNamed(context, '/home');
                    break;
                  case 1:
                    // Ya estamos en results, no hacer nada
                    break;
                  case 2:
                    Navigator.pushNamed(context, '/tournaments');
                    break;
                  case 3:
                    Navigator.pushNamed(context, '/profile');
                    break;
                }
              },
              items: const [
                F1BottomNavItem(
                  icon: CupertinoIcons.house_fill,
                  label: 'Inicio',
                ),
                F1BottomNavItem(
                  icon: CupertinoIcons.list_bullet_below_rectangle,
                  label: 'Resultados',
                ),
                F1BottomNavItem(
                  icon: CupertinoIcons.person_3_fill,
                  label: 'Torneos',
                ),
                F1BottomNavItem(
                  icon: CupertinoIcons.person_fill,
                  label: 'Perfil',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildPredictionsList(bool showCompleted) {
    final currentUser = apiService.getCurrentUser();
    if (currentUser == null) {
      return const Center(
        child: Text(
          'No has iniciado sesión',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Filtrar los resultados según si están completados o no
    final filteredResults =
        _results.where((bet) => bet.isComplete == showCompleted).toList();

    if (filteredResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showCompleted
                  ? Icons.emoji_events_outlined
                  : Icons.pending_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              showCompleted
                  ? 'No hay predicciones completadas'
                  : 'No hay predicciones en curso',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchResults,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 17, 0),
              ),
              child: const Text(
                'Actualizar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredResults.length,
      itemBuilder: (context, index) {
        final betRes = filteredResults[index];
        return _buildBetResultCard(betRes);
      },
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
        const Center(
          child: Column(
            children: [
              Icon(
                Icons.timer_outlined,
                color: Colors.amber,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Carrera pendiente',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
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

        // Mostrar predicciones de sprint si la carrera tiene sprint
        if (bet.hasSprint &&
            bet.sprintTop10User != null &&
            bet.sprintTop10User!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionTitle('Sprint Race - Top 8'),
          const SizedBox(height: 8),
          _buildTop10List(bet.sprintTop10User!),
        ],
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
        _buildDnfComparison(
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

        // Mostrar resultados de sprint si la carrera tiene sprint
        if (bet.hasSprint &&
            bet.sprintTop10User != null &&
            bet.sprintTop10User!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionTitle('Sprint Race - Top 8'),
          const SizedBox(height: 8),
          if (bet.sprintTop10Real != null && bet.sprintTop10Real!.isNotEmpty)
            _buildTop10Comparison(bet.sprintTop10User!, bet.sprintTop10Real!)
          else
            _buildTop10List(bet.sprintTop10User!),
        ],

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

  Widget _buildDnfComparison({
    required String prediction,
    required String? result,
  }) {
    // Verificar si el piloto predicho está en la lista de DNFs reales
    bool isCorrect = false;
    if (result != null) {
      // Si el resultado es una lista (separada por comas), dividirla
      if (result.contains(',')) {
        final List<String> dnfList =
            result.split(',').map((e) => e.trim()).toList();
        isCorrect = dnfList.contains(prediction);
      } else {
        // Si es un solo piloto, comparar directamente
        isCorrect = prediction == result;
      }
    }

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
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTop10List(List<String> drivers) {
    return Column(
      children: List.generate(
        drivers.length,
        (index) => ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[800],
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            drivers[index],
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
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
