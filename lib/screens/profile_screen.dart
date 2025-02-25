import 'package:f1prodeflutter/services/api_service.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  UserModel? _currentUser;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    print('ProfileScreen: Iniciando carga de perfil');

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      print('ProfileScreen: Intentando cargar perfil de usuario');
      final ApiService apiService = ApiService();

      // Verificar si hay un usuario actual
      if (apiService.currentUser != null) {
        print(
            'ProfileScreen: Usuario actual encontrado: ${apiService.currentUser!.username}');
      } else {
        print('ProfileScreen: No hay usuario actual');
      }

      final userData = await apiService.getUserProfile();
      print('ProfileScreen: Perfil cargado desde el servidor');

      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;

          // Extraer y mostrar la información del perfil
          final username = _userData?['username'] ?? 'Usuario';
          final email = _userData?['email'] ?? 'No disponible';
          final points = _userData?['total_points']?.toString() ?? '0';

          print(
              'ProfileScreen: Mostrando perfil - Usuario: $username, Email: $email, Puntos: $points');
        });
      }
    } catch (e) {
      print('ProfileScreen: Error al cargar perfil: $e');
      if (mounted) {
        setState(() {
          _error = 'Error al cargar el perfil: ${e.toString()}';
          _isLoading = false;
        });

        // Mostrar un mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo cargar el perfil: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Piloto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadUserProfile();
            },
            tooltip: 'Actualizar perfil',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color.fromARGB(255, 255, 17, 0),
                    ),
                    SizedBox(height: 16),
                    Text('Cargando perfil...'),
                  ],
                ),
              )
            : _error != null
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
                          'Error al cargar el perfil',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadUserProfile,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : _buildProfileContent(),
      ),
    );
  }

  Widget _buildProfileContent() {
    // Extraer datos del perfil con valores por defecto
    final username = _userData?['username'] ?? 'Usuario';
    final email = _userData?['email'] ?? 'No disponible';
    final totalPoints = _userData?['total_points'] ?? 0;
    final racesPlayed = _userData?['races_played'] ?? 0;
    final polesGuessed = _userData?['poles_guessed'] ?? 0;
    final userRank = _calculateRank(totalPoints);

    // Calcular progreso hacia el siguiente rango
    final (nextRank, pointsNeeded, progress) =
        _calculateNextRankProgress(totalPoints);

    print(
        'ProfileScreen: Mostrando datos - Username: $username, Email: $email, Puntos: $totalPoints');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar y nombre de usuario
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color.fromARGB(255, 255, 17, 0),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  username,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                if (nextRank != null) ...[
                  const SizedBox(height: 16),
                  Text('Siguiente rango: $nextRank'),
                  const SizedBox(height: 4),
                  Text('Faltan $pointsNeeded puntos'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(255, 255, 17, 0),
                      ),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _navigateToEditProfile(),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar Perfil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Estadísticas
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estadísticas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildStatRow('Puntos totales', totalPoints.toString()),
                  _buildStatRow('Carreras jugadas', racesPlayed.toString()),
                  _buildStatRow('Poles acertadas', polesGuessed.toString()),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botón para cerrar sesión
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                await _apiService.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _calculateRank(int points) {
    if (points >= 500) return 'Campeón Mundial';
    if (points >= 300) return 'Piloto Elite';
    if (points >= 200) return 'Piloto Profesional';
    if (points >= 100) return 'Piloto Amateur';
    return 'Novato';
  }

  (String?, int, double) _calculateNextRankProgress(int points) {
    if (points >= 500) {
      // Ya es Campeón Mundial, no hay siguiente rango
      return (null, 0, 1.0);
    } else if (points >= 300) {
      // Siguiente: Campeón Mundial (500 puntos)
      final remaining = 500 - points;
      final progress = (points - 300) / (500 - 300);
      return ('Campeón Mundial', remaining, progress);
    } else if (points >= 200) {
      // Siguiente: Piloto Elite (300 puntos)
      final remaining = 300 - points;
      final progress = (points - 200) / (300 - 200);
      return ('Piloto Elite', remaining, progress);
    } else if (points >= 100) {
      // Siguiente: Piloto Profesional (200 puntos)
      final remaining = 200 - points;
      final progress = (points - 100) / (200 - 100);
      return ('Piloto Profesional', remaining, progress);
    } else {
      // Siguiente: Piloto Amateur (100 puntos)
      final remaining = 100 - points;
      final progress = points / 100;
      return ('Piloto Amateur', remaining, progress);
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar la información del perfil'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userData: _userData!),
      ),
    );

    // Si se actualizó el perfil, recargar los datos
    if (result != null && result is Map<String, dynamic>) {
      print('Perfil actualizado, recargando datos: $result');
      setState(() {
        _userData = result;
      });
      _loadUserProfile(); // Recargar los datos del perfil
    }
  }
}
