import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

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
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await widget.apiService.initializeApp();
      if (mounted) {
        widget.onInitialized(true);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        widget.onInitialized(false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
