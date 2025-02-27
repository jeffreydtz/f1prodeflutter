import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  bool _isLoading = false;
  String? _error;
  Uint8List? _selectedImage;
  String? _avatarBase64;

  // Instanciamos ApiService (singleton)
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _selectImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 75,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);
      setState(() {
        _selectedImage = bytes;
        _avatarBase64 =
            'data:image/${image.name.split('.').last};base64,$base64';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Registro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Imagen de perfil
            GestureDetector(
              onTap: _selectImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color.fromARGB(255, 255, 4, 0),
                    width: 2,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipOval(
                        child: Image.memory(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: 116,
                          height: 116,
                        ),
                      )
                    : Icon(
                        Icons.add_a_photo,
                        color: Colors.white,
                        size: 40,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Selecciona una foto de perfil',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 16),
            TextField(
              controller: _passwordConfirmController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: _buildTextFieldDecoration('Confirmar Password'),
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
    final passwordConfirm = _passwordConfirmController.text.trim();

    // Validaciones básicas
    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        passwordConfirm.isEmpty) {
      setState(() {
        _error = 'Todos los campos son obligatorios';
        _isLoading = false;
      });
      return;
    }

    // Validación de email
    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _error = 'Por favor ingresa un email válido';
        _isLoading = false;
      });
      return;
    }

    // Validación de contraseña
    if (password.length < 8) {
      setState(() {
        _error = 'La contraseña debe tener al menos 8 caracteres';
        _isLoading = false;
      });
      return;
    }

    // Validación de coincidencia de contraseñas
    if (password != passwordConfirm) {
      setState(() {
        _error = 'Las contraseñas no coinciden';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await _apiService.register(
          username, email, password, passwordConfirm,
          avatarBase64: _avatarBase64);
      setState(() => _isLoading = false);

      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Usuario registrado con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        String errorMessage = '';

        if (response['errors'] is Map<String, dynamic>) {
          final errors = response['errors'] as Map<String, dynamic>;
          if (errors.containsKey('username')) {
            errorMessage = errors['username'].toString();
          } else if (errors.containsKey('email')) {
            errorMessage = errors['email'].toString();
          } else if (errors.containsKey('password')) {
            errorMessage = errors['password'].toString();
          } else if (errors.containsKey('password_confirm')) {
            errorMessage = errors['password_confirm'].toString();
          } else if (errors.containsKey('avatar')) {
            errorMessage = errors['avatar'].toString();
          } else if (errors.containsKey('detail')) {
            errorMessage = errors['detail'].toString();
          }
        } else if (response['error'] != null) {
          errorMessage = response['error'].toString();
        }

        setState(() {
          _error = errorMessage.isNotEmpty
              ? errorMessage
              : 'Error en el registro. Por favor, intente nuevamente.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e.toString().contains('500')) {
          _error = 'Error en el servidor. Por favor, intente más tarde.';
        } else if (e.toString().contains('timeout')) {
          _error = 'Tiempo de espera agotado. Verifica tu conexión.';
        } else {
          _error = 'Error de conexión. Por favor, intente nuevamente.';
        }
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
