import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';
import '../theme/f1_theme.dart';
import 'f1_widgets.dart';

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
  Size get preferredSize => const Size.fromHeight(80.0);

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService();
    final user = apiService.getCurrentUser();

    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        gradient: F1Theme.carbonGradient,
        border: const Border(
          bottom: BorderSide(
            color: F1Theme.borderGrey,
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo and title section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: F1Theme.l),
            child: Row(
              children: [
                if (showBackButton && onBackPressed != null)
                  Container(
                    margin: const EdgeInsets.only(right: F1Theme.m),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: onBackPressed,
                      style: IconButton.styleFrom(
                        backgroundColor: F1Theme.f1Red.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(F1Theme.radiusM),
                          side: BorderSide(
                            color: F1Theme.f1Red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                // F1 Brand container
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: F1Theme.m,
                    vertical: F1Theme.s,
                  ),
                  decoration: BoxDecoration(
                    gradient: F1Theme.f1RedGradient,
                    borderRadius: BorderRadius.circular(F1Theme.radiusM),
                    boxShadow: F1Theme.coloredShadow(F1Theme.f1Red),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sports_motorsports,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: F1Theme.s),
                      Text(
                        'F1',
                        style: F1Theme.headlineMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: F1Theme.m),
                Text(
                  title,
                  style: F1Theme.headlineMedium.copyWith(
                    fontWeight: FontWeight.w600,
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
