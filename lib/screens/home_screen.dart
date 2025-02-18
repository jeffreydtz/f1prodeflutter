import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';
import '../models/race.dart';
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
  bool _loading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchRaces();
  }

  Future<void> _fetchRaces() async {
    try {
      final fetchedRaces = await apiService.getRaces();
      if (mounted) {
        setState(() {
          races = fetchedRaces;
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

  Future<bool> _checkExistingPrediction(String season, String round) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final results = await apiService.getUserBetResults();
        return results
            .any((result) => result.season == season && result.round == round);
      } catch (e) {
        retryCount++;
        if (retryCount < maxRetries) {
          // Esperar antes de reintentar
          await Future.delayed(Duration(seconds: 1));
        }
      }
    }

    // Si todos los intentos fallan, asumimos que no hay predicción
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text('Carreras $currentYear'),
        automaticallyImplyLeading: false,
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
                return FutureBuilder<bool>(
                  future: _checkExistingPrediction(race.season, race.round),
                  builder: (context, snapshot) {
                    final hasPrediction = snapshot.data ?? false;
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
                        );
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
