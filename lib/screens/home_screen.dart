import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/race.dart';
import '../widgets/race_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  List<Race> races = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRaces();
  }

  Future<void> _fetchRaces() async {
    final fetchedRaces = await apiService.getRaces();
    setState(() {
      races = fetchedRaces;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Próximas Carreras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[900],
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.red,
              ),
              child: const Text(
                'Menú',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title:
                  const Text('Inicio', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pushReplacementNamed(context, '/home'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.sports_motorsports, color: Colors.white),
              title: const Text('Mis Apuestas',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pushNamed(context, '/bet'),
            ),
            ListTile(
              leading: const Icon(Icons.score, color: Colors.white),
              title: const Text('Resultados',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pushNamed(context, '/results'),
            ),
            ListTile(
              leading: const Icon(Icons.group, color: Colors.white),
              title:
                  const Text('Torneos', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pushNamed(context, '/tournaments'),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: races.length,
              itemBuilder: (context, index) {
                final race = races[index];
                return RaceCard(
                  raceName: race.name,
                  date: race.date,
                  circuit: race.circuit,
                  onBetPressed: () {
                    Navigator.pushNamed(context, '/bet');
                  },
                );
              },
            ),
    );
  }
}
