import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';
import '../theme/f1_theme.dart';
import '../models/user.dart';

/// Layout principal para web con sidebar moderno estilo React
class WebAppLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final int currentIndex;
  final Function(int)? onNavigationChanged;
  final Function()? onRefresh;

  const WebAppLayout({
    Key? key,
    required this.child,
    required this.title,
    required this.currentIndex,
    this.onNavigationChanged,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<WebAppLayout> createState() => _WebAppLayoutState();
}

class _WebAppLayoutState extends State<WebAppLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sidebarAnimation;
  bool _sidebarExpanded = true;
  final ApiService _apiService = ApiService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _sidebarAnimation = Tween<double>(
      begin: 240,
      end: 80,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _loadUserData();
    _animationController.forward();
  }

  void _loadUserData() {
    try {
      _currentUser = _apiService.getCurrentUser();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarExpanded = !_sidebarExpanded;
    });
    if (_sidebarExpanded) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: F1Theme.carbonBlack,
      body: Row(
        children: [
          // Sidebar moderno
          AnimatedBuilder(
            animation: _sidebarAnimation,
            builder: (context, child) {
              return Container(
                width: _sidebarAnimation.value,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      F1Theme.carbonBlack,
                      const Color(0xFF1a1a1a),
                      F1Theme.carbonBlack,
                    ],
                  ),
                  border: const Border(
                    right: BorderSide(
                      color: F1Theme.borderGrey,
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header con logo
                    _buildSidebarHeader(),
                    
                    // Navegación principal
                    Expanded(
                      child: _buildNavigationItems(),
                    ),
                    
                    // User section en la parte inferior
                    _buildUserSection(),
                  ],
                ),
              );
            },
          ),

          // Contenido principal
          Expanded(
            child: Column(
              children: [
                // Top bar moderno
                _buildTopBar(),
                
                // Contenido
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
      height: 100,
      padding: const EdgeInsets.all(F1Theme.m),
      child: Row(
        children: [
          // Logo F1
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: F1Theme.f1RedGradient,
              borderRadius: BorderRadius.circular(12),
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
              Icons.sports_motorsports,
              color: Colors.white,
              size: 28,
            ),
          ),
          if (_sidebarExpanded) ...[
            const SizedBox(width: F1Theme.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'F1 PRODE',
                    style: F1Theme.titleMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Season 2025',
                    style: F1Theme.bodySmall.copyWith(
                      color: F1Theme.textGrey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Toggle button
          IconButton(
            icon: Icon(
              _sidebarExpanded ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right,
              color: F1Theme.textGrey,
              size: 16,
            ),
            onPressed: _toggleSidebar,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
            ),
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
        badge: null,
      ),
      _NavigationItem(
        icon: CupertinoIcons.chart_bar,
        activeIcon: CupertinoIcons.chart_bar_fill,
        label: 'Results',
        index: 1,
        badge: null,
      ),
      _NavigationItem(
        icon: CupertinoIcons.group,
        activeIcon: CupertinoIcons.person_3_fill,
        label: 'Tournaments',
        index: 2,
        badge: null,
      ),
      _NavigationItem(
        icon: CupertinoIcons.person_circle,
        activeIcon: CupertinoIcons.person_circle_fill,
        label: 'Profile',
        index: 3,
        badge: null,
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: F1Theme.s),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isActive = widget.currentIndex == item.index;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => widget.onNavigationChanged?.call(item.index),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isActive
                      ? F1Theme.f1Red.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: isActive
                      ? Border.all(
                          color: F1Theme.f1Red.withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isActive
                            ? F1Theme.f1Red.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                      child: Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive ? F1Theme.f1Red : F1Theme.textGrey,
                        size: 20,
                      ),
                    ),
                    if (_sidebarExpanded) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: F1Theme.bodyMedium.copyWith(
                            color: isActive ? F1Theme.f1Red : Colors.white,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (item.badge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: F1Theme.f1Red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.badge!,
                            style: F1Theme.bodySmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: F1Theme.l),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: const Border(
          bottom: BorderSide(
            color: F1Theme.borderGrey,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumb/Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  style: F1Theme.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Formula 1 Prediction Championship',
                  style: F1Theme.bodySmall.copyWith(
                    color: F1Theme.textGrey,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              // Refresh button
              if (widget.onRefresh != null)
                IconButton(
                  icon: const Icon(CupertinoIcons.refresh, size: 20),
                  onPressed: widget.onRefresh,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    foregroundColor: F1Theme.textGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              const SizedBox(width: 12),
              
              // Notifications
              IconButton(
                icon: const Icon(CupertinoIcons.bell, size: 20),
                onPressed: () {
                  // TODO: Implementar notificaciones
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  foregroundColor: F1Theme.textGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserSection() {
    return Container(
      padding: const EdgeInsets.all(F1Theme.m),
      margin: const EdgeInsets.all(F1Theme.s),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: F1Theme.borderGrey.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: F1Theme.f1RedGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              CupertinoIcons.person_fill,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (_sidebarExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser?.username ?? 'Usuario',
                    style: F1Theme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_currentUser?.points ?? 0} pts',
                    style: F1Theme.bodySmall.copyWith(
                      color: F1Theme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.settings, size: 16),
              onPressed: () {
                // TODO: Implementar configuración
              },
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                foregroundColor: F1Theme.textGrey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
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
  final String? badge;

  const _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    this.badge,
  });
}