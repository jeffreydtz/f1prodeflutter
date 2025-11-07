import 'package:f1prodeflutter/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/user.dart';
import '../screens/edit_profile_screen.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/web_navbar.dart';
import '../widgets/f1_widgets.dart';
import '../theme/f1_theme.dart';

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
      // Obtener el perfil actualizado del servidor
      final profileData = await apiService.getUserProfile();

      if (profileData != null) {
        if (mounted) {
          setState(() {
            user = profileData;
            userData = {
              'id': profileData.id,
              'username': profileData.username,
              'email': profileData.email,
              'points': profileData.points,
              'avatar': profileData.avatar,
              'first_name': profileData.firstName,
              'last_name': profileData.lastName,
              'favorite_team': profileData.favoriteTeam,
              'total_points': profileData.points,
            };
            _loading = false;
            _error = false;
          });
        }
      } else {
        // Si no hay datos del servidor, intentar usar datos en memoria
        final userFromMemory = apiService.getCurrentUser();
        if (userFromMemory != null && mounted) {
          setState(() {
            user = userFromMemory;
            userData = {
              'id': userFromMemory.id,
              'username': userFromMemory.username,
              'email': userFromMemory.email,
              'points': userFromMemory.points,
              'avatar': userFromMemory.avatar,
              'first_name': userFromMemory.firstName,
              'last_name': userFromMemory.lastName,
              'favorite_team': userFromMemory.favoriteTeam,
              'total_points': userFromMemory.points,
            };
            _loading = false;
            _error = false;
          });
        } else {
          if (mounted) {
            setState(() {
              _loading = false;
              _error = true;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  // Obtener el color del equipo
  Color getTeamColor() {
    final favoriteTeam = userData?['favorite_team'] ?? '';
    return F1Theme.getTeamColor(favoriteTeam);
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveLayout.isWeb(context);
    final teamColor = getTeamColor();

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
              backgroundColor: teamColor,
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
          : F1BottomNavigation(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
                switch (index) {
                  case 0:
                    Navigator.pushNamed(context, '/home');
                    break;
                  case 1:
                    Navigator.pushNamed(context, '/results');
                    break;
                  case 2:
                    Navigator.pushNamed(context, '/tournaments');
                    break;
                  case 3:
                    // Ya estamos en perfil
                    break;
                }
              },
              items: const [
                F1BottomNavItem(
                  icon: CupertinoIcons.house_fill,
                  label: 'Inicio',
                ),
                F1BottomNavItem(
                  icon: CupertinoIcons.list_bullet_below_rectangle,
                  label: 'Resultados',
                ),
                F1BottomNavItem(
                  icon: CupertinoIcons.person_3_fill,
                  label: 'Torneos',
                ),
                F1BottomNavItem(
                  icon: CupertinoIcons.person_fill,
                  label: 'Perfil',
                ),
              ],
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: F1LoadingIndicator(
          message: 'Cargando perfil...',
        ),
      );
    }

    if (_error || userData == null) {
      return F1ErrorState(
        title: 'Error al cargar el perfil',
        subtitle: 'No se pudo cargar la información del usuario',
        actionText: 'Reintentar',
        onAction: _loadUserProfile,
      );
    }

    final isWeb = ResponsiveLayout.isWeb(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWeb ? 32.0 : 16.0),
      child: isWeb ? _buildWebProfileLayout() : _buildMobileProfileLayout(),
    );
  }

  Widget _buildWebProfileLayout() {
    final teamColor = getTeamColor();
    final username = userData?['username'] ?? user?.username ?? 'Usuario';
    final email = userData?['email'] ?? user?.email ?? '';
    final firstName = userData?['first_name'] ?? '';
    final lastName = userData?['last_name'] ?? '';
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
    final favoriteTeam = userData?['favorite_team'] ?? '';
    final points = userData?['points'] ?? user?.points ?? 0;
    final totalPoints = userData?['total_points'] ?? points;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: teamColor, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _navigateToEditProfile(),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: teamColor.withOpacity(0.2),
                        child: Icon(
                          Icons.sports_motorsports,
                          size: 60,
                          color: teamColor,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: teamColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
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
                const SizedBox(height: 24),

                const SizedBox(height: 32),
                const Divider(color: Colors.white30),
                const SizedBox(height: 16),

                // Nombre completo
                if (fullName.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.person, color: teamColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nombre',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                // Equipo favorito (si existe)
                if (favoriteTeam.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.sports_motorsports, color: teamColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Equipo favorito',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              favoriteTeam,
                              style: TextStyle(
                                color: teamColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'Editar Perfil',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => _navigateToEditProfile(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teamColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    label: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(color: Colors.white70),
                    ),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileProfileLayout() {
    final teamColor = getTeamColor();
    final username = userData?['username'] ?? user?.username ?? 'Usuario';
    final email = userData?['email'] ?? user?.email ?? '';
    final firstName = userData?['first_name'] ?? '';
    final lastName = userData?['last_name'] ?? '';
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
    final favoriteTeam = userData?['favorite_team'] ?? '';
    final points = userData?['points'] ?? user?.points ?? 0;
    final totalPoints = userData?['total_points'] ?? points;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar y nombre
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _navigateToEditProfile(),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: teamColor.withOpacity(0.2),
                      child: Icon(
                        Icons.sports_motorsports,
                        size: 60,
                        color: teamColor,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: teamColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
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
        const SizedBox(height: 24),

        const SizedBox(height: 32),

        // Información de perfil
        Text(
          'Información de Perfil',
          style: TextStyle(
            color: teamColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Tarjeta para nombre completo
        if (fullName.isNotEmpty)
          Card(
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: teamColor.withOpacity(0.3), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.person, color: teamColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nombre',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Tarjeta para equipo favorito
        if (favoriteTeam.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Card(
              color: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: teamColor.withOpacity(0.3), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.sports_motorsports, color: teamColor),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Equipo favorito',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            favoriteTeam,
                            style: TextStyle(
                              color: teamColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 32),

        // Botón de editar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text(
              'Editar Perfil',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => _navigateToEditProfile(),
            style: ElevatedButton.styleFrom(
              backgroundColor: teamColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white70),
            label: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.white70),
            ),
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

  Widget _buildStatCard(String title, String value, Color teamColor) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: teamColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: teamColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: teamColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getInitials() {
    final username = userData?['username'] ?? user?.username ?? '';
    final firstName = userData?['first_name'] ?? '';
    final lastName = userData?['last_name'] ?? '';

    // Si hay nombre y apellido, usar las iniciales de ambos
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }

    // Si solo hay nombre, usar la primera letra
    if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    }

    // Si solo hay apellido, usar la primera letra
    if (lastName.isNotEmpty) {
      return lastName[0].toUpperCase();
    }

    // Si no hay nombre ni apellido pero hay username, usar su primera letra
    if (username.isNotEmpty) {
      return username[0].toUpperCase();
    }

    // Valor por defecto
    return 'U';
  }

  void _navigateToEditProfile() {
    if (userData == null) {
      F1Theme.showError(context, 'No se pudo cargar la información del perfil');
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
