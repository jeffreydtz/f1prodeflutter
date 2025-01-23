import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/bet.dart';

class BetScreen extends StatefulWidget {
  final String raceName;
  final String date;
  final String circuit;
  final String season;
  final String round;

  const BetScreen({
    Key? key,
    required this.raceName,
    required this.date,
    required this.circuit,
    required this.season,
    required this.round,
  }) : super(key: key);

  @override
  State<BetScreen> createState() => _BetScreenState();
}

class _BetScreenState extends State<BetScreen> {
  final ApiService apiService = ApiService();
  bool _isLoading = true;
  List<String> _pilotos = [];
  String _selectedPoleman = '';
  List<String> _top10 = List.filled(10, '');
  String _selectedDnf = '';

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
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
          title: const Text('Nueva Apuesta'),
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
        title: const Text('Nueva Apuesta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de la carrera
            Container(
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
            // Pole Position
            const Text(
              'Pole Position',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPoleman.isEmpty ? null : _selectedPoleman,
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
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPoleman = newValue ?? '';
                });
              },
            ),
            const SizedBox(height: 24),

            // Top 10
            const Text(
              'Top 10',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 10,
              itemBuilder: (context, index) {
                // Obtener pilotos disponibles para esta posición
                final availablePilots = _getAvailablePilots(index);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Text(
                        '${index + 1}.',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _top10[index].isEmpty ? null : _top10[index],
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
                          hint: Text('Posición ${index + 1}',
                              style: const TextStyle(color: Colors.white70)),
                          items: [
                            if (_top10[index].isNotEmpty)
                              DropdownMenuItem<String>(
                                value: _top10[index],
                                child: Text(_top10[index]),
                              ),
                            ...availablePilots
                                .where((pilot) => pilot != _top10[index])
                                .map((String pilot) {
                              return DropdownMenuItem<String>(
                                value: pilot,
                                child: Text(pilot),
                              );
                            }),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              _top10[index] = newValue ?? '';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // DNF
            const Text(
              'DNF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedDnf.isEmpty ? null : _selectedDnf,
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
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDnf = newValue ?? '';
                });
              },
            ),
            const SizedBox(height: 32),

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
                onPressed: _confirmBet,
                child: const Text(
                  'Enviar Apuesta',
                  style: TextStyle(
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
    if (_selectedDnf.isEmpty) {
      _showDialog('Por favor, selecciona un piloto como DNF.',
          const Color.fromARGB(255, 255, 17, 0), Icons.close);
      return;
    }

    try {
      final success = await apiService.createBet(
        season: widget.season,
        round: widget.round,
        raceName: widget.raceName,
        date: widget.date,
        circuit: widget.circuit,
        poleman: _selectedPoleman,
        top10: _top10,
        dnf: _selectedDnf,
      );

      if (success && mounted) {
        await _showDialog(
            'Apuesta confirmada con éxito.', Colors.green, Icons.check_circle);
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        _showDialog('Error al enviar la apuesta: ${e.toString()}',
            const Color.fromARGB(255, 255, 17, 0), Icons.error);
      }
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
}
