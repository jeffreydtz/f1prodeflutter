import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/bet.dart';

class BetScreen extends StatefulWidget {
  const BetScreen({Key? key}) : super(key: key);

  @override
  State<BetScreen> createState() => _BetScreenState();
}

class _BetScreenState extends State<BetScreen> {
  final ApiService apiService = ApiService();

  String _selectedPoleman = '';
  List<String> _top10 = List.filled(10, '');
  String _selectedDnf = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apostar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Seleccione Poleman',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              value: _selectedPoleman.isNotEmpty ? _selectedPoleman : null,
              items: _pilotos.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(p),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedPoleman = val ?? '';
                });
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Escoge un piloto',
                hintStyle: const TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Top 10 Final (Orden)',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            ...List.generate(_top10.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: DropdownButtonFormField<String>(
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  value: _top10[index].isNotEmpty ? _top10[index] : null,
                  items: _pilotos
                      .where((p) => !_top10.contains(p) || _top10[index] == p)
                      .map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _top10[index] = val ?? '';
                    });
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Posición ${index + 1}',
                    hintStyle: const TextStyle(color: Colors.white54),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'DNF (Selecciona quien no terminará)',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            DropdownButtonFormField<String>(
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              value: _selectedDnf.isNotEmpty ? _selectedDnf : null,
              items: _pilotos.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(p),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedDnf = val ?? '';
                });
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Selecciona un piloto',
                hintStyle: const TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.red)
                : ElevatedButton(
                    onPressed: _confirmBet,
                    child: const Text('Confirmar Apuesta'),
                  ),
          ],
        ),
      ),
    );
  }

  final List<String> _pilotos = [
    'Verstappen',
    'Hamilton',
    'Leclerc',
    'Norris',
    'Russell',
    'Sainz',
    'Alonso',
    'Perez',
    'Gasly',
    'Ocon',
    'Stroll',
    'Bottas',
    'Zhou',
    'Hulkenberg',
    'Magnussen',
    'Tsunoda',
    'De Vries',
    'Piastri',
    'Ricciardo',
  ];

  Future<void> _confirmBet() async {
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
          const Color.fromARGB(255, 250, 22, 5), Icons.close);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final bet = Bet(
      userId: 'user1',
      raceId: '1',
      poleman: _selectedPoleman,
      top10: _top10,
      dnfs: [_selectedDnf],
    );

    final success = await apiService.createBet(bet);
    setState(() {
      _isLoading = false;
    });

    if (success) {
      _showDialog(
          'Apuesta confirmada con éxito.', Colors.green, Icons.check_circle);
    } else {
      _showDialog('Error al enviar la apuesta.',
          const Color.fromARGB(255, 255, 21, 4), Icons.close);
    }
  }

  void _showDialog(String message, Color color, IconData icon) {
    showDialog(
      context: context,
      barrierDismissible: true, // No se puede cerrar tocando fuera del diálogo
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 50,
                color: const Color.fromARGB(255, 247, 247, 247),
              ),
              const SizedBox(
                height: 10,
                width: 10,
              ),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: const Color.fromARGB(255, 255, 255, 255)),
              ),
              const SizedBox(
                height: 10,
                width: 10,
              ),
            ],
          ),
        );
      },
    );
  }
}
