import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';
import '../models/race.dart';
import '../widgets/race_card.dart';
import '../screens/bet_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Próximas Carreras'),
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
                return RaceCard(
                  raceName: race.name,
                  date: race.date,
                  circuit: race.circuit,
                  season: race.season,
                  round: race.round,
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
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        foregroundColor: Colors.white,
        onPressed: () {
          if (races.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BetScreen(
                  raceName: races[0].name,
                  date: races[0].date,
                  circuit: races[0].circuit,
                  season: races[0].season,
                  round: races[0].round,
                ),
              ),
            );
          }
        },
        backgroundColor: const Color.fromARGB(255, 255, 17, 0),
        child: const Icon(CupertinoIcons.car_fill),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        shadowColor: Colors.transparent,
        color: Colors.grey[900],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(CupertinoIcons.home, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedIndex = 0;
                });
                // Navegación a Inicio
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
            const SizedBox(width: 40), // Espacio para el FloatingActionButton

            IconButton(
              icon:
                  const Icon(CupertinoIcons.person_3_fill, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pushNamed(context, '/tournaments');
              },
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.profile_circled,
                  color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedIndex = 2;
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
