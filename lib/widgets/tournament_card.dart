import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../models/sanction.dart';
import '../services/api_service.dart';
import '../theme/f1_theme.dart';
import 'f1_widgets.dart';

class TournamentCard extends StatefulWidget {
  final String name;
  final String inviteCode;
  final int participantsCount;
  final int position;
  final int points;
  final bool isCreator;
  final int tournamentId;
  final VoidCallback onTap;

  const TournamentCard({
    Key? key,
    required this.name,
    required this.inviteCode,
    required this.participantsCount,
    required this.position,
    required this.points,
    required this.onTap,
    this.isCreator = false,
    required this.tournamentId,
  }) : super(key: key);

  @override
  State<TournamentCard> createState() => _TournamentCardState();
}

class _TournamentCardState extends State<TournamentCard> {
  bool _showingSanctions = false;
  bool _loadingSanctions = false;
  List<Sanction> _sanctions = [];

  final ApiService _apiService = ApiService();

  // Controladores para el formulario de sanciones
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _pointsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchSanctions() async {
    if (_showingSanctions && _sanctions.isEmpty && !_loadingSanctions) {
      setState(() {
        _loadingSanctions = true;
      });

      try {
        final sanctions =
            await _apiService.getTournamentSanctions(widget.tournamentId);

        if (mounted) {
          setState(() {
            _sanctions = sanctions;
            _loadingSanctions = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loadingSanctions = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar las sanciones: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _applyTournamentSanction() async {
    // Validar que todos los campos estén completos
    if (_usernameController.text.isEmpty ||
        _pointsController.text.isEmpty ||
        _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los campos son obligatorios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar que los puntos sean un número válido
    int? points = int.tryParse(_pointsController.text);
    if (points == null || points <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los puntos deben ser un número positivo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final result = await _apiService.applyTournamentSanction(
        widget.tournamentId,
        _usernameController.text,
        points,
        _reasonController.text,
      );

      if (result['success'] == true) {
        // Limpiar el formulario
        _usernameController.clear();
        _pointsController.clear();
        _reasonController.clear();

        // Actualizar la lista de sanciones
        _sanctions = [];
        _fetchSanctions();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sanción aplicada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aplicar la sanción: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aplicar la sanción: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTournamentSanction(int sanctionId) async {
    try {
      final result = await _apiService.deleteTournamentSanction(
        widget.tournamentId,
        sanctionId,
      );

      if (result) {
        // Actualizar la lista de sanciones
        _sanctions = [];
        _fetchSanctions();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sanción eliminada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar la sanción'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar la sanción: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(Sanction sanction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Eliminar Sanción',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro que deseas eliminar la sanción aplicada a ${sanction.username}? Se revertirán los puntos descontados.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTournamentSanction(sanction.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSanctionsList() {
    if (_loadingSanctions) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.red,
          ),
        ),
      );
    }

    if (_sanctions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No hay sanciones aplicadas en este torneo',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
          child: Text(
            'Sanciones (${_sanctions.length})',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _sanctions.length,
          separatorBuilder: (context, index) =>
              const Divider(color: Colors.white24),
          itemBuilder: (context, index) {
            final sanction = _sanctions[index];
            return ListTile(
              title: Text(
                sanction.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Puntos: -${sanction.points}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Motivo: ${sanction.reason}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Fecha: ${sanction.createdAt}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              trailing: widget.isCreator
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(sanction),
                    )
                  : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSanctionForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aplicar Nueva Sanción',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Usuario',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Color(0xFF303030),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pointsController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Puntos a descontar',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Color(0xFF303030),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Color(0xFF303030),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyTournamentSanction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'APLICAR SANCIÓN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return F1Card(
      margin: const EdgeInsets.only(bottom: F1Theme.m),
      borderColor: F1Theme.f1Red.withOpacity(0.3),
      child: Column(
        children: [
          InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(F1Theme.radiusL),
            child: Padding(
              padding: const EdgeInsets.all(F1Theme.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tournament header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          style: F1Theme.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (widget.isCreator)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: F1Theme.s,
                            vertical: F1Theme.xs,
                          ),
                          decoration: BoxDecoration(
                            color: F1Theme.championGold.withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(F1Theme.radiusS),
                            border: Border.all(
                              color: F1Theme.championGold,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'CREATOR',
                            style: F1Theme.labelSmall.copyWith(
                              color: F1Theme.championGold,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: F1Theme.m),

                  // Performance stats container
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          F1Theme.f1Red.withOpacity(0.1),
                          F1Theme.f1Red.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(F1Theme.radiusM),
                      border: Border.all(
                        color: F1Theme.f1Red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(F1Theme.m),
                    child: Row(
                      children: [
                        // Position indicator
                        F1PositionIndicator(
                          position: widget.position,
                          size: 40,
                        ),

                        const SizedBox(width: F1Theme.m),

                        // Performance info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tu posición',
                                style: F1Theme.bodySmall.copyWith(
                                  color: F1Theme.textGrey,
                                ),
                              ),
                              const SizedBox(height: F1Theme.xs),
                              F1PointsIndicator(
                                points: widget.points,
                                style: F1Theme.titleLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Participants count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: F1Theme.m,
                            vertical: F1Theme.s,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius:
                                BorderRadius.circular(F1Theme.radiusM),
                            border: Border.all(
                              color: F1Theme.borderGrey,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${widget.participantsCount}',
                                style: F1Theme.titleLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: F1Theme.f1Red,
                                ),
                              ),
                              Text(
                                'Pilotos',
                                style: F1Theme.bodySmall.copyWith(
                                  color: F1Theme.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: F1Theme.m),

                  // Invite code section
                  Container(
                    padding: const EdgeInsets.all(F1Theme.s),
                    decoration: BoxDecoration(
                      color: context.colors.surface == F1Theme.carbonBlack
                          ? F1Theme.mediumGrey
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(F1Theme.radiusM),
                      border: Border.all(
                        color: F1Theme.borderGrey,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.vpn_key_outlined,
                          color: F1Theme.textGrey,
                          size: 16,
                        ),
                        const SizedBox(width: F1Theme.s),
                        Expanded(
                          child: Text(
                            'Código: ${widget.inviteCode}',
                            style: F1Theme.bodySmall.copyWith(
                              fontFamily: F1Theme.codeFontFamily,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            // Copy to clipboard
                            // You can implement clipboard functionality here
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Código copiado: ${widget.inviteCode}'),
                                backgroundColor: F1Theme.successGreen,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(F1Theme.radiusS),
                          child: Container(
                            padding: const EdgeInsets.all(F1Theme.xs),
                            child: Icon(
                              Icons.copy_rounded,
                              color: F1Theme.textGrey,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botón para mostrar boletín de sanciones
          InkWell(
            onTap: () {
              setState(() {
                _showingSanctions = !_showingSanctions;
              });
              if (_showingSanctions) {
                _fetchSanctions();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showingSanctions ? Icons.expand_less : Icons.expand_more,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Boletín de Sanciones',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sección expandible de sanciones
          if (_showingSanctions) ...[
            const Divider(color: Colors.white24),
            _buildSanctionsList(),
            if (widget.isCreator) ...[
              const Divider(color: Colors.white24),
              _buildSanctionForm(),
            ],
          ],
        ],
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown;
      default:
        return Colors.grey[700]!;
    }
  }
}
