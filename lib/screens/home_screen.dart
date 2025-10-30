import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/race.dart';
import '../models/betresult.dart';
import '../widgets/race_card.dart';
import '../screens/bet_screen.dart';
import '../screens/results_screen.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/web_navbar.dart';
import '../theme/f1_theme.dart';
import '../widgets/f1_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  List<Race> races = [];
  List<BetResult> betResults = [];
  bool _loading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    // Cancel any ongoing operations or timers here if needed
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      debugPrint('[Home] Fetching initial data');
      await Future.wait([
        _fetchRaces(),
        _fetchBetResults(),
      ]);

      // Una vez que tenemos tanto las carreras como las predicciones, cruzamos los datos
      await _updateRacesWithBetInfo();

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // Método optimizado para actualizar las carreras con la información de predicciones
  Future<void> _updateRacesWithBetInfo() async {
    if (!mounted) return;

    debugPrint('[Home] Updating races with bet info');
    debugPrint('[Home] BetResults count: ${betResults.length}');

    // Crear un Set para búsqueda rápida de apuestas existentes
    final Set<String> existingBets =
        betResults.map((bet) => '${bet.season}_${bet.round}').toSet();

    // Crear una nueva lista de carreras con la información de apuestas actualizada
    List<Race> updatedRaces = [];

    for (Race race in races) {
      // Verificación local rápida usando Set.contains (O(1))
      final raceKey = '${race.season}_${race.round}';
      bool hasBet = existingBets.contains(raceKey);
      debugPrint(
          '[Home] Race ${race.name} (${race.season}-${race.round}): has bet = $hasBet');

      // Crear race actualizada si es necesario
      if (race.hasBet != hasBet) {
        debugPrint(
            '[Home] Updating race ${race.name}: hasBet ${race.hasBet} -> $hasBet');
        updatedRaces.add(race.copyWith(hasBet: hasBet));
      } else {
        updatedRaces.add(race);
      }
    }

    if (mounted) {
      setState(() {
        races = updatedRaces;
      });
      debugPrint(
          '[Home] Races updated. Bets found: ${updatedRaces.where((r) => r.hasBet).length}');
    }
  }

  Future<void> _fetchRaces() async {
    try {
      final fetchedRaces = await apiService.getRaces();
      if (mounted) {
        setState(() {
          races = fetchedRaces;
        });
        debugPrint('[Home] Races loaded: ${races.length}');
        if (races.isNotEmpty) {
          debugPrint(
              '[Home] First race: ${races.first.name} hasBet=${races.first.hasBet}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error al cargar las carreras: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _fetchBetResults() async {
    try {
      final results = await apiService.getUserBetResults();
      if (mounted) {
        setState(() {
          betResults = results;
        });
        debugPrint('[Home] User bet results loaded: ${betResults.length}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error al cargar las predicciones: ${e.toString()}';
        });
      }
    }
  }

  // Método para forzar la actualización del estado de apuestas
  Future<void> forceUpdateBetStatus() async {
    if (!mounted) return;

    debugPrint('[Home] Force updating bet status');
    await _fetchBetResults();
    await _updateRacesWithBetInfo();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveLayout.isWeb(context);

    Widget content;
    if (_loading) {
      content = KeyedSubtree(
        key: const ValueKey('home-loading'),
        child: Center(
          child: F1LoadingIndicator(
            message: 'Sincronizando el paddock...',
          ),
        ),
      );
    } else if (_hasError) {
      content = KeyedSubtree(
        key: const ValueKey('home-error'),
        child: F1ErrorState(
          title: 'Error al cargar',
          subtitle: _errorMessage ?? 'Error desconocido',
          actionText: 'Reintentar',
          onAction: _fetchInitialData,
        ),
      );
    } else {
      content = KeyedSubtree(
        key: const ValueKey('home-content'),
        child: _buildRacesList(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: isWeb
          ? WebNavbar(
              title: 'F1 Prode',
              currentIndex: _selectedIndex,
              onRefresh: _fetchInitialData,
              showBackButton: Navigator.canPop(context),
              onBackPressed: () => Navigator.of(context).pop(),
            )
          : _buildMobileAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        child: content,
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
                    break;
                  case 1:
                    Navigator.pushNamed(context, '/results');
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

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      titleSpacing: 0,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temporada ${DateTime.now().year}',
            style: F1Theme.labelSmall.copyWith(
              color: F1Theme.textGrey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'F1 Prode',
            style: F1Theme.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _fetchInitialData,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.06),
            foregroundColor: F1Theme.f1Red,
          ),
        ),
        const SizedBox(width: F1Theme.s),
      ],
    );
  }

  Widget _buildRacesList() {
    if (races.isEmpty) {
      return Center(
        child: F1EmptyState(
          icon: Icons.sports_motorsports,
          title: 'No hay carreras disponibles',
          subtitle: 'Las carreras aparecerán aquí cuando estén disponibles',
          actionText: 'Actualizar',
          onAction: _fetchInitialData,
        ),
      );
    }

    final isMobile = ResponsiveLayout.isMobile(context);
    final columns = _gridColumnCount(context);
    final aspectRatio = columns == 1
        ? 0.95
        : columns == 2
            ? 1.05
            : 1.12;

    final scrollView = CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            F1Theme.m,
            isMobile ? F1Theme.l : F1Theme.xl,
            F1Theme.m,
            F1Theme.l,
          ),
          sliver: SliverToBoxAdapter(
            child: _buildHeroHeader(),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            left: F1Theme.s,
            right: F1Theme.s,
            bottom: MediaQuery.of(context).padding.bottom + F1Theme.xl,
          ),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildRaceItem(races[index]),
              childCount: races.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: F1Theme.m,
              mainAxisSpacing: F1Theme.m,
              childAspectRatio: aspectRatio,
            ),
          ),
        ),
      ],
    );

    return isMobile
        ? RefreshIndicator(
            onRefresh: _fetchInitialData,
            color: F1Theme.f1Red,
            backgroundColor: Colors.black.withOpacity(0.6),
            edgeOffset: 80,
            child: scrollView,
          )
        : scrollView;
  }

  Widget _buildRaceItem(Race race) {
    return RaceCard(
      race: race,
      onPredict: () => _handleRaceSelection(race),
      onViewResults: () => _openResults(race),
    );
  }

  int _gridColumnCount(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) return 3;
    if (ResponsiveLayout.isTablet(context)) return 2;
    return 1;
  }

  Widget _buildHeroHeader() {
    final now = DateTime.now();
    Race? nextRace;
    DateTime? nextRaceDate;

    final upcomingRaces =
        races.where((race) => DateTime.parse(race.date).isAfter(now)).toList()
          ..sort(
            (a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)),
          );
    if (upcomingRaces.isNotEmpty) {
      nextRace = upcomingRaces.first;
      nextRaceDate = DateTime.parse(nextRace.date);
    }

    final totalRaces = races.length;
    final predictedCount = races.where((r) => r.hasBet).length;
    final upcomingCount = upcomingRaces.length;
    final completedCount = races.where((r) => r.completed).length;
    final completionPercent =
        totalRaces == 0 ? 0 : ((predictedCount / totalRaces) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nextRace != null ? 'Próxima parada' : 'Mantente listo',
          style: F1Theme.labelSmall.copyWith(
            color: F1Theme.textGrey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: F1Theme.xs),
        Text(
          nextRace?.name ?? 'Todas las carreras sincronizadas',
          style: F1Theme.displaySmall.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: F1Theme.m),
        F1Card(
          padding: const EdgeInsets.all(F1Theme.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (nextRace != null && nextRaceDate != null) ...[
                Text(
                  DateFormat('dd MMM yyyy').format(nextRaceDate),
                  style: F1Theme.labelSmall.copyWith(
                    color: F1Theme.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: F1Theme.xs),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: F1Theme.textGrey,
                    ),
                    const SizedBox(width: F1Theme.s),
                    Expanded(
                      child: Text(
                        nextRace.circuit,
                        style: F1Theme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: F1Theme.m),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(F1Theme.radiusM),
                        child: LinearProgressIndicator(
                          value: _countdownRatio(nextRaceDate),
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            F1Theme.telemetryTeal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: F1Theme.m),
                    F1SecondaryButton(
                      text: 'Predecir ahora',
                      icon: Icons.flash_on_rounded,
                      onPressed: () => _handleRaceSelection(nextRace!),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'No hay carreras próximamente',
                  style: F1Theme.bodyMedium.copyWith(
                    color: F1Theme.textGrey,
                  ),
                ),
                const SizedBox(height: F1Theme.s),
                Text(
                  'Cuando se confirme la próxima carrera, la verás aquí con acceso rápido para predecir.',
                  style: F1Theme.bodySmall.copyWith(
                    color: F1Theme.textGrey,
                  ),
                ),
              ],
              const SizedBox(height: F1Theme.l),
              _buildStatsRow(
                predictedCount: predictedCount,
                upcomingCount: upcomingCount,
                completedCount: completedCount,
                totalRaces: totalRaces,
                completionPercent: completionPercent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow({
    required int predictedCount,
    required int upcomingCount,
    required int completedCount,
    required int totalRaces,
    required int completionPercent,
  }) {
    return Wrap(
      spacing: F1Theme.m,
      runSpacing: F1Theme.m,
      children: [
        _buildStatTile(
          label: 'Predicciones realizadas',
          value: '$predictedCount',
          color: F1Theme.telemetryTeal,
          caption: '$completionPercent% de la temporada',
        ),
        _buildStatTile(
          label: 'Carreras por disputar',
          value: '$upcomingCount',
          color: F1Theme.f1Red,
          caption: upcomingCount > 0
              ? 'Próximas oportunidades para sumar puntos'
              : 'Prepárate para la próxima temporada',
        ),
        _buildStatTile(
          label: 'Carreras completadas',
          value: '$completedCount',
          color: F1Theme.championGold,
          caption: '$totalRaces en total',
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required Color color,
    String? caption,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.all(F1Theme.m),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(F1Theme.radiusL),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.18),
              color.withOpacity(0.06),
            ],
          ),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: F1Theme.labelSmall.copyWith(
                color: Colors.white.withOpacity(0.75),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: F1Theme.xs),
            Text(
              value,
              style: F1Theme.displaySmall.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: F1Theme.xs),
              Text(
                caption,
                style: F1Theme.labelSmall.copyWith(
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _countdownRatio(DateTime raceDate) {
    const totalWindow = Duration(days: 10);
    final diff = raceDate.difference(DateTime.now());
    if (diff.isNegative) return 1.0;
    final ratio = 1 - (diff.inSeconds / totalWindow.inSeconds);
    return ratio.clamp(0.0, 1.0);
  }

  void _handleRaceSelection(Race race) {
    Future<void>(() async {
      await _navigateToRace(race);
    });
  }

  Future<void> _navigateToRace(Race race) async {
    if (!mounted) return;
    final raceId = _raceIdentifier(race);

    if (race.hasBet) {
      await _openResultsById(raceId);
      return;
    }

    final alreadyHasBet = betResults.any(
      (b) =>
          b.season.toString() == race.season.toString() &&
          b.round.toString() == race.round.toString(),
    );

    if (alreadyHasBet) {
      if (mounted) {
        setState(() {
          races = races
              .map(
                (r) => (r.season == race.season && r.round == race.round)
                    ? r.copyWith(hasBet: true)
                    : r,
              )
              .toList();
        });
      }
      await _openResultsById(raceId);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BetScreen(
          raceName: race.name,
          date: race.date,
          circuit: race.circuit,
          season: race.season,
          round: race.round,
          hasSprint: race.hasSprint,
        ),
      ),
    );

    if (!mounted) return;
    await forceUpdateBetStatus();
  }

  Future<void> _openResults(Race race) async {
    await _openResultsById(_raceIdentifier(race));
  }

  Future<void> _openResultsById(String raceId) async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(initialRaceId: raceId),
      ),
    );
  }

  String _raceIdentifier(Race race) => '${race.season}_${race.round}';
}
