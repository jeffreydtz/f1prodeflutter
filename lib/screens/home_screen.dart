import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';
import '../models/race.dart';
import '../models/betresult.dart';
import '../widgets/race_card.dart';
import '../screens/bet_screen.dart';
import '../screens/results_screen.dart';
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
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      // Hacer ambas llamadas en paralelo
      final results = await Future.wait([
        apiService.getRaces(),
        apiService.getUserBetResults(),
      ]);

      if (mounted) {
        setState(() {
          races = results[0] as List<Race>;
          betResults = results[1] as List<BetResult>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color.fromARGB(255, 255, 17, 0),
          ),
        );
      }
    }
  }

  bool _checkExistingPrediction(String season, String round) {
    return betResults
        .any((result) => result.season == season && result.round == round);
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text('Carreras $currentYear'),
        automaticallyImplyLeading: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        iconTheme: const IconThemeData(
          color: Colors.white, // Esto asegura que los iconos sean blancos
          size: 28, // Y que tengan un tamaño adecuado
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 255, 17, 0)))
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: races.length,
              itemBuilder: (context, index) {
                final race = races[index];
                final hasPrediction =
                    _checkExistingPrediction(race.season, race.round);
                final raceDate = DateTime.parse(race.date);
                final raceCompleted = raceDate.isBefore(DateTime.now());

                return RaceCard(
                  raceName: race.name,
                  date: race.date,
                  circuit: race.circuit,
                  season: race.season,
                  round: race.round,
                  hasPrediction: hasPrediction,
                  raceCompleted: raceCompleted,
                  onBetPressed: () {
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
                      // Actualizar los resultados cuando volvemos de hacer una predicción
                      _fetchInitialData();
                    });
                  },
                  onViewResults: (season, round) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultsScreen(
                          initialRaceId: '${season}_$round',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        shadowColor: Colors.transparent,
        color: Colors.grey[900],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(CupertinoIcons.home, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.list_number, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pushNamed(context, '/results');
              },
            ),
            IconButton(
              icon:
                  const Icon(CupertinoIcons.person_3_fill, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pushNamed(context, '/tournaments');
              },
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.profile_circled,
                  color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ],
        ),
      ),
    );
  }
}
