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
import 'dart:convert';

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
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchInitialData,
                ),
              ],
            ),
      body: _loading
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
                        onPressed: _fetchInitialData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 255, 17, 0),
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _buildRacesList(),
      bottomNavigationBar: !isWeb
          ? BottomNavigationBar(
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
              type: BottomNavigationBarType.fixed,
              backgroundColor: const Color.fromARGB(255, 30, 30, 30),
              selectedItemColor: const Color.fromARGB(255, 255, 17, 0),
              unselectedItemColor: Colors.white70,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Inicio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt),
                  label: 'Resultados',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Torneos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildRacesList() {
    final isWeb = ResponsiveLayout.isWeb(context);

    if (isWeb) {
      return GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.8,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
        ),
        itemCount: races.length,
        itemBuilder: (context, index) => _buildRaceItem(index),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: races.length,
        itemBuilder: (context, index) => _buildRaceItem(index),
      );
    }
  }

  Widget _buildRaceItem(int index) {
    final race = races[index];

    return RaceCard(
      race: race,
      onPredict: () {
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
