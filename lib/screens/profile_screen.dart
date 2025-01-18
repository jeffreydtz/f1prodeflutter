import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock de datos de usuario para pruebas
    final Map<String, dynamic> mockUser = {
      'username': 'TestUser',
      'email': 'testuser@example.com',
      'points': 120,
      'racesPlayed': 5,
      'polesGuessed': 2,
    };

    final String username = mockUser['username'];
    final String email = mockUser['email'];
    final int totalPoints = mockUser['points'];
    final int racesPlayed = mockUser['racesPlayed'];
    final int polesGuessed = mockUser['polesGuessed'];
    final String userRank = 'Corredor Pro'; // Ejemplo de rango

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
}
