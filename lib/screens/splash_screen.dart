import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
      debugPrint('[SplashScreen] Stored token exists: ${token != null}');

      if (mounted) {
        widget.onInitialized(true);

        if (token != null) {
          debugPrint('[SplashScreen] Token found, initializing app...');
          // Si hay token, inicializar la app y esperar a que termine antes de redirigir
          final initSuccess = await widget.apiService.initializeApp();
          debugPrint('[SplashScreen] App initialization success: $initSuccess');
          
          if (initSuccess) {
            debugPrint('[SplashScreen] Navigating to /home');
            Navigator.of(context).pushReplacementNamed('/home');
          } else {
            // Si la inicialización falla, redirigir al login
            debugPrint('[SplashScreen] Initialization failed, navigating to /login');
            Navigator.of(context).pushReplacementNamed('/login');
          }
        } else {
          // Si no hay token, redirigir al login
          debugPrint('[SplashScreen] No token found, navigating to /login');
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      debugPrint('[SplashScreen] Error during auth check: $e');
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
