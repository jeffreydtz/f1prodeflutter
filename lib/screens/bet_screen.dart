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
  // Para top 10, aquí podrías usar un arreglo de 10 pilotos
  List<String> _top10 = List.filled(10, '');
  // Para DNF, podrías usar checks
  List<String> _dnfs = [];

  bool _isLoading = false;
  String? _message;

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
                  items: _pilotos.map((p) {
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
              'DNFs (Selecciona quienes crees que no terminarán)',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            ..._pilotos.map((p) {
              return CheckboxListTile(
                title: Text(p, style: const TextStyle(color: Colors.white)),
                value: _dnfs.contains(p),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _dnfs.add(p);
                    } else {
                      _dnfs.remove(p);
                    }
                  });
                },
                activeColor: Colors.red,
                checkColor: Colors.white,
              );
            }).toList(),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.red)
                : ElevatedButton(
                    onPressed: _confirmBet,
                    child: const Text('Confirmar Apuesta'),
                  ),
            const SizedBox(height: 10),
            if (_message != null)
              Text(
                _message!,
                style: const TextStyle(color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  // Lista mock de pilotos
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
    if (_selectedPoleman.isEmpty) {
      setState(() {
        _message = 'Por favor, selecciona un poleman';
      });
      return;
    }
    if (_top10.contains('')) {
      setState(() {
        _message = 'Completa todas las posiciones del Top 10';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    // Suponiendo que la carrera actual sea con ID "1"
    final bet = Bet(
      userId: 'user1', // ID de ejemplo
      raceId: '1',
      poleman: _selectedPoleman,
      top10: _top10,
      dnfs: _dnfs,
    );

    final success = await apiService.createBet(bet);
    setState(() {
      _isLoading = false;
    });

    if (success) {
      setState(() {
        _message = 'Apuesta confirmada con éxito.';
      });
    } else {
      setState(() {
        _message = 'Error al enviar la apuesta.';
      });
    }
  }
}
