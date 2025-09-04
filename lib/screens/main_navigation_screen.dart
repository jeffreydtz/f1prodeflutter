import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/web_navbar.dart';
import '../widgets/f1_widgets.dart';
import '../theme/f1_theme.dart';
import '../services/api_service.dart';
import '../models/race.dart';
import '../models/betresult.dart';
import '../models/tournament.dart';
import '../models/user.dart';
import '../widgets/race_card.dart';
import '../screens/bet_screen.dart';
import '../screens/results_screen.dart';
import '../screens/tournament_details_screen.dart';
import '../widgets/tournament_card.dart';
import '../widgets/skeleton_widgets.dart';
import '../utils/auth_guard.dart';

// Cache global para mejorar performance
class GlobalDataCache {
  static final GlobalDataCache _instance = GlobalDataCache._internal();
  factory GlobalDataCache() => _instance;
  GlobalDataCache._internal();

  List<Race>? _races;
  List<BetResult>? _betResults;
  List<Tournament>? _tournaments;
  UserModel? _currentUser;
  DateTime? _lastRacesUpdate;
  DateTime? _lastBetResultsUpdate;
  DateTime? _lastTournamentsUpdate;
  DateTime? _lastUserUpdate;

  // Cache validity: 2 minutes for races/bets, 5 minutes for tournaments/user
  static const Duration _shortCacheDuration = Duration(minutes: 2);
  static const Duration _longCacheDuration = Duration(minutes: 5);

  List<Race>? get races {
    if (_races == null || _lastRacesUpdate == null) return null;
    if (DateTime.now().difference(_lastRacesUpdate!) > _shortCacheDuration)
      return null;
    return _races;
  }

  set races(List<Race>? value) {
    _races = value;
    _lastRacesUpdate = DateTime.now();
  }

  List<BetResult>? get betResults {
    if (_betResults == null || _lastBetResultsUpdate == null) return null;
    if (DateTime.now().difference(_lastBetResultsUpdate!) > _shortCacheDuration)
      return null;
    return _betResults;
  }

  set betResults(List<BetResult>? value) {
    _betResults = value;
    _lastBetResultsUpdate = DateTime.now();
  }

  List<Tournament>? get tournaments {
    if (_tournaments == null || _lastTournamentsUpdate == null) return null;
    if (DateTime.now().difference(_lastTournamentsUpdate!) > _longCacheDuration)
      return null;
    return _tournaments;
  }

  set tournaments(List<Tournament>? value) {
    _tournaments = value;
    _lastTournamentsUpdate = DateTime.now();
  }

  UserModel? get currentUser {
    if (_currentUser == null || _lastUserUpdate == null) return null;
    if (DateTime.now().difference(_lastUserUpdate!) > _longCacheDuration)
      return null;
    return _currentUser;
  }

  set currentUser(UserModel? value) {
    _currentUser = value;
    _lastUserUpdate = DateTime.now();
  }

  void clearCache() {
    _races = null;
    _betResults = null;
    _tournaments = null;
    _currentUser = null;
    _lastRacesUpdate = null;
    _lastBetResultsUpdate = null;
    _lastTournamentsUpdate = null;
    _lastUserUpdate = null;
  }
}

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({Key? key, this.initialIndex = 0})
      : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  // GlobalKeys para acceder a los métodos de cada pantalla
  final GlobalKey<_HomeScreenState> _homeKey = GlobalKey<_HomeScreenState>();
  final GlobalKey<_ResultsScreenState> _resultsKey =
      GlobalKey<_ResultsScreenState>();
  final GlobalKey<_TournamentsScreenState> _tournamentsKey =
      GlobalKey<_TournamentsScreenState>();
  final GlobalKey<_ProfileScreenState> _profileKey =
      GlobalKey<_ProfileScreenState>();

  // Lista de pantallas que se mantienen en memoria
  late List<Widget> _screens;

  // Cache global de datos para mejorar performance
  final GlobalDataCache _dataCache = GlobalDataCache();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // Pre-cargar datos en paralelo para mejorar performance
    _preloadAllData();

    // Inicializar las pantallas una sola vez sin AppBar/BottomNav
    _screens = [
      HomeScreenContent(key: _homeKey),
      ResultsScreenContent(key: _resultsKey),
      TournamentsScreenContent(key: _tournamentsKey),
      ProfileScreenContent(key: _profileKey),
    ];
  }

  // Pre-carga paralela de todos los datos necesarios
  void _preloadAllData() {
    // No esperar - ejecutar en background para mejorar la experiencia de usuario
    Future.microtask(() async {
      final apiService = ApiService();

      try {
        // Cargar todos los datos en paralelo
        await Future.wait([
          _loadRacesData(apiService),
          _loadBetResultsData(apiService),
          _loadTournamentsData(apiService),
          _loadUserData(apiService),
        ], eagerError: false); // Continue even if some fail
      } catch (e) {
        debugPrint('[MainNav] Background data preload failed: $e');
      }
    });
  }

  Future<void> _loadRacesData(ApiService apiService) async {
    if (_dataCache.races == null) {
      try {
        final races = await apiService.getRaces();
        _dataCache.races = races;
        debugPrint('[MainNav] Races preloaded: ${races.length}');
      } catch (e) {
        debugPrint('[MainNav] Failed to preload races: $e');
      }
    }
  }

  Future<void> _loadBetResultsData(ApiService apiService) async {
    if (_dataCache.betResults == null) {
      try {
        final betResults = await apiService.getUserBetResults();
        _dataCache.betResults = betResults;
        debugPrint('[MainNav] Bet results preloaded: ${betResults.length}');
      } catch (e) {
        debugPrint('[MainNav] Failed to preload bet results: $e');
      }
    }
  }

  Future<void> _loadTournamentsData(ApiService apiService) async {
    if (_dataCache.tournaments == null) {
      try {
        final tournaments = await apiService.getTournaments();
        _dataCache.tournaments = tournaments;
        debugPrint('[MainNav] Tournaments preloaded: ${tournaments.length}');
      } catch (e) {
        debugPrint('[MainNav] Failed to preload tournaments: $e');
      }
    }
  }

  Future<void> _loadUserData(ApiService apiService) async {
    if (_dataCache.currentUser == null) {
      try {
        final user = apiService.getCurrentUser();
        _dataCache.currentUser = user;
        debugPrint('[MainNav] User data preloaded');
      } catch (e) {
        debugPrint('[MainNav] Failed to preload user data: $e');
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });

      // Navegación suave con animación de deslizamiento
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'F1 Prode';
      case 1:
        return 'Resultados';
      case 2:
        return 'Torneos';
      case 3:
        return 'Perfil';
      default:
        return 'F1 Prode';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveLayout.isWeb(context);

    return Scaffold(
      appBar: isWeb
          ? WebNavbar(
              title: _getTitle(),
              currentIndex: _currentIndex,
              onRefresh: _refreshCurrentScreen,
              showBackButton: false,
            )
          : AppBar(
              title: Text(_getTitle()),
              backgroundColor: F1Theme.carbonBlack,
              automaticallyImplyLeading: false, // No mostrar botón back
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _refreshCurrentScreen,
                  style: IconButton.styleFrom(
                    backgroundColor: F1Theme.f1Red.withValues(alpha: 0.1),
                    foregroundColor: F1Theme.f1Red,
                  ),
                ),
                const SizedBox(width: F1Theme.s),
              ],
            ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: !isWeb
          ? F1BottomNavigation(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
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

  void _refreshCurrentScreen() {
    // Llamar al método refresh de la pantalla actual
    switch (_currentIndex) {
      case 0:
        _homeKey.currentState?.refresh();
        break;
      case 1:
        _resultsKey.currentState?.refresh();
        break;
      case 2:
        _tournamentsKey.currentState?.refresh();
        break;
      case 3:
        _profileKey.currentState?.refresh();
        break;
    }
  }
}

// Widgets de contenido sin AppBar/BottomNav
class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({Key? key}) : super(key: key);

  @override
  State<HomeScreenContent> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreenContent> {
  late Widget _homeContent;

  @override
  void initState() {
    super.initState();
    _homeContent = const _HomeScreenBody();
  }

  void refresh() {
    // Force rebuild of the home content to trigger data refresh
    setState(() {
      _homeContent = const _HomeScreenBody();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _homeContent;
  }
}

class _HomeScreenBody extends StatefulWidget {
  const _HomeScreenBody();

  @override
  State<_HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<_HomeScreenBody> {
  final ApiService apiService = ApiService();
  final GlobalDataCache _cache = GlobalDataCache();
  List<Race> races = [];
  List<BetResult> betResults = [];
  bool _loading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInitialDataOptimized();
  }

    Future<void> _fetchInitialDataOptimized() async {
    if (!mounted) return;
    
    // Verificar autenticación antes de proceder
    final isAuthenticated = await AuthGuard.checkAndRedirect(context);
    if (!isAuthenticated) {
      return;
    }
    
    // Primero intentar cargar desde cache
    final cachedRaces = _cache.races;
    final cachedBetResults = _cache.betResults;
    
    if (cachedRaces != null && cachedBetResults != null) {
      // Carga instantánea desde cache
      setState(() {
        races = cachedRaces;
        betResults = cachedBetResults;
        _loading = false;
      });
      await _updateRacesWithBetInfo();
      debugPrint('[Home] Loaded from cache instantly');
      return;
    }
    
    // Si no hay cache, cargar normalmente
    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _fetchRaces(),
        _fetchBetResults(),
      ]);

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

        // Si es un error de autenticación, redirigir al login
        if (e.toString().contains('autenticación') ||
            e.toString().contains('inicia sesión')) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            }
          });
        }
      }
    }
  }

  Future<void> _fetchInitialData() async {
    await _fetchInitialDataOptimized();
  }

  Future<void> _updateRacesWithBetInfo() async {
    if (!mounted) return;

    final Set<String> existingBets =
        betResults.map((bet) => '${bet.season}_${bet.round}').toSet();
    List<Race> updatedRaces = [];

    for (Race race in races) {
      final raceKey = '${race.season}_${race.round}';
      bool hasBet = existingBets.contains(raceKey);

      if (race.hasBet != hasBet) {
        updatedRaces.add(race.copyWith(hasBet: hasBet));
      } else {
        updatedRaces.add(race);
      }
    }

    if (mounted) {
      setState(() {
        races = updatedRaces;
      });
    }
  }

  Future<void> _fetchRaces() async {
    try {
      // Primero intentar cache
      final cachedRaces = _cache.races;
      if (cachedRaces != null) {
        if (mounted) {
          setState(() {
            races = cachedRaces;
          });
        }
        return;
      }

      // Si no hay cache, hacer la petición
      final fetchedRaces = await apiService.getRaces();
      _cache.races = fetchedRaces; // Guardar en cache
      if (mounted) {
        setState(() {
          races = fetchedRaces;
        });
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
      // Primero intentar cache
      final cachedResults = _cache.betResults;
      if (cachedResults != null) {
        if (mounted) {
          setState(() {
            betResults = cachedResults;
          });
        }
        return;
      }

      // Si no hay cache, hacer la petición
      final results = await apiService.getUserBetResults();
      _cache.betResults = results; // Guardar en cache
      if (mounted) {
        setState(() {
          betResults = results;
        });
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

  Future<void> forceUpdateBetStatus() async {
    if (!mounted) return;
    await _fetchBetResults();
    await _updateRacesWithBetInfo();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      // Mostrar skeleton screens inmediatamente para mejor UX
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => const RaceCardSkeleton(),
      );
    }

    if (_hasError) {
      return F1ErrorState(
        title: 'Error al cargar',
        subtitle: _errorMessage ?? 'Error desconocido',
        actionText: 'Reintentar',
        onAction: _fetchInitialData,
      );
    }

    return _buildRacesList();
  }

  Widget _buildRacesList() {
    if (races.isEmpty) {
      return F1EmptyState(
        icon: Icons.sports_motorsports,
        title: 'No hay carreras disponibles',
        subtitle: 'Las carreras aparecerán aquí cuando estén disponibles',
        actionText: 'Actualizar',
        onAction: _fetchInitialData,
      );
    }

    return ResponsiveGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 3,
      childAspectRatio: ResponsiveLayout.isMobile(context) ? 0.8 : 1.1,
      children: races.map((race) => _buildRaceItem(race)).toList(),
    );
  }

  Widget _buildRaceItem(Race race) {
    return RaceCard(
      race: race,
      onPredict: () {
        Future<void>(() async {
          final initialRaceId = '${race.season}_${race.round}';

          if (race.hasBet) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ResultsScreen(initialRaceId: initialRaceId),
                ),
              );
            }
            return;
          }

          final alreadyHasBet = betResults.any((b) =>
              b.season.toString() == race.season.toString() &&
              b.round.toString() == race.round.toString());

          if (alreadyHasBet && mounted) {
            setState(() {
              races = races
                  .map((r) => (r.season == race.season && r.round == race.round)
                      ? r.copyWith(hasBet: true)
                      : r)
                  .toList();
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ResultsScreen(initialRaceId: initialRaceId),
              ),
            );
            return;
          }

          if (mounted) {
            Navigator.push(
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
            ).then((_) {
              if (mounted) {
                forceUpdateBetStatus();
              }
            });
          }
        });
      },
      onViewResults: () {
        if (race.hasBet) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsScreen(
                initialRaceId: '${race.season}_${race.round}',
              ),
            ),
          );
        }
      },
    );
  }
}

class ResultsScreenContent extends StatefulWidget {
  const ResultsScreenContent({Key? key}) : super(key: key);

  @override
  State<ResultsScreenContent> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreenContent> {
  void refresh() {
    // Implementar refresh de results
  }

  @override
  Widget build(BuildContext context) {
    return const _ResultsScreenBody();
  }
}

class _ResultsScreenBody extends StatefulWidget {
  const _ResultsScreenBody();

  @override
  State<_ResultsScreenBody> createState() => _ResultsScreenBodyState();
}

class _ResultsScreenBodyState extends State<_ResultsScreenBody>
    with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  final GlobalDataCache _cache = GlobalDataCache();
  List<BetResult> _results = [];
  bool _isLoading = true;
  String? _expandedRaceId;
  late TabController _tabController;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchResultsOptimized();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchResultsOptimized() async {
    if (!mounted) return;

    // Intentar cargar desde cache primero
    final cachedResults = _cache.betResults;
    if (cachedResults != null) {
      setState(() {
        _results = cachedResults;
        _isLoading = false;
        _hasError = false;
      });
      debugPrint('[Results] Loaded from cache instantly');
      return;
    }

    // Si no hay cache, cargar normalmente
    setState(() => _isLoading = true);
    try {
      final results = await apiService.getUserBetResults();
      _cache.betResults = results; // Guardar en cache
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

  Future<void> _fetchResults() async {
    await _fetchResultsOptimized();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Mostrar skeleton screens para resultados
      return Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'En curso'),
              Tab(text: 'Completadas'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: const Color.fromARGB(255, 255, 17, 0),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: 4,
              itemBuilder: (context, index) => const ResultCardSkeleton(),
            ),
          ),
        ],
      );
    }

    if (_hasError) {
      return Center(
        child: Text(
          'Error: $_errorMessage',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En curso'),
            Tab(text: 'Completadas'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color.fromARGB(255, 255, 17, 0),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildResultsList(false),
              _buildResultsList(true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsList(bool completed) {
    final filteredResults =
        _results.where((r) => r.isComplete == completed).toList();

    if (filteredResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              completed ? Icons.emoji_events : Icons.access_time,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              completed
                  ? 'Sin resultados completados'
                  : 'Sin apuestas en curso',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              completed
                  ? 'Los resultados aparecerán cuando las carreras terminen'
                  : 'Tus predicciones en curso aparecerán aquí',
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: filteredResults.length,
      itemBuilder: (context, index) {
        final result = filteredResults[index];
        final raceId = '${result.season}_${result.round}';
        final isExpanded = _expandedRaceId == raceId;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ExpansionTile(
            title: Text(result.raceName,
                style: const TextStyle(color: Colors.white)),
            subtitle: Text('${result.date} • ${result.circuit ?? 'Circuito'}',
                style: TextStyle(color: Colors.grey[400])),
            trailing: completed
                ? Text('${result.points} pts',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 17, 0),
                    ))
                : const Icon(Icons.pending, color: Colors.orange),
            initiallyExpanded: isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedRaceId = expanded ? raceId : null;
              });
            },
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (result.polemanUser.isNotEmpty) ...[
                      Text('Pole Position: ${result.polemanUser}',
                          style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 4),
                    ],
                    if (result.top10User.isNotEmpty) ...[
                      const Text('Top 10:',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(result.top10User.join(', '),
                          style: TextStyle(color: Colors.grey[300])),
                      const SizedBox(height: 8),
                    ],
                    if (result.dnfUser.isNotEmpty) ...[
                      const Text('DNF:',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(result.dnfUser,
                          style: TextStyle(color: Colors.grey[300])),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TournamentsScreenContent extends StatefulWidget {
  const TournamentsScreenContent({Key? key}) : super(key: key);

  @override
  State<TournamentsScreenContent> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreenContent> {
  void refresh() {
    // Implementar refresh de tournaments
  }

  @override
  Widget build(BuildContext context) {
    return const _TournamentsScreenBody();
  }
}

class _TournamentsScreenBody extends StatefulWidget {
  const _TournamentsScreenBody();

  @override
  State<_TournamentsScreenBody> createState() => _TournamentsScreenBodyState();
}

class _TournamentsScreenBodyState extends State<_TournamentsScreenBody> {
  final ApiService apiService = ApiService();
  final GlobalDataCache _cache = GlobalDataCache();
  List<Tournament> tournaments = [];
  bool isLoading = true;
  String? error;

  final TextEditingController _tournamentNameController =
      TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTournamentsOptimized();
  }

  Future<void> _fetchTournamentsOptimized() async {
    if (!mounted) return;

    // Intentar cargar desde cache primero
    final cachedTournaments = _cache.tournaments;
    if (cachedTournaments != null) {
      setState(() {
        tournaments = List.from(cachedTournaments)
          ..sort((a, b) => b.userPoints.compareTo(a.userPoints));
        isLoading = false;
        error = null;
      });
      debugPrint('[Tournaments] Loaded from cache instantly');
      return;
    }

    // Si no hay cache, cargar normalmente
    try {
      final data = await apiService.getTournaments();
      _cache.tournaments = data; // Guardar en cache
      if (mounted) {
        setState(() {
          tournaments = data
            ..sort((a, b) => b.userPoints.compareTo(a.userPoints));
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          error = e.toString();
        });
      }
    }
  }

  Future<void> _fetchTournaments() async {
    await _fetchTournamentsOptimized();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // Skeleton screens para torneos
      return Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: 3,
            itemBuilder: (context, index) => const TournamentCardSkeleton(),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _showTournamentActionSheet(context),
              backgroundColor: const Color.fromARGB(255, 255, 17, 0),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }

    if (error != null) {
      return Center(
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
              'Error: $error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTournaments,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        _buildTournamentsList(),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => _showTournamentActionSheet(context),
            backgroundColor: const Color.fromARGB(255, 255, 17, 0),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentsList() {
    if (tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              color: Colors.grey,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay torneos disponibles',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchTournaments,
              child: const Text('Actualizar'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: tournaments.length,
        itemBuilder: (context, index) =>
            _buildTournamentCard(tournaments[index]),
      ),
    );
  }

  Widget _buildTournamentCard(Tournament tournament) {
    return TournamentCard(
      name: tournament.name,
      inviteCode: tournament.inviteCode,
      participantsCount: tournament.participants.length,
      position: tournament.userPosition,
      points: tournament.userPoints,
      isCreator: tournament.isCreator,
      tournamentId: tournament.id,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TournamentDetailsScreen(
              tournament: tournament,
            ),
          ),
        ).then((_) => _fetchTournaments());
      },
    );
  }

  void _showTournamentActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Qué deseas hacer?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.white),
              title: const Text('Crear un nuevo torneo',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showCreateTournamentDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add, color: Colors.white),
              title: const Text('Unirse a un torneo',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showJoinTournamentDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTournamentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Crear Nuevo Torneo',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _tournamentNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Nombre del Torneo',
            labelStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createTournament();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 17, 0),
            ),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showJoinTournamentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Unirse a un Torneo',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _inviteCodeController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Código de Invitación',
            labelStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _joinTournament();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 17, 0),
            ),
            child: const Text('Unirse'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTournament() async {
    if (_tournamentNameController.text.isEmpty) return;

    try {
      final response =
          await apiService.createTournament(_tournamentNameController.text);
      if (response['success'] == true && response['tournament'] != null) {
        final tournamentData = response['tournament'];
        final newTournament = Tournament.fromJson(tournamentData);
        if (mounted) {
          setState(() {
            tournaments.add(newTournament);
          });
        }
        _tournamentNameController.clear();
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _joinTournament() async {
    if (_inviteCodeController.text.isEmpty) return;

    try {
      final response =
          await apiService.joinTournament(_inviteCodeController.text);
      if (response['success'] == true) {
        _fetchTournaments();
        _inviteCodeController.clear();
      }
    } catch (e) {
      // Handle error
    }
  }
}

class ProfileScreenContent extends StatefulWidget {
  const ProfileScreenContent({Key? key}) : super(key: key);

  @override
  State<ProfileScreenContent> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreenContent> {
  void refresh() {
    // Implementar refresh de profile
  }

  @override
  Widget build(BuildContext context) {
    return const _ProfileScreenBody();
  }
}

class _ProfileScreenBody extends StatefulWidget {
  const _ProfileScreenBody();

  @override
  State<_ProfileScreenBody> createState() => _ProfileScreenBodyState();
}

class _ProfileScreenBodyState extends State<_ProfileScreenBody> {
  final ApiService apiService = ApiService();
  final GlobalDataCache _cache = GlobalDataCache();
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfileOptimized();
  }

  Future<void> _loadUserProfileOptimized() async {
    if (!mounted) return;

    // Intentar cargar desde cache primero
    final cachedUser = _cache.currentUser;
    if (cachedUser != null) {
      setState(() {
        _currentUser = cachedUser;
        _isLoading = false;
        _hasError = false;
      });
      debugPrint('[Profile] Loaded from cache instantly');
      return;
    }

    // Si no hay cache, cargar normalmente
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final user = apiService.getCurrentUser();
      _cache.currentUser = user; // Guardar en cache
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
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

  Future<void> _loadUserProfile() async {
    await _loadUserProfileOptimized();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Skeleton screen para perfil
      return const ProfileSkeleton();
    }

    if (_hasError || _currentUser == null) {
      return Center(
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
              'Error: ${_errorMessage ?? 'No se pudo cargar el perfil'}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserProfile,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 60,
            backgroundImage: _currentUser!.avatar != null
                ? NetworkImage(_currentUser!.avatar!)
                : null,
            child: _currentUser!.avatar == null
                ? Text(
                    _currentUser!.username.isNotEmpty
                        ? _currentUser!.username[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(fontSize: 32),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser!.username,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (_currentUser!.email.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _currentUser!.email,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
          const SizedBox(height: 32),
          _buildProfileCard(
            context,
            'Estadísticas',
            [
              _buildStatRow('Carreras jugadas', '${_currentUser!.racesPlayed}'),
              _buildStatRow('Puntos totales', '${_currentUser!.points}'),
            ],
          ),
          const SizedBox(height: 16),
          _buildProfileCard(
            context,
            'Configuración',
            [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text('Editar Perfil',
                    style: TextStyle(color: Colors.white)),
                trailing:
                    const Icon(Icons.arrow_forward_ios, color: Colors.white54),
                onTap: () {
                  Navigator.pushNamed(context, '/edit-profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Cerrar Sesión',
                    style: TextStyle(color: Colors.red)),
                onTap: _handleLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
      BuildContext context, String title, List<Widget> children) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[300]),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await apiService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
