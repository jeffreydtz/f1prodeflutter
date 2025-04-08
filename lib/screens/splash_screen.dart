import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  final ApiService apiService;
  final Function(bool) onInitialized;

  const SplashScreen({
    Key? key,
    required this.apiService,
    required this.onInitialized,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndRedirect();
  }

  Future<void> _checkAuthAndRedirect() async {
    try {
      // Intentar obtener el token almacenado
      final token = await widget.apiService.getStoredAccessToken();

      if (mounted) {
        widget.onInitialized(true);

        if (token != null) {
          // Si hay token, inicializar la app en segundo plano y redirigir al home
          widget.apiService.initializeApp(); // No esperamos a que termine
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Si no hay token, redirigir al login
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        widget.onInitialized(false);
        // En caso de error, redirigir al login
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Este widget nunca debería mostrarse, pero por si acaso
    return const SizedBox.shrink();
  }
}
