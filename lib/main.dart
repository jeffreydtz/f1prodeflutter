import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/bet_screen.dart';
import 'screens/results_screen.dart';
import 'screens/tournaments_screen.dart';
import 'screens/profile_screen.dart';

void main() {
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
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.black,
        // Paleta de texto
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        // Color de AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
        ),
        // Botones
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/bet': (context) => const BetScreen(),
        '/results': (context) => const ResultsScreen(),
        '/tournaments': (context) => const TournamentsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
