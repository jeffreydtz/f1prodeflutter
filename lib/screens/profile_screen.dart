import 'package:f1prodeflutter/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/user.dart';
import '../screens/edit_profile_screen.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/web_navbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService apiService = ApiService();
  UserModel? user;
  Map<String, dynamic>? userData;
  bool _loading = true;
  bool _error = false;
  int _selectedIndex = 3; // Perfil tab is selected

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      // Primero intentamos obtener el usuario actual desde la API en memoria
      UserModel? userFromMemory = apiService.getCurrentUser();

      // Si existe un usuario en memoria, actualizar con esos datos primero
      if (userFromMemory != null) {
        setState(() {
          user = userFromMemory;
          // Mostrar los datos que tenemos mientras cargamos la información completa
          userData = {
            'id': userFromMemory.id,
            'username': userFromMemory.username,
            'email': userFromMemory.email,
            'points': userFromMemory.points,
          };
        });
      }

      // Luego hacemos la solicitud al servidor para obtener datos actualizados
      final profileData = await apiService.getUserProfile();

      // Verificamos si hay datos válidos
      if (profileData != null &&
          profileData is Map<String, dynamic> &&
          profileData.isNotEmpty) {
        // Mostrar datos para debug
        debugPrint('Profile data loaded: $profileData');

        if (mounted) {
          setState(() {
            userData = profileData;
            // Volver a obtener el usuario actual (que ahora debería estar actualizado)
            user = apiService.getCurrentUser();
            _loading = false;
          });
        }
      } else {
        // Si no se obtuvieron datos válidos del perfil pero tenemos un usuario en memoria
        if (mounted && userFromMemory != null) {
          setState(() {
            _loading = false;
          });
        } else if (mounted) {
          // Si no tenemos datos del servidor ni usuario en memoria, mostrar error
          setState(() {
            _loading = false;
            _error = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudieron cargar datos del perfil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');

      // Si hubo un error pero tenemos datos cargados anteriormente, no mostrar error
      if (mounted && userData != null) {
        setState(() {
          _loading = false;
        });

        // Mostrar mensaje de error más discreto si ya tenemos datos
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo actualizar el perfil: $e'),
            duration: Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        // Si no tenemos datos previos, mostrar pantalla de error
        setState(() {
          _loading = false;
          _error = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el perfil: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveLayout.isWeb(context);

    return Scaffold(
      appBar: isWeb
          ? WebNavbar(
              title: 'Mi Perfil',
              onRefresh: _loadUserProfile,
              showBackButton: Navigator.canPop(context),
              onBackPressed: () => Navigator.of(context).pop(),
              currentIndex: _selectedIndex,
            )
          : AppBar(
              title: const Text('Mi Perfil'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadUserProfile,
                  tooltip: 'Actualizar perfil',
                ),
              ],
            ),
      body: _buildBody(),
      bottomNavigationBar: isWeb
          ? null
          : BottomAppBar(
              shape: const CircularNotchedRectangle(),
              color: Colors.grey[900],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.home, color: Colors.white),
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.list_number,
                        color: Colors.white),
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/results'),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.person_3_fill,
                        color: Colors.white),
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/tournaments'),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.profile_circled,
                        color: Colors.white),
                    onPressed: null, // Ya estamos en perfil
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 255, 17, 0),
        ),
      );
    }

    if (_error || userData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar el perfil',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserProfile,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final isWeb = ResponsiveLayout.isWeb(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWeb ? 32.0 : 16.0),
      child: isWeb ? _buildWebProfileLayout() : _buildMobileProfileLayout(),
    );
  }

  Widget _buildWebProfileLayout() {
    final username = userData?['username'] ?? user?.username ?? 'Usuario';
    final email = userData?['email'] ?? user?.email ?? '';
    final name = userData?['name'] ?? '';
    final country = userData?['country'] ?? '';
    final favoriteTeam = userData?['favorite_team'] ?? '';
    final ranking = userData?['ranking'] ?? 'N/A';
    final points =
        userData?['points'] ?? userData?['total_points'] ?? user?.points ?? 0;
    final tournaments = userData?['tournaments_count'] ?? 0;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar y estadísticas
            Expanded(
              flex: 1,
              child: Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[800],
                        child: Text(
                          _getInitials(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildStatistic('Posición', '$ranking'),
                      const SizedBox(height: 16),
                      _buildStatistic('Puntos', '$points'),
                      const SizedBox(height: 16),
                      _buildStatistic('Torneos', '$tournaments'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Información del perfil
            Expanded(
              flex: 2,
              child: Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildProfileInfo('Email', email),
                      _buildProfileInfo(
                          'Nombre', name != '' ? name : 'No especificado'),
                      // Ocultamos estos campos hasta que estén implementados en el backend
                      // _buildProfileInfo('País', country != '' ? country : 'No especificado'),
                      // _buildProfileInfo('Equipo Favorito', favoriteTeam != '' ? favoriteTeam : 'No especificado'),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar Perfil'),
                          onPressed: () => _navigateToEditProfile(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 255, 17, 0),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.logout, color: Colors.white70),
                          label: const Text('Cerrar Sesión',
                              style: TextStyle(color: Colors.white70)),
                          onPressed: () async {
                            await apiService.logout();
                            if (mounted) {
                              Navigator.of(context)
                                  .pushReplacementNamed('/login');
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade700),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileProfileLayout() {
    final username = userData?['username'] ?? user?.username ?? 'Usuario';
    final email = userData?['email'] ?? user?.email ?? '';
    final name = userData?['name'] ?? '';
    final country = userData?['country'] ?? '';
    final favoriteTeam = userData?['favorite_team'] ?? '';
    final ranking = userData?['ranking'] ?? 'N/A';
    final points =
        userData?['points'] ?? userData?['total_points'] ?? user?.points ?? 0;
    final tournaments = userData?['tournaments_count'] ?? 0;
    final avatarUrl = userData?['avatar'] ?? user?.avatar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar y nombre
        Center(
          child: Column(
            children: [
              avatarUrl != null && avatarUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(avatarUrl),
                      backgroundColor: Colors.grey[800],
                    )
                  : CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[800],
                      child: Text(
                        _getInitials(),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Estadísticas
        Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Posición', '$ranking'),
                _buildStatColumn('Puntos', '$points'),
                _buildStatColumn('Torneos', '$tournaments'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Información de perfil
        const Text(
          'Información de Perfil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildProfileInfoRow('Nombre', name != '' ? name : 'No especificado'),
        // Ocultamos estos campos hasta que estén implementados en el backend
        // _buildProfileInfoRow('País', country != '' ? country : 'No especificado'),
        // _buildProfileInfoRow('Equipo Favorito', favoriteTeam != '' ? favoriteTeam : 'No especificado'),
        const SizedBox(height: 32),

        // Botón de editar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Editar Perfil'),
            onPressed: () => _navigateToEditProfile(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 17, 0),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white70),
            label: const Text('Cerrar Sesión',
                style: TextStyle(color: Colors.white70)),
            onPressed: () async {
              await apiService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade700),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatistic(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials() {
    final username = userData?['username'] ?? user?.username ?? '';
    final name = userData?['name'] ?? '';

    if (name.isNotEmpty) {
      final nameParts = name.split(' ');
      if (nameParts.length > 1) {
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else if (nameParts.isNotEmpty) {
        return nameParts[0][0].toUpperCase();
      }
    }

    if (username.isNotEmpty) {
      return username[0].toUpperCase();
    }

    return 'U';
  }

  void _navigateToEditProfile() {
    if (userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar la información del perfil'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userData: userData!),
      ),
    ).then((_) => _loadUserProfile());
  }
}
