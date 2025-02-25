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
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final ApiService apiService = ApiService();

      // Verificar si hay un usuario actual
      _currentUser = apiService.getCurrentUser();

      final userData = await apiService.getUserProfile();

      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;

          // Extraer y mostrar la información del perfil
          final username = _userData?['username'] ?? 'Usuario';
          final email = _userData?['email'] ?? 'No disponible';
          final points = _userData?['total_points']?.toString() ?? '0';

          // Si el usuario actual tiene un nombre genérico pero tenemos datos reales, actualizarlo
          if (_currentUser != null &&
              _currentUser!.username == 'Usuario' &&
              username != 'Usuario') {
            _currentUser = UserModel(
              id: _currentUser!.id,
              username: username,
              email: email,
              password: '',
              points: int.tryParse(points) ?? 0,
            );

            // Actualizar también el usuario en el ApiService
            apiService.currentUser = _currentUser;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Proporcionar un mensaje de error más amigable
          String errorMsg = 'Error al cargar el perfil';

          if (e.toString().contains('404')) {
            errorMsg =
                'No se encontró el perfil. El servidor puede estar en mantenimiento.';
          } else if (e.toString().contains('HTML')) {
            errorMsg =
                'El servidor respondió con un formato incorrecto. Intente más tarde.';
          } else if (e.toString().contains('conexión')) {
            errorMsg = 'Error de conexión. Verifique su conexión a internet.';
          } else {
            errorMsg = 'Error al cargar el perfil: ${e.toString()}';
          }

          _error = errorMsg;
          _isLoading = false;

          // Si tenemos un usuario actual, usarlo como respaldo
          if (_currentUser != null && _currentUser!.username != 'Usuario') {
            _userData = {
              'id': _currentUser!.id,
              'username': _currentUser!.username,
              'email': _currentUser!.email,
              'points': _currentUser!.points,
              'total_points': _currentUser!.points,
              'races_played': 0,
              'poles_guessed': 0,
            };
          }
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

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Avatar y nombre de usuario
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color.fromARGB(255, 255, 17, 0),
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              username,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _navigateToEditProfile(),
              icon: const Icon(Icons.edit),
              label: const Text('Editar Perfil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Estadísticas
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF212121),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estadísticas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Divider(
                    thickness: 1.5,
                    height: 30,
                  ),
                  _buildStatItem('#️⃣ Puntos totales', totalPoints.toString()),
                  _buildStatItem('🏁 Carreras jugadas', racesPlayed.toString()),
                  _buildStatItem('🏆 Poles acertadas', polesGuessed.toString()),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Botón para cerrar sesión
            ElevatedButton.icon(
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
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 17, 0),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
      setState(() {
        _userData = result;
      });
      _loadUserProfile(); // Recargar los datos del perfil
    }
  }
}
