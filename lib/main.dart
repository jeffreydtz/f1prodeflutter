import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/reset_password_screen.dart';
import 'services/api_service.dart';
// Importaciones web condicionales
import 'web_imports.dart'
    if (dart.library.html) 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/bet_screen.dart';
import 'screens/tournaments_screen.dart';
import 'screens/results_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/create_tournament_screen.dart';
import 'screens/join_tournament_screen.dart';
import 'screens/tournament_race_screen.dart';

void main() async {
  // Asegurar que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar URL strategy para web solo si estamos en web
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }

  // Inicializar ApiService
  final apiService = ApiService();

  // Ejecutar la app inmediatamente
  runApp(MyApp(
    apiService: apiService,
    initialized: true,
    initializationError: null,
  ));
}

class MyApp extends StatefulWidget {
  final ApiService apiService;
  final bool initialized;
  final String? initializationError;

  const MyApp({
    Key? key,
    required this.apiService,
    required this.initialized,
    this.initializationError,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Mostrar mensaje de error de inicialización si existe
    if (widget.initializationError != null) {
      // Esperar a que el framework esté listo para mostrar el mensaje
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar(
            'Error de inicialización: ${widget.initializationError}');
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'F1 Prode',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 255, 17, 0),
        colorScheme: ColorScheme.dark(
          primary: const Color.fromARGB(255, 255, 17, 0),
          secondary: const Color.fromARGB(255, 255, 17, 0),
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 17, 0),
          ),
        ),
      ),
      home: SplashScreen(
        apiService: widget.apiService,
        onInitialized: (bool success) {
          if (!success && mounted) {
            _showErrorSnackBar(
                'Error de inicialización. Algunas funciones pueden no estar disponibles.');
          }
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/tournaments': (context) => const TournamentsScreen(),
        '/bet': (context) => BetScreen(
              raceName: '',
              date: '',
              circuit: '',
              season: '',
              round: '',
              hasSprint: false,
            ),
        '/results': (context) => const ResultsScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/create-tournament': (context) => const CreateTournamentScreen(),
        '/join-tournament': (context) => const JoinTournamentScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name != null) {
          if (settings.name!.contains('reset-password')) {
            final uri = Uri.parse(settings.name!);
            String? uid = uri.queryParameters['uid'];
            String? token = uri.queryParameters['token'];
            if (uid != null && token != null) {
              return MaterialPageRoute(
                builder: (context) =>
                    ResetPasswordScreen(uid: uid, token: token),
              );
            }
          } else if (settings.name == '/edit-profile') {
            return MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
            );
          }
        }
        return null;
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
