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

  Future<void> _fetchInitialData() async {
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

      // Una vez que tenemos tanto las carreras como las predicciones, cruzamos los datos
      _updateRacesWithBetInfo();

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  // Método para actualizar las carreras con la información de predicciones
  void _updateRacesWithBetInfo() {
    if (mounted) {
      setState(() {
        // Para cada carrera, verificamos si existe una predicción
        races = races.map((race) {
          bool hasBet = _checkExistingPrediction(race.season, race.round);
          // Solo actualizamos hasBet si es necesario
          if (race.hasBet != hasBet) {
            return race.copyWith(hasBet: hasBet);
          }
          return race;
        }).toList();
      });
    }
  }

  Future<void> _fetchRaces() async {
    try {
      final fetchedRaces = await apiService.getRaces();
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
      final results = await apiService.getUserBetResults();
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

  bool _checkExistingPrediction(String season, String round) {
    // Aquí el problema puede ser el tipo de datos. Asegurémonos de comparar strings
    bool result = betResults.any((bet) =>
        bet.season.toString() == season.toString() &&
        bet.round.toString() == round.toString());
    return result;
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
                    backgroundColor: F1Theme.f1Red.withOpacity(0.1),
                    foregroundColor: F1Theme.f1Red,
                  ),
                ),
                const SizedBox(width: F1Theme.s),
              ],
            ),
      body: _loading
          ? Center(
              child: F1LoadingIndicator(
                message: 'Cargando carreras...',
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
                    Navigator.pushReplacementNamed(context, '/home');
                    break;
                  case 1:
                    Navigator.pushReplacementNamed(context, '/results');
                    break;
                  case 2:
                    Navigator.pushReplacementNamed(context, '/tournaments');
                    break;
                  case 3:
                    Navigator.pushReplacementNamed(context, '/profile');
                    break;
                }
              },
              items: const [
                F1BottomNavItem(
                  icon: CupertinoIcons.home,
                  activeIcon: CupertinoIcons.house_fill,
                  label: 'Inicio',
                ),
                F1BottomNavItem(
                  icon: CupertinoIcons.list_bullet,
                  activeIcon: CupertinoIcons.list_bullet_below_rectangle,
                  label: 'Resultados',
                ),
                F1BottomNavItem(
                  icon: CupertinoIcons.group,
                  activeIcon: CupertinoIcons.group_solid,
                  label: 'Torneos',
                ),
                F1BottomNavItem(
                  icon: CupertinoIcons.person_circle,
                  activeIcon: CupertinoIcons.person_circle_fill,
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
        // Si ya hay apuesta, navegar a resultados en lugar de permitir otra
        if (race.hasBet) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsScreen(
                initialRaceId: '${race.season}_${race.round}',
              ),
            ),
          );
          return;
        }

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
          _fetchInitialData();
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
