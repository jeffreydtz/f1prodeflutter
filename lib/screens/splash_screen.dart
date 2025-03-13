import 'dart:async';
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
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _loadingSeconds = 0;
  late Timer _loadingTimer;

  @override
  void initState() {
    super.initState();

    // Timer para mostrar cuánto tiempo ha pasado cargando
    _loadingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _loadingSeconds++;
        });
      }
    });

    _initializeApp();
  }

  @override
  void dispose() {
    _loadingTimer.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Verificar el estado de la API
      final user = widget.apiService.getCurrentUser();

      // Esperar al menos 1.5 segundos para mostrar la pantalla de splash
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      widget.onInitialized(true);

      // Navegar a la pantalla adecuada
      if (user != null) {
        // Si hay usuario, ir a home
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        // Si no hay usuario, ir a login
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });

        widget.onInitialized(false);

        // A pesar del error, navegar a login
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/logo.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                // Si no se encuentra el logo, mostrar un texto
                return const Text(
                  'F1 PRODE',
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 17, 0),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 30),

            // Animación de carga
            if (_isLoading)
              Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color.fromARGB(255, 255, 17, 0),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cargando... ($_loadingSeconds s)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

            // Mensaje de error
            if (_hasError)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Error de conexión',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage.length > 100
                          ? '${_errorMessage.substring(0, 100)}...'
                          : _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Redirigiendo a la pantalla de inicio de sesión...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
