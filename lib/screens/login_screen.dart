import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:f1prodeflutter/screens/home_screen.dart';
import 'package:f1prodeflutter/main.dart';
import 'package:f1prodeflutter/theme/f1_theme.dart';
import 'package:f1prodeflutter/widgets/f1_widgets.dart';
import 'register_screen.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final ApiService _apiService = ApiService();

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
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = context.isWeb;

    return Scaffold(
      backgroundColor: F1Theme.carbonBlack,
      body: Stack(
        children: [
          // Animated checkered pattern background
          _buildCheckeredBackground(isWeb),

          // Gradient overlay for depth
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.transparent,
                  F1Theme.carbonBlack.withOpacity(0.3),
                  F1Theme.carbonBlack.withOpacity(0.7),
                  F1Theme.carbonBlack,
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.isMobile ? F1Theme.l : F1Theme.xl,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWeb ? 480 : double.infinity,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo & Title
                        _buildHeader(),
                        F1Theme.xxxl.vSpacing,

                        // Login Form in glass container
                        F1Theme.glassContainer(
                          padding: F1Theme.xl.allPadding,
                          blur: 20,
                          opacity: 0.08,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Bienvenido',
                                style: F1Theme.headlineLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              F1Theme.xs.vSpacing,
                              Text(
                                'Inicia sesión para continuar',
                                style: F1Theme.bodyMedium.copyWith(
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
                                onSubmitted: (_) => _login(),
                              ),
                              F1Theme.m.vSpacing,

                              // Password field
                              F1TextField(
                                controller: _passwordController,
                                hint: 'Password',
                                prefixIcon: Icons.lock_rounded,
                                obscureText: true,
                                onSubmitted: (_) => _login(),
                              ),
                              F1Theme.l.vSpacing,

                              // Login button
                              F1PrimaryButton(
                                text: 'Iniciar Sesión',
                                icon: Icons.arrow_forward_rounded,
                                onPressed: _isLoading ? null : _login,
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

                              // Forgot password
                              F1TextButton(
                                text: '¿Olvidaste tu contraseña?',
                                onPressed: () {
                                  Navigator.pushNamed(context, '/forgot-password');
                                },
                              ),

                              F1Theme.m.vSpacing,

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: F1Theme.borderGrey,
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: F1Theme.m.hPadding,
                                    child: Text(
                                      'o',
                                      style: F1Theme.bodySmall.copyWith(
                                        color: F1Theme.textGrey,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: F1Theme.borderGrey,
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),

                              F1Theme.m.vSpacing,

                              // Register button
                              F1SecondaryButton(
                                text: 'Crear una cuenta',
                                icon: Icons.person_add_rounded,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                fullWidth: true,
                              ),
                            ],
                          ),
                        ),

                        F1Theme.l.vSpacing,

                        // Footer
                        Text(
                          'F1 Prode © ${DateTime.now().year}',
                          style: F1Theme.labelSmall.copyWith(
                            color: F1Theme.textGrey.withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: F1Theme.l.allPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // F1 Logo with glow effect
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: F1Theme.softGlow(F1Theme.f1Red, spread: 16),
            ),
            child: Image.asset(
              'assets/f1_logo.png',
              width: 100,
              height: 100,
            ),
          ),
          F1Theme.m.hSpacing,
          // Prode title with gradient
          ShaderMask(
            shaderCallback: (bounds) => F1Theme.f1RedGradient.createShader(bounds),
            child: Text(
              'Prode',
              style: F1Theme.displayLarge.copyWith(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -1,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckeredBackground(bool isWeb) {
    if (!isWeb) {
      // Mobile: Simple checkered pattern at bottom
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: MediaQuery.of(context).size.height * 0.3,
        child: Opacity(
          opacity: 0.1,
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
                color: (row + col) % 2 == 0
                    ? F1Theme.carbonBlack
                    : F1Theme.darkGrey,
              );
            },
            itemCount: 64,
          ),
        ),
      );
    }

    // Web: Animated checkered pattern with glassmorphism
    return Positioned.fill(
      child: Opacity(
        opacity: 0.08,
        child: CustomPaint(
          painter: CheckeredPatternPainter(),
        ),
      ),
    );
  }

  Future<void> _login() async {
    // Validate inputs
    if (_usernameController.text.trim().isEmpty) {
      setState(() => _error = 'Por favor ingresa tu username');
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      setState(() => _error = 'Por favor ingresa tu password');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response['success']) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            CheckeredTransitionRoute(
              page: const HomeScreen(),
            ),
          );
        }
      } else {
        setState(() {
          _error = response['error'] ?? 'Credenciales inválidas';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión. Por favor, intente nuevamente.';
        _isLoading = false;
      });
    }
  }
}

class CheckeredPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final squareSize = size.width / 20;
    final rows = (size.height / squareSize).ceil();
    final cols = 20;

    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        if ((i + j) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(
              j * squareSize,
              size.height - (i + 1) * squareSize,
              squareSize,
              squareSize,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
