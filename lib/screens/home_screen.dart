import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
    final Set<String> existingBets = betResults.map((bet) => '${bet.season}_${bet.round}').toSet();
    
    // Crear una nueva lista de carreras con la información de apuestas actualizada
    List<Race> updatedRaces = [];
    
    for (Race race in races) {
      // Verificación local rápida usando Set.contains (O(1))
      final raceKey = '${race.season}_${race.round}';
      bool hasBet = existingBets.contains(raceKey);
      debugPrint('[Home] Race ${race.name} (${race.season}-${race.round}): has bet = $hasBet');
      
      // Crear race actualizada si es necesario
      if (race.hasBet != hasBet) {
        debugPrint('[Home] Updating race ${race.name}: hasBet ${race.hasBet} -> $hasBet');
        updatedRaces.add(race.copyWith(hasBet: hasBet));
      } else {
        updatedRaces.add(race);
      }
    }
    
    if (mounted) {
      setState(() {
        races = updatedRaces;
      });
      debugPrint('[Home] Races updated. Bets found: ${updatedRaces.where((r) => r.hasBet).length}');
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

    return Scaffold(
      appBar: isWeb
          ? WebNavbar(
              title: 'F1 Prode',
              currentIndex: _selectedIndex,
              onRefresh: _fetchInitialData,
              showBackButton: Navigator.canPop(context),
              onBackPressed: () => Navigator.of(context).pop(),
            )
          : AppBar(
              title: const Text('F1 Prode'),
              backgroundColor: F1Theme.carbonBlack,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _fetchInitialData,
                  style: IconButton.styleFrom(
                    backgroundColor: F1Theme.f1Red.withValues(alpha: 0.1),
                    foregroundColor: F1Theme.f1Red,
                  ),
                ),
                const SizedBox(width: F1Theme.s),
              ],
            ),
      body: _loading
          ? Center(
              child: F1LoadingIndicator(
                message: 'Cargando temporada 2025...',
              ),
            )
          : _hasError
              ? F1ErrorState(
                  title: 'Error al cargar',
                  subtitle: _errorMessage ?? 'Error desconocido',
                  actionText: 'Reintentar',
                  onAction: _fetchInitialData,
                )
              : _buildRacesList(),
      bottomNavigationBar: !isWeb
          ? F1BottomNavigation(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
                switch (index) {
                  case 0:
                    // Ya estamos en home, no hacer nada
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
        // Doble validación: flag local y verificación al vuelo desde el backend
        Future<void>(() async {
          final initialRaceId = '${race.season}_${race.round}';
          
          // Primera verificación: estado local
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

          // Segunda verificación: verificar localmente en betResults cargados
          final alreadyHasBet = betResults.any((b) =>
              b.season.toString() == race.season.toString() &&
              b.round.toString() == race.round.toString());
          
          if (alreadyHasBet && mounted) {
            // Actualizar estado local para reflejar los datos
            setState(() {
              races = races
                  .map((r) =>
                      (r.season == race.season && r.round == race.round)
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

          // Si no hay apuesta, permitir crearla
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
                // Forzar actualización completa para sincronizar el estado
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
