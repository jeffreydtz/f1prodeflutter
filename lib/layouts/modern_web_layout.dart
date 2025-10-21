import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';
import '../theme/f1_theme.dart';
import '../models/user.dart';

/// Layout web moderno y limpio estilo aplicaciones profesionales
class ModernWebLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final int currentIndex;
  final Function(int)? onNavigationChanged;
  final Function()? onRefresh;

  const ModernWebLayout({
    Key? key,
    required this.child,
    required this.title,
    required this.currentIndex,
    this.onNavigationChanged,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<ModernWebLayout> createState() => _ModernWebLayoutState();
}

class _ModernWebLayoutState extends State<ModernWebLayout> {
  final ApiService _apiService = ApiService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    try {
      _currentUser = _apiService.getCurrentUser();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: F1Theme.carbonBlack,
      body: Row(
        children: [
          // Sidebar fijo y elegante
          Container(
            width: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1a1a1a),
                  F1Theme.carbonBlack,
                  Color(0xFF1a1a1a),
                ],
              ),
              border: Border(
                right: BorderSide(
                  color: F1Theme.borderGrey,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Header con logo
                _buildSidebarHeader(),
                
                const SizedBox(height: 32),
                
                // Navegación principal
                Expanded(
                  child: _buildNavigationItems(),
                ),
                
                // User section en la parte inferior
                _buildUserSection(),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: Column(
              children: [
                // Top bar limpio
                _buildTopBar(),
                
                // Contenido con scroll
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF0a0a0a),
                          F1Theme.carbonBlack,
                          Color(0xFF0a0a0a),
                        ],
                      ),
                    ),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Logo F1 grande y prominente
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: F1Theme.f1RedGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: F1Theme.f1Red.withValues(alpha: 0.4),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_motorsports,
              color: Colors.white,
              size: 40,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Título
          Text(
            'F1 PRODE',
            style: F1Theme.displaySmall.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            'Formula 1 Prediction Championship',
            style: F1Theme.bodySmall.copyWith(
              color: F1Theme.textGrey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems() {
    final items = [
      _NavigationItem(
        icon: CupertinoIcons.home,
        activeIcon: CupertinoIcons.house_fill,
        label: 'Dashboard',
        index: 0,
      ),
      _NavigationItem(
        icon: CupertinoIcons.chart_bar,
        activeIcon: CupertinoIcons.chart_bar_fill,
        label: 'Results',
        index: 1,
      ),
      _NavigationItem(
        icon: CupertinoIcons.group,
        activeIcon: CupertinoIcons.person_3_fill,
        label: 'Tournaments',
        index: 2,
      ),
      _NavigationItem(
        icon: CupertinoIcons.person_circle,
        activeIcon: CupertinoIcons.person_circle_fill,
        label: 'Profile',
        index: 3,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: items.map((item) {
          final isActive = widget.currentIndex == item.index;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onNavigationChanged?.call(item.index),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: isActive
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              F1Theme.f1Red.withValues(alpha: 0.2),
                              F1Theme.f1Red.withValues(alpha: 0.1),
                            ],
                          )
                        : null,
                    border: isActive
                        ? Border.all(
                            color: F1Theme.f1Red.withValues(alpha: 0.4),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isActive
                              ? F1Theme.f1Red.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                        ),
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive ? F1Theme.f1Red : F1Theme.textGrey,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item.label,
                          style: F1Theme.bodyLarge.copyWith(
                            color: isActive ? F1Theme.f1Red : Colors.white,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: const Border(
          bottom: BorderSide(
            color: F1Theme.borderGrey,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Título de la página actual
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  style: F1Theme.headlineLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Temporada 2025 • ${_getTitleDescription()}',
                  style: F1Theme.bodySmall.copyWith(
                    color: F1Theme.textGrey,
                  ),
                ),
              ],
            ),
          ),

          // Botón de refresh
          if (widget.onRefresh != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: const Icon(CupertinoIcons.refresh, size: 20),
                onPressed: widget.onRefresh,
                style: IconButton.styleFrom(
                  backgroundColor: F1Theme.f1Red.withValues(alpha: 0.1),
                  foregroundColor: F1Theme.f1Red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: F1Theme.f1Red.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getTitleDescription() {
    switch (widget.currentIndex) {
      case 0:
        return 'Próximas carreras y predicciones';
      case 1:
        return 'Resultados y estadísticas';
      case 2:
        return 'Torneos y competencias';
      case 3:
        return 'Mi perfil y configuración';
      default:
        return 'Dashboard principal';
    }
  }

  Widget _buildUserSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: F1Theme.borderGrey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: F1Theme.f1RedGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: F1Theme.f1Red.withValues(alpha: 0.3),
                  spreadRadius: 0,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.person_fill,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser?.username ?? 'Usuario',
                  style: F1Theme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_currentUser?.points ?? 0} puntos',
                  style: F1Theme.bodyMedium.copyWith(
                    color: F1Theme.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  const _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
  });
}