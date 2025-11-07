import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/f1_theme.dart';

class JoinTournamentScreen extends StatefulWidget {
  const JoinTournamentScreen({Key? key}) : super(key: key);

  @override
  State<JoinTournamentScreen> createState() => _JoinTournamentScreenState();
}

class _JoinTournamentScreenState extends State<JoinTournamentScreen> {
  final TextEditingController _inviteCodeController = TextEditingController();
  final ApiService apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinTournament() async {
    final inviteCode = _inviteCodeController.text.trim();

    if (inviteCode.isEmpty) {
      setState(() {
        _errorMessage = 'Debes ingresar un código de invitación';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await apiService.joinTournament(inviteCode);

      if (mounted) {
        if (response['success'] == true) {
          F1Theme.showSuccess(context, '¡Te has unido al torneo exitosamente!');
          Navigator.pushReplacementNamed(context, '/tournaments');
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = response['error'] ??
                response['detail'] ??
                'Error al unirse al torneo';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unirse a Torneo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Únete a un torneo existente con el código de invitación',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            // Campo de código de invitación
            TextField(
              controller: _inviteCodeController,
              decoration: InputDecoration(
                labelText: 'Código de Invitación',
                hintText: 'Ingresa el código proporcionado',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              style: const TextStyle(color: Colors.white),
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 24),

            // Botón de unirse
            ElevatedButton(
              onPressed: _isLoading ? null : _joinTournament,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color.fromARGB(255, 255, 17, 0),
                disabledBackgroundColor: Colors.grey,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Unirse al Torneo',
                      style: TextStyle(fontSize: 16),
                    ),
            ),

            const SizedBox(height: 16),

            // Información sobre los torneos
            const Card(
              color: Color.fromARGB(255, 30, 30, 30),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Cómo unirme a un torneo?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Para unirte a un torneo, necesitas el código de invitación que te proporcionará el creador del torneo. Simplemente ingresa el código en el campo de arriba y haz clic en "Unirse al Torneo".',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Importantes:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Una vez que te unes a un torneo, apareceré en la lista de participantes\n• Tus predicciones serán visibles para otros participantes cuando todos hayan predicho o cuando la carrera finalice\n• Puedes salir de un torneo en cualquier momento desde la sección de torneos',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
