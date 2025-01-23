import 'package:f1prodeflutter/services/api_service.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userData = await _apiService.getUserProfile();
      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 255, 17, 0),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final userData = _userData!;
    final username = userData['username'] ?? 'N/A';
    final email = userData['email'] ?? 'N/A';
    final totalPoints = userData['points'] ?? 0;
    final racesPlayed = userData['races_played'] ?? 0;
    final polesGuessed = userData['poles_guessed'] ?? 0;
    final userRank = _calculateRank(totalPoints);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Piloto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar e información del usuario
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey,
              backgroundImage: AssetImage('assets/avatar_placeholder.png'),
            ),
            const SizedBox(height: 16),
            Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                userRank,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white54),
            const SizedBox(height: 16),

            // Estadísticas del usuario
            const Text(
              'Estadísticas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Puntos', totalPoints.toString(),
                    Icons.emoji_events, Colors.amber),
                _buildStatCard('Carreras', racesPlayed.toString(),
                    Icons.sports_motorsports, Colors.blue),
                _buildStatCard(
                    'Poles', polesGuessed.toString(), Icons.flag, Colors.red),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white54),
            const SizedBox(height: 16),

            // Opciones de configuración
            const Text(
              'Opciones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text(
                'Configuración de la Cuenta',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                // Ir a configuración
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                // Cerrar sesión
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  String _calculateRank(int points) {
    if (points >= 500) return 'Campeón Mundial';
    if (points >= 300) return 'Piloto Elite';
    if (points >= 200) return 'Piloto Profesional';
    if (points >= 100) return 'Piloto Amateur';
    return 'Novato';
  }
}
