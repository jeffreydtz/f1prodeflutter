import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'results_screen.dart';

class BetScreen extends StatefulWidget {
  final String raceName;
  final String date;
  final String circuit;
  final String season;
  final String round;
  final bool hasSprint;

  const BetScreen({
    Key? key,
    required this.raceName,
    required this.date,
    required this.circuit,
    required this.season,
    required this.round,
    required this.hasSprint,
  }) : super(key: key);

  @override
  State<BetScreen> createState() => _BetScreenState();
}

class _BetScreenState extends State<BetScreen> {
  final ApiService apiService = ApiService();
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<String> _pilotos = [];
  String _selectedPoleman = '';
  List<String> _top10 = List.filled(10, '');
  String _selectedDnf = '';
  String _selectedFastestLap = '';
  List<String> _sprintTop8 = List.filled(8, '');

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Ejecutar en paralelo: pilotos + verificación de predicción
    try {
      await Future.wait([
        _fetchDrivers(),
        _checkAlreadyPredicted(),
      ]);
    } catch (_) {
      // Ignorar; _fetchDrivers gestiona sus errores
    }
  }

  Future<void> _fetchDrivers() async {
    try {
      final fetchedDrivers = await apiService.getDrivers();
      if (mounted) {
        setState(() {
          _pilotos = fetchedDrivers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar los pilotos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkAlreadyPredicted() async {
    try {
      final results = await apiService.getUserBetResults(pageSize: 500);
      final hasBet = results.any((r) =>
          r.season.toString() == widget.season.toString() &&
          r.round.toString() == widget.round.toString());

      if (hasBet && mounted) {
        // Si ya tiene predicción, navegar directamente a verla
        Future.microtask(() {
          Navigator.of(context).pushReplacementNamed(
            '/results',
            arguments: null,
          );
        });
      }
    } catch (_) {
      // En caso de error, no bloqueamos la pantalla
    }
  }

  // Método para obtener pilotos disponibles (no seleccionados)
  List<String> _getAvailablePilots(int currentPosition) {
    // Obtener todos los pilotos seleccionados excepto el de la posición actual
    final selectedPilots = _top10
        .asMap()
        .entries
        .where(
            (entry) => entry.key != currentPosition && entry.value.isNotEmpty)
        .map((entry) => entry.value)
        .toList();

    // Filtrar los pilotos ya seleccionados
    return _pilotos.where((pilot) => !selectedPilots.contains(pilot)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nueva Prediccion'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color.fromARGB(255, 255, 17, 0),
              ),
              SizedBox(height: 20),
              Text(
                'Cargando corredores\naguarde un momento...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Prediccion'),
        centerTitle: true,
        leadingWidth: 40,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de la carrera
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.raceName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.date} - ${widget.circuit}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sprint Race (si aplica)
            if (widget.hasSprint) ...[
              _buildSectionTitle('Sprint Race - Top 8'),
              const SizedBox(height: 10),
              for (int i = 0; i < 8; i++)
                _buildPositionSelector(
                  'P${i + 1}',
                  _sprintTop8[i],
                  (value) {
                    setState(() => _sprintTop8[i] = value ?? '');
                  },
                ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              const SizedBox(height: 20),
            ],

            // Carrera Principal
            _buildSectionTitle('Pole Position'),
            _buildDriverSelector(
              _selectedPoleman,
              (value) => setState(() => _selectedPoleman = value ?? ''),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Top 10 Carrera'),
            for (int i = 0; i < 10; i++)
              _buildPositionSelector(
                'P${i + 1}',
                _top10[i],
                (value) {
                  setState(() => _top10[i] = value ?? '');
                },
              ),
            const SizedBox(height: 20),

            _buildSectionTitle('Vuelta Rápida'),
            _buildDriverSelector(
              _selectedFastestLap,
              (value) => setState(() => _selectedFastestLap = value ?? ''),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('DNF'),
            _buildDriverSelector(
              _selectedDnf,
              (value) => setState(() => _selectedDnf = value ?? ''),
            ),
            const SizedBox(height: 30),

            // Botón de enviar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 17, 0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isSubmitting ? null : _confirmBet,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Enviar Prediccion',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBet() async {
    if (_isSubmitting) return;
    if (_selectedPoleman.isEmpty) {
      _showDialog('Por favor, selecciona un piloto para la pole position.',
          const Color.fromARGB(255, 255, 17, 0), Icons.close);
      return;
    }
    if (_top10.contains('')) {
      _showDialog('Completa todas las posiciones del Top 10.',
          const Color.fromARGB(255, 255, 17, 0), Icons.close);
      return;
    }
    if (_top10.toSet().length != _top10.length) {
      _showDialog('No puedes repetir pilotos en el Top 10.',
          const Color.fromARGB(255, 255, 17, 0), Icons.close);
      return;
    }
    if (_selectedFastestLap.isEmpty) {
      _showDialog('Por favor, selecciona un piloto para la vuelta rápida.',
          const Color.fromARGB(255, 255, 17, 0), Icons.close);
      return;
    }
    if (_selectedDnf.isEmpty) {
      _showDialog('Por favor, selecciona un piloto como DNF.',
          const Color.fromARGB(255, 255, 17, 0), Icons.close);
      return;
    }
    if (widget.hasSprint && _sprintTop8.contains('')) {
      _showDialog('Completa todas las posiciones del Sprint Top 8.',
          const Color.fromARGB(255, 255, 17, 0), Icons.close);
      return;
    }

    try {
      setState(() => _isSubmitting = true);
      final result = await apiService.createBet(
        season: widget.season,
        round: widget.round,
        raceName: widget.raceName,
        date: widget.date,
        circuit: widget.circuit,
        hasSprint: widget.hasSprint,
        poleman: _selectedPoleman,
        top10: _top10,
        dnf: _selectedDnf,
        fastestLap: _selectedFastestLap,
        sprintTop10: widget.hasSprint ? _sprintTop8 : null,
      );

      if (result['success'] == true && mounted) {
        await _showDialog('Predicción confirmada con éxito.', Colors.green,
            Icons.check_circle);
        if (mounted) {
          // Después de enviar, redirigir a resultados de esa carrera
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ResultsScreen(
                initialRaceId: '${widget.season}_${widget.round}',
              ),
            ),
          );
        }
      } else if (mounted) {
        final errorMessage =
            result['error'] ?? 'Error desconocido al enviar la predicción';
        await _showDialog(
            errorMessage, const Color.fromARGB(255, 255, 17, 0), Icons.error);
      }
    } catch (e) {
      if (mounted) {
        await _showDialog('Error al enviar la predicción: ${e.toString()}',
            const Color.fromARGB(255, 255, 17, 0), Icons.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showDialog(String message, Color color, IconData icon) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDriverSelector(
      String selectedValue, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue.isEmpty ? null : selectedValue,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: Colors.grey[800],
      style: const TextStyle(color: Colors.white),
      hint: const Text('Selecciona un piloto',
          style: TextStyle(color: Colors.white70)),
      items: _pilotos.map((String pilot) {
        return DropdownMenuItem<String>(
          value: pilot,
          child: Text(pilot),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPositionSelector(
      String label, String selectedValue, Function(String?) onChanged) {
    final availablePilots =
        _getAvailablePilots(int.parse(label.substring(1)) - 1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedValue.isEmpty ? null : selectedValue,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white),
              hint: Text(label, style: const TextStyle(color: Colors.white70)),
              items: [
                if (selectedValue.isNotEmpty)
                  DropdownMenuItem<String>(
                    value: selectedValue,
                    child: Text(selectedValue),
                  ),
                ...availablePilots
                    .where((pilot) => pilot != selectedValue)
                    .map((String pilot) {
                  return DropdownMenuItem<String>(
                    value: pilot,
                    child: Text(pilot),
                  );
                }),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
