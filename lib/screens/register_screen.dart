import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  // Instanciamos ApiService (singleton)
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildTextFieldDecoration('Username'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildTextFieldDecoration('Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: _buildTextFieldDecoration('Password'),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 4, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Registrarme',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Botón de registro
  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Completa todos los campos';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await _apiService.register(username, email, password);
      setState(() => _isLoading = false);

      if (response['success']) {
        // Mostramos SnackBar de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(response['message'] ?? '¡Usuario registrado con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
          // Retornamos a la pantalla de Login
          Navigator.pop(context);
        }
      } else {
        final errors = response['errors'] as Map<String, dynamic>;
        setState(() {
          if (errors.containsKey('username')) {
            _error = errors['username'];
          } else if (errors.containsKey('email')) {
            _error = errors['email'];
          } else if (errors.containsKey('password')) {
            _error = errors['password'];
          } else if (errors.containsKey('detail')) {
            _error = errors['detail'];
          } else {
            _error = 'Error en el registro. Por favor, intente nuevamente.';
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error de conexión. Por favor, intente nuevamente.';
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
