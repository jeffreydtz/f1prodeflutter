import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({Key? key}) : super(key: key);

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final TextEditingController _tournamentNameController =
      TextEditingController();
  final ApiService apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _tournamentNameController.dispose();
    super.dispose();
  }

  Future<void> _createTournament() async {
    final tournamentName = _tournamentNameController.text.trim();

    if (tournamentName.isEmpty) {
      setState(() {
        _errorMessage = 'Debes ingresar un nombre para el torneo';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await apiService.createTournament(tournamentName);

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Torneo creado con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, '/tournaments');
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = response['error'] ?? 'Error al crear el torneo';
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
        title: const Text('Crear Torneo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Crea un nuevo torneo e invita a tus amigos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            // Campo de nombre del torneo
            TextField(
              controller: _tournamentNameController,
              decoration: InputDecoration(
                labelText: 'Nombre del Torneo',
                hintText: 'Ej: Copa Amigos F1 2025',
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

            // Botón de crear
            ElevatedButton(
              onPressed: _isLoading ? null : _createTournament,
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
                      'Crear Torneo',
                      style: TextStyle(fontSize: 16),
                    ),
            ),

            const SizedBox(height: 16),

            // Información sobre el torneo
            const Card(
              color: Color.fromARGB(255, 30, 30, 30),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Qué es un torneo?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Un torneo te permite competir con amigos o compañeros de trabajo. Cada participante hace sus predicciones y gana puntos en base a sus aciertos. Al final de la temporada, el jugador con más puntos será el campeón.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Características:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Tabla de posiciones en tiempo real\n• Las predicciones de los demás solo se muestran cuando todos han predicho o la carrera ha finalizado\n• Código de invitación para que tus amigos puedan unirse',
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
