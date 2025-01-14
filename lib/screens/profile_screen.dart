import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService();
    final UserModel? user = apiService.currentUser;

    // Mock de datos de "estadísticas"
    final int totalPoints = user?.points ?? 0;
    final int racesPlayed = 3; // Ejemplo
    final int polesGuessed = 1; // Ejemplo

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil y Estadísticas'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: user == null
            ? const Center(
                child: Text(
                  'No hay usuario autenticado',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usuario: ${user.username}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Email: ${user.email}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white54),
                  const Text(
                    'Estadísticas:',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Puntos Totales: $totalPoints',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    'Carreras Apostadas: $racesPlayed',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    'Poles Adivinadas: $polesGuessed',
                    style: const TextStyle(color: Colors.white),
                  ),
                  // Aquí podrías añadir una gráfica o progreso
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Cerrar sesión, por ejemplo
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text('Cerrar Sesión'),
                  ),
                ],
              ),
      ),
    );
  }
}
