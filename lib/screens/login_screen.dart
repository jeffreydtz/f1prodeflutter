import 'package:flutter/material.dart';
import 'package:f1prodeflutter/screens/home_screen.dart';
import 'package:f1prodeflutter/main.dart';
import 'register_screen.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Patrón de cuadros en la parte inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.3,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                int row = index ~/ 8;
                int col = index % 8;
                return Container(
                  color: (row + col) % 2 == 0 ? Colors.black : Colors.white,
                );
              },
              itemCount: 64,
            ),
          ),
          // Contenedor principal con gradiente
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.1,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                  Colors.black,
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo + Título
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/f1_logo.png',
                          width: 100,
                          height: 100,
                        ),
                        Text(
                          'Prode',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 255, 0, 0),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Campo username
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildTextFieldDecoration('Username'),
                    ),
                    const SizedBox(height: 20),
                    // Campo password
                    TextField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                      decoration: _buildTextFieldDecoration('Password'),
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 255, 4, 0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Iniciar Sesión',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 255, 17, 0),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Olvidaste contraseña
                    TextButton(
                      onPressed: () {
                        // Navigate to forgot password screen (si lo implementas)
                      },
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),

                    // BOTÓN REGISTRO
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        '¿No tienes cuenta? Regístrate',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await _apiService.login(
          _usernameController.text.trim(), _passwordController.text.trim());

      if (success) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            CheckeredTransitionRoute(
              page: const HomeScreen(),
            ),
          );
        }
      } else {
        setState(() {
          _error = 'Credenciales inválidas';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión';
        _isLoading = false;
      });
    }
  }

  InputDecoration _buildTextFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.grey[800],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class CheckeredFlagAnimation extends StatelessWidget {
  const CheckeredFlagAnimation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          int row = index ~/ 8;
          int col = index % 8;
          return Container(
            color: (row + col) % 2 == 0 ? Colors.black : Colors.white,
          );
        },
        itemCount: 64, // 8x8 grid
      ),
    );
  }
}
