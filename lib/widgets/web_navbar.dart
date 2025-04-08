import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';

/// Barra de navegación superior para la interfaz web
/// con estilo de F1 Prode
class WebNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Function()? onRefresh;
  final Function()? onBackPressed;
  final bool showBackButton;
  final int currentIndex;
  final Function(int)? onIndexChanged;

  const WebNavbar({
    Key? key,
    required this.title,
    this.onRefresh,
    this.onBackPressed,
    this.showBackButton = false,
    required this.currentIndex,
    this.onIndexChanged,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService();
    final user = apiService.getCurrentUser();

    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            const Color.fromARGB(255, 30, 30, 30),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo y título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                if (showBackButton && onBackPressed != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onBackPressed,
                  ),
                Image.asset(
                  'assets/f1_logo.png',
                  height: 40,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Espacio flexible
          const Spacer(),

          // Ítems de navegación
          _buildNavItem(
            context,
            'Inicio',
            CupertinoIcons.home,
            0,
            currentIndex,
            () => Navigator.pushReplacementNamed(context, '/home'),
          ),
          _buildNavItem(
            context,
            'Resultados',
            CupertinoIcons.list_number,
            1,
            currentIndex,
            () => Navigator.pushReplacementNamed(context, '/results'),
          ),
          _buildNavItem(
            context,
            'Torneos',
            CupertinoIcons.person_3_fill,
            2,
            currentIndex,
            () => Navigator.pushReplacementNamed(context, '/tournaments'),
          ),
          _buildNavItem(
            context,
            'Perfil',
            CupertinoIcons.profile_circled,
            3,
            currentIndex,
            () => Navigator.pushReplacementNamed(context, '/profile'),
          ),

          // Acciones adicionales
          const SizedBox(width: 16),
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: onRefresh,
              tooltip: 'Actualizar datos',
            ),

          // Avatar de usuario
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: InkWell(
                onTap: () =>
                    Navigator.pushReplacementNamed(context, '/profile'),
                borderRadius: BorderRadius.circular(50),
                child: CircleAvatar(
                  backgroundColor: const Color.fromARGB(255, 255, 17, 0),
                  child: Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String label,
    IconData icon,
    int index,
    int currentIndex,
    VoidCallback onTap,
  ) {
    final isSelected = index == currentIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onTap();
            onIndexChanged?.call(index);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color.fromARGB(255, 255, 17, 0).withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(
                      color: const Color.fromARGB(255, 255, 17, 0), width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? const Color.fromARGB(255, 255, 17, 0)
                      : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? const Color.fromARGB(255, 255, 17, 0)
                        : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
