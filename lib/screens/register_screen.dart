import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:f1prodeflutter/theme/f1_theme.dart';
import 'package:f1prodeflutter/widgets/f1_widgets.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  Uint8List? _selectedImage;
  String? _avatarBase64;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

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
        _avatarBase64 = 'data:image/${image.name.split('.').last};base64,$base64';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = context.isWeb;

    return Scaffold(
      backgroundColor: F1Theme.carbonBlack,
      appBar: AppBar(
        backgroundColor: F1Theme.darkGrey,
        title: Text(
          'Crear Cuenta',
          style: F1Theme.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: context.isMobile ? F1Theme.l : F1Theme.xl,
              vertical: F1Theme.xl,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWeb ? 480 : double.infinity,
                ),
                child: F1Theme.glassContainer(
                  padding: F1Theme.xl.allPadding,
                  blur: 20,
                  opacity: 0.08,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Text(
                        'Únete a F1 Prode',
                        style: F1Theme.headlineLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      F1Theme.xs.vSpacing,
                      Text(
                        'Compite con tus amigos en las predicciones de F1',
                        style: F1Theme.bodyMedium.copyWith(
                          color: F1Theme.textGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      F1Theme.xl.vSpacing,

                      // Avatar selector
                      Center(
                        child: _buildAvatarSelector(),
                      ),
                      F1Theme.s.vSpacing,
                      Text(
                        _selectedImage != null
                            ? 'Toca para cambiar la foto'
                            : 'Selecciona una foto de perfil (opcional)',
                        style: F1Theme.bodySmall.copyWith(
                          color: F1Theme.textGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      F1Theme.xl.vSpacing,

                      // Username field
                      F1TextField(
                        controller: _usernameController,
                        hint: 'Username',
                        prefixIcon: Icons.person_rounded,
                      ),
                      F1Theme.m.vSpacing,

                      // Email field
                      F1TextField(
                        controller: _emailController,
                        hint: 'Email',
                        prefixIcon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      F1Theme.m.vSpacing,

                      // Password field
                      F1TextField(
                        controller: _passwordController,
                        hint: 'Password (mínimo 8 caracteres)',
                        prefixIcon: Icons.lock_rounded,
                        obscureText: true,
                      ),
                      F1Theme.m.vSpacing,

                      // Confirm password field
                      F1TextField(
                        controller: _passwordConfirmController,
                        hint: 'Confirmar Password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                      ),
                      F1Theme.l.vSpacing,

                      // Register button
                      F1PrimaryButton(
                        text: 'Registrarme',
                        icon: Icons.check_circle_rounded,
                        onPressed: _isLoading ? null : _handleRegister,
                        isLoading: _isLoading,
                        fullWidth: true,
                      ),

                      // Error message
                      if (_error != null) ...[
                        F1Theme.m.vSpacing,
                        Container(
                          padding: F1Theme.m.allPadding,
                          decoration: BoxDecoration(
                            color: F1Theme.errorRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(F1Theme.radiusM),
                            border: Border.all(
                              color: F1Theme.errorRed.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: F1Theme.errorRed,
                                size: 20,
                              ),
                              F1Theme.s.hSpacing,
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: F1Theme.bodySmall.copyWith(
                                    color: F1Theme.errorRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      F1Theme.l.vSpacing,

                      // Back to login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Ya tienes cuenta?',
                            style: F1Theme.bodyMedium.copyWith(
                              color: F1Theme.textGrey,
                            ),
                          ),
                          F1Theme.s.hSpacing,
                          F1TextButton(
                            text: 'Iniciar Sesión',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSelector() {
    return GestureDetector(
      onTap: _selectImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _selectedImage != null
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    F1Theme.f1Red.withOpacity(0.3),
                    F1Theme.telemetryTeal.withOpacity(0.3),
                  ],
                ),
          border: Border.all(
            color: _selectedImage != null ? F1Theme.f1Red : F1Theme.telemetryTeal,
            width: 3,
          ),
          boxShadow: _selectedImage != null
              ? F1Theme.softGlow(F1Theme.f1Red, spread: 12)
              : F1Theme.softGlow(F1Theme.telemetryTeal, spread: 12),
        ),
        child: ClipOval(
          child: _selectedImage != null
              ? Image.memory(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  width: 134,
                  height: 134,
                )
              : Container(
                  color: F1Theme.mediumGrey,
                  child: Icon(
                    Icons.add_a_photo_rounded,
                    color: Colors.white.withOpacity(0.7),
                    size: 48,
                  ),
                ),
        ),
      ),
    );
  }

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
    if (username.isEmpty || email.isEmpty || password.isEmpty || passwordConfirm.isEmpty) {
      setState(() {
        _error = 'Todos los campos son obligatorios';
        _isLoading = false;
      });
      return;
    }

    // Validación de username
    if (username.length < 3) {
      setState(() {
        _error = 'El username debe tener al menos 3 caracteres';
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
        username: username,
        email: email,
        password: password,
        avatarBase64: _avatarBase64,
      );
      setState(() => _isLoading = false);

      if (response['success']) {
        if (mounted) {
          F1Theme.showSuccess(context, '¡Usuario registrado con éxito!');
          // Wait a moment before popping to show the success message
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pop(context);
          }
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
}
