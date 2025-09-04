import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/web_navbar.dart';
import '../widgets/f1_widgets.dart';
import '../theme/f1_theme.dart';
import 'home_screen.dart';
import 'results_screen.dart';
import 'tournaments_screen.dart';
import 'profile_screen.dart';

class MainAppScreen extends StatefulWidget {
  final int initialIndex;

  const MainAppScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      
      // Navegación suave con animación de deslizamiento
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'F1 Prode';
      case 1:
        return 'Resultados';
      case 2:
        return 'Torneos';
      case 3:
        return 'Perfil';
      default:
        return 'F1 Prode';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveLayout.isWeb(context);

    return Scaffold(
      appBar: isWeb
          ? WebNavbar(
              title: _getTitle(),
              currentIndex: _currentIndex,
              onRefresh: () => _refreshCurrentScreen(),
              showBackButton: false,
            )
          : AppBar(
              title: Text(_getTitle()),
              backgroundColor: F1Theme.carbonBlack,
              automaticallyImplyLeading: false, // No mostrar botón back
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => _refreshCurrentScreen(),
                  style: IconButton.styleFrom(
                    backgroundColor: F1Theme.f1Red.withValues(alpha: 0.1),
                    foregroundColor: F1Theme.f1Red,
                  ),
                ),
                const SizedBox(width: F1Theme.s),
              ],
            ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          // Envolvemos cada pantalla quitándole su AppBar/BottomNav
          _ScreenWrapper(child: HomeScreenBody()),
          _ScreenWrapper(child: ResultsScreenBody()),
          _ScreenWrapper(child: TournamentsScreenBody()),
          _ScreenWrapper(child: ProfileScreenBody()),
        ],
      ),
      bottomNavigationBar: !isWeb
          ? F1BottomNavigation(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
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
            )
          : null,
    );
  }

  void _refreshCurrentScreen() {
    // Por ahora, podemos implementar refresh general o específico por pantalla
    setState(() {});
  }
}

// Widget wrapper que mantiene el contenido sin AppBar/BottomNav
class _ScreenWrapper extends StatelessWidget {
  final Widget child;

  const _ScreenWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

// Contenido de Home Screen sin AppBar/BottomNav
class HomeScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Por ahora devolvemos el HomeScreen completo pero podemos extraer solo el body
    return HomeScreen();
  }
}

// Contenido de Results Screen sin AppBar/BottomNav
class ResultsScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResultsScreen();
  }
}

// Contenido de Tournaments Screen sin AppBar/BottomNav
class TournamentsScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TournamentsScreen();
  }
}

// Contenido de Profile Screen sin AppBar/BottomNav
class ProfileScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProfileScreen();
  }
}