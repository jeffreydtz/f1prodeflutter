import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/tournaments_screen.dart';
import 'screens/bet_screen.dart';
import 'screens/results_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/register_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/create_tournament_screen.dart';
import 'screens/join_tournament_screen.dart';
import 'services/api_service.dart';

void main() async {
  // Configurar para usar rutas con hash en la web (importante para GitHub Pages)
  setUrlStrategy(HashUrlStrategy());

  // Asegurarse de que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar ApiService y cargar datos del usuario
  final apiService = ApiService();
  await apiService.initializeApp();

  // Ejecutar la app
  runApp(const F1BettingApp());
}

class F1BettingApp extends StatelessWidget {
  const F1BettingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F1 Prode',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 255, 17, 0),
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodySmall: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 17, 0),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/bet': (context) => BetScreen(
              raceName: '',
              date: '',
              circuit: '',
              season: '',
              round: '',
              hasSprint: false,
            ),
        '/results': (context) => const ResultsScreen(),
        '/tournaments': (context) => const TournamentsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
      onGenerateRoute: (settings) {
        // Normalizar la ruta para manejar diferentes formatos
        String routeName = settings.name ?? '';

        // Si viene con # al inicio, quitarlo (puede pasar cuando la ruta inicial viene del index.html)
        if (routeName.startsWith('#')) {
          routeName = routeName.substring(1);
        }

        // Verificar si es una ruta de restablecimiento de contraseña
        final resetPasswordPattern =
            RegExp(r'^/?reset-password/([^/]+)/([^/]+)$');
        final match = resetPasswordPattern.firstMatch(routeName);

        if (match != null) {
          final uid = match.group(1);
          final token = match.group(2);

          if (uid != null && token != null) {
            return MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(
                uid: uid,
                token: token,
              ),
            );
          }
        }

        // Si la ruta comienza con /reset-password/ (formato alternativo)
        if (routeName.contains('/reset-password/')) {
          final parts = routeName.split('/reset-password/');
          if (parts.length >= 2) {
            final params = parts[1].split('/');
            if (params.length >= 2) {
              final uid = params[0];
              final token = params[1];

              return MaterialPageRoute(
                builder: (context) => ResetPasswordScreen(
                  uid: uid,
                  token: token,
                ),
              );
            }
          }
        }

        // Si la ruta no coincide con ningún patrón, redirigir al login
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );
      },
      // Este widget se mostrará durante la carga (importante para web)
      builder: (context, child) {
        return child ??
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Color.fromARGB(255, 255, 17, 0)),
              ),
            );
      },
    );
  }
}

class CheckeredTransitionRoute extends PageRouteBuilder {
  final Widget page;

  CheckeredTransitionRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return Stack(
              children: [
                // El contenido de la nueva página
                FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                // La bandera a cuadros que se desliza desde abajo
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: const Offset(0.0, -1.0),
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (context, index) {
                      int row = index ~/ 8;
                      int col = index % 8;
                      return Container(
                        color:
                            (row + col) % 2 == 0 ? Colors.black : Colors.white,
                      );
                    },
                    itemCount: 64,
                  ),
                ),
              ],
            );
          },
          transitionDuration: const Duration(milliseconds: 1500),
        );
}
